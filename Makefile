SERVICES_DIR ?= ../services

# ── Release artifact — the ONLY source of Globular bits ──
# The image installs Globular exactly the way an operator does: by unpacking
# the published release tarball and running its install.sh (which delegates to
# scripts/install-day0.sh). Nothing is copied from the build host.
#
# Historical note — why this matters:
#   This used to be BIN_SRC=/usr/lib/globular/bin + UNIT_SRC=/etc/systemd/system,
#   i.e. the image was assembled from whatever happened to be installed on the
#   developer's workstation, with a 579-line entrypoint standing in for the
#   3013-line real installer. The simulation then validated a cluster that no
#   operator ever builds: no workflow definitions, no desired state, no RBAC
#   bindings, no repository artifacts. 18/38 scenarios failed on 2026-07-31
#   against artifacts of that divergence rather than real defects.
#   Keep the release tarball as the single source. Do not reintroduce host copies.
RELEASE_VERSION ?= 1.2.327
RELEASE_NAME     = globular-$(RELEASE_VERSION)-linux-amd64
RELEASE_TARBALL  = $(SERVICES_DIR)/dist/$(RELEASE_NAME).tar.gz
RELEASE_SHA256   = $(RELEASE_TARBALL).sha256

.PHONY: collect check-units build up down clean logs status shell test \
	snapshot snapshot-restore snapshot-list \
	check-glibc-floor check-host-aio test-hardened-tmp test-concurrent-join \
	quickstart-up quickstart-down quickstart-reset quickstart-logs \
	test-wait test-smoke test-functional test-security test-resilience \
	test-recovery test-soak test-upgrade test-authority test-v1-certification ci-smoke \
	test-scenario test-scenario-keep \
	test-parity-report test-health-matrix test-authz-report test-recovery-report \
	check-test-schemas check-test-scenarios test-debug-shell \
	test-awareness-smoke test-awareness-recovery test-awareness-debug awareness-latest \
	awareness-train-day0 awareness-train-day1 awareness-train-scenario \
	awareness-reset awareness-training-suite awareness-ledger \
	awareness-patterns awareness-pattern awareness-pattern-latest awareness-pattern-day1

## collect — stage the release tarball into the build context
## The tarball IS the install source. If it is missing, build it in the services
## repo (scripts/build-local-release.sh) rather than falling back to host copies.
collect:
	@echo "=== Staging release $(RELEASE_VERSION) ==="
	@test -f "$(RELEASE_TARBALL)" || { \
		echo "  ✗ $(RELEASE_TARBALL) not found."; \
		echo "    Build it first:  cd $(SERVICES_DIR) && ./scripts/build-local-release.sh"; \
		echo "    Or pick another: make build RELEASE_VERSION=<x.y.z>"; \
		exit 1; \
	}
	@mkdir -p release
	@cp "$(RELEASE_TARBALL)" release/
	@echo "  ✓ $(RELEASE_NAME).tar.gz"
	@if [ -f "$(RELEASE_SHA256)" ]; then \
		cp "$(RELEASE_SHA256)" release/; \
		echo "  ✓ $(RELEASE_NAME).tar.gz.sha256"; \
	else \
		( cd release && sha256sum "$(RELEASE_NAME).tar.gz" > "$(RELEASE_NAME).tar.gz.sha256" ); \
		echo "  ✓ $(RELEASE_NAME).tar.gz.sha256 (generated)"; \
	fi
	@echo "=== Done ==="

## check-units — verify the RELEASE's unit files, not host-collected ones.
## (services repo INC-2026-0018: bare WorkingDirectory=/var/lib/globular/... causes
## status=200/CHDIR before ExecStartPre.) Units now ship inside the packages, so
## this inspects the staged tarball instead of a units/ directory.
check-units:
	@./scripts/check-systemd-working-directory.sh

## build — build the Docker image (runs collect first)
build: collect
	docker build \
		--build-arg RELEASE_VERSION=$(RELEASE_VERSION) \
		-t globulario/globular-node:latest .
	@$(MAKE) --no-print-directory prune-cache

## prune-cache — reclaim BuildKit cache and dead volumes
##
## Every image build leaves BuildKit cache that is never reused across release
## versions, and every `compose down -v` leaves its volumes behind. Left alone
## these grow without bound: seven release cycles put 46 GB of build cache and
## 3.7 GB of dead volumes on a 338 GB disk and took it to 94% full, which
## eventually wedged a run mid-suite. Both are pure cache — safe to drop; the
## only cost is a slower next build.
prune-cache:
	@before=$$(df --output=avail -BG / | tail -1 | tr -d ' G'); \
	docker builder prune -af >/dev/null 2>&1 || true; \
	docker volume prune -f  >/dev/null 2>&1 || true; \
	after=$$(df --output=avail -BG / | tail -1 | tr -d ' G'); \
	echo "prune-cache: freed $$((after-before))G (now $${after}G free)"

## check-host-aio — the host kernel must have enough AIO contexts for every
## ScyllaDB instance in the sim.
##
## fs.aio-max-nr is a HOST-WIDE budget shared by all containers; seastar needs
## ~66.5k per node, so the 65536 default is not enough for even one storage
## node. It fails late and confusingly: dpkg installs, the package reports
## installed, and scylla-server crash-loops on "Your system does not satisfy
## minimum AIO requirements" — which then strands every service whose
## ExecStartPre waits on :9042 (2026-08-11: node-2 stuck in start-pre with 9
## units queued, then its etcd data dir corrupted under the restart churn).
## The cluster-doctor sees only the downstream convergence errors, never the
## sysctl. Check it before the containers exist.
check-host-aio:
	@need=$$(( 66563 * 3 )); \
	have=$$(cat /proc/sys/fs/aio-max-nr 2>/dev/null || echo 0); \
	if [ "$$have" -lt "$$need" ]; then \
		echo "  ✗ fs.aio-max-nr=$$have is below $$need (3 storage nodes x 66563)."; \
		echo "    ScyllaDB will crash-loop on every storage node. Raise it with:"; \
		echo "      sudo sysctl -w fs.aio-max-nr=1048576"; \
		echo "    Persist it with:"; \
		echo "      echo 'fs.aio-max-nr = 1048576' | sudo tee /etc/sysctl.d/99-globular-scylla.conf"; \
		exit 1; \
	fi; \
	echo "  ✓ fs.aio-max-nr=$$have"

## up — start the 5-node cluster
up: check-host-aio build
	docker compose up -d
	@echo ""
	@echo "Cluster starting..."
	@echo "  Admin:      https://localhost:443"
	@echo "  Prometheus: http://localhost:9090"
	@echo "  Logs:       make logs"
	@echo "  Status:     make status"

## down — stop the cluster (preserve state)
down:
	docker compose down

## clean — stop + remove all volumes (full reset)
clean:
	docker compose down -v
	rm -rf release/

## logs — follow all container logs
logs:
	docker compose logs -f

## log-N — follow a single node's logs (e.g., make log-1)
log-%:
	docker compose logs -f node-$*

## status — check cluster health
status:
	@echo "=== Container status ==="
	@docker compose ps
	@echo ""
	@echo "=== etcd health ==="
	@docker exec globular-node-1 \
		/usr/lib/globular/bin/etcdctl \
		--endpoints=https://10.10.0.11:2379 \
		--cacert=/var/lib/globular/pki/ca.crt \
		--cert=/var/lib/globular/pki/issued/services/service.crt \
		--key=/var/lib/globular/pki/issued/services/service.key \
		endpoint health 2>/dev/null || echo "etcd not ready yet"

## shell — exec into a node (e.g., make shell N=1)
shell:
	docker exec -it globular-node-$(N) bash

## test — run integration tests against the running cluster
test:
	@echo "=== Running integration tests ==="
	cd $(SERVICES_DIR) && GLOBULAR_TEST_CLUSTER=1 make test-integration

# ── V1 Test Harness ──────────────────────────────────────────────────────────
TEST_BIN = ./tests/harness/bin/globular-test

## quickstart-up — start the cluster (alias for up without rebuild)
quickstart-up:
	docker compose up -d
	@echo "Cluster starting. Run 'make quickstart-logs' or 'make test-wait' to monitor."

## quickstart-down — stop cluster, preserve state
quickstart-down:
	docker compose down

## quickstart-reset — full reset (removes all state volumes)
quickstart-reset:
	docker compose down -v
	docker compose up -d

# ── Snapshots ────────────────────────────────────────────────────────────────
# Scenario work (especially resilience/recovery, which deliberately stop nodes
# and wipe etcd) leaves the cluster damaged. Rebuilding costs ~8 min of Day-0
# plus ~4 min of serialized joins. A snapshot returns you to a converged
# 5-node cluster in about a minute.
#
# This is an ITERATION aid only. `make clean && make up` remains the way to
# exercise the real install path — never let a snapshot stand in for that.

## snapshot — freeze the current converged cluster (~2 GB)
snapshot:
	./scripts/snapshot.sh save

## snapshot-restore — return to the frozen cluster (~1 min)
snapshot-restore:
	./scripts/snapshot.sh restore

## snapshot-list — show what is stored
snapshot-list:
	./scripts/snapshot.sh list

# ── Environment-matrix checks ────────────────────────────────────────────────
# These validate properties of the RELEASE and the HOST, not of a running
# cluster, so they are make targets rather than YAML scenarios.

## check-glibc-floor — every shipped binary must run on the oldest supported OS
## (services repo gate; catches file_server-style build-provenance drift)
check-glibc-floor:
	$(SERVICES_DIR)/scripts/check-glibc-floor.sh \
		$(SERVICES_DIR)/dist/$(RELEASE_NAME)

## test-concurrent-join — regression for the Day-1 join race (5.4 writes
## etcd.yaml from a pre-member-add snapshot). Destructive: wipes node-4/5.
test-concurrent-join:
	./scripts/test-concurrent-join.sh

## test-hardened-tmp — prove Day-0 survives a CIS-style noexec /tmp.
## Destructive: wipes the cluster. Run standalone, ~10 min.
test-hardened-tmp:
	@echo "=== Day-0 on a hardened host (/tmp noexec) ==="
	docker compose down -v
	docker compose -f docker-compose.yml -f docker-compose.hardened.yml up -d node-1
	@echo "Watching Day-0; a failure here means an [[ -x ]]-gated install step"
	@echo "has the same defect codex_0.142.3 had."
	@for i in $$(seq 1 120); do \
		if docker exec globular-node-1 test -f /var/lib/globular/.quickstart-bootstrap-complete 2>/dev/null; then \
			echo "  PASS: Day-0 completed with noexec /tmp"; exit 0; \
		fi; \
		if [ "$$(docker exec globular-node-1 systemctl is-active globular-quickstart-bootstrap 2>/dev/null)" = "failed" ]; then \
			echo "  FAIL: Day-0 aborted under noexec /tmp:"; \
			docker exec globular-node-1 journalctl -u globular-quickstart-bootstrap --no-pager -n 20 | tail -20; \
			exit 1; \
		fi; \
		sleep 15; \
	done; echo "  FAIL: timeout"; exit 1

## quickstart-logs — follow all container logs
quickstart-logs:
	docker compose logs -f

## test-wait — wait for cluster to become healthy (up to 5 min)
test-wait:
	$(TEST_BIN) cluster wait 300

## test-smoke — run the smoke test suite (cluster must be up)
test-smoke:
	$(TEST_BIN) suite smoke

## test-functional — run the functional test suite
test-functional:
	$(TEST_BIN) suite functional

## test-security — run the security test suite
test-security:
	$(TEST_BIN) suite security

## test-resilience — run the resilience test suite
test-resilience:
	$(TEST_BIN) suite resilience

## test-recovery — run the recovery test suite
test-recovery:
	$(TEST_BIN) suite recovery

## test-soak — run the soak test suite
test-soak:
	$(TEST_BIN) suite soak

## test-upgrade — run the upgrade suite (package + platform upgrade, and the
## 2026-08-16 incident regressions: liveness, etcd backend, CAS reachability)
test-upgrade:
	$(TEST_BIN) suite upgrade

## test-authority — run the authority suite (gray failure: zombie leaders,
## identity collisions, missed generations, atomicity under crash and ENOSPC)
test-authority:
	$(TEST_BIN) suite authority

## test-v1-certification — full V1 certification run (all suites)
test-v1-certification:
	@echo "=== V1 CERTIFICATION RUN ==="
	$(TEST_BIN) suite smoke && \
	$(TEST_BIN) suite functional && \
	$(TEST_BIN) suite security && \
	$(TEST_BIN) suite resilience && \
	$(TEST_BIN) suite recovery && \
	$(TEST_BIN) suite upgrade && \
	$(TEST_BIN) suite authority
	@echo "=== V1 CERTIFICATION COMPLETE ==="

## ci-smoke — bring up cluster then run smoke suite (CI entry point)
ci-smoke: up test-wait test-smoke

## test-scenario — run a single scenario (SCENARIO=path/to/scenario.yaml)
test-scenario:
	$(TEST_BIN) scenario $(SCENARIO)

## test-scenario-keep — run a scenario, keep artifacts on failure
test-scenario-keep:
	$(TEST_BIN) scenario $(SCENARIO) --keep-cluster --keep-artifacts

## test-parity-report — generate service parity report
test-parity-report:
	$(TEST_BIN) report parity

## test-health-matrix — generate service health matrix
test-health-matrix:
	$(TEST_BIN) report service-health

## test-authz-report — generate authz report
test-authz-report:
	$(TEST_BIN) report authz

## test-recovery-report — generate recovery report
test-recovery-report:
	$(TEST_BIN) report recovery

## check-test-schemas — validate all scenario YAML files
check-test-schemas:
	$(TEST_BIN) check schemas

## check-test-scenarios — list all scenarios
check-test-scenarios:
	$(TEST_BIN) check scenarios

## test-debug-shell — open shell on a node (NODE=node-1)
test-debug-shell:
	$(TEST_BIN) debug shell $(NODE)

# ── Awareness targets ─────────────────────────────────────────────────────────

## test-awareness-smoke — run smoke/cluster-cold-boot with awareness enabled
test-awareness-smoke:
	@echo "=== Awareness: smoke/cluster-cold-boot ==="
	$(TEST_BIN) scenario tests/scenarios/smoke/cluster-cold-boot.yaml --keep-artifacts
	@echo ""
	@echo "Awareness artifacts:"
	@ls tests/reports/latest/cluster-cold-boot/awareness/ 2>/dev/null || \
		echo "  (no artifacts — run 'make test-wait' first if cluster is not up)"

## test-awareness-recovery — run recovery/layer-parity-spot-check with awareness enabled
test-awareness-recovery:
	@echo "=== Awareness: recovery/layer-parity-spot-check ==="
	$(TEST_BIN) scenario tests/scenarios/recovery/layer-parity-spot-check.yaml --keep-artifacts
	@echo ""
	@echo "Awareness artifacts:"
	@ls tests/reports/latest/layer-parity-spot-check/awareness/ 2>/dev/null || \
		echo "  (no artifacts)"

## test-awareness-debug — run a scenario and keep all awareness artifacts (SCENARIO=path)
test-awareness-debug:
	$(TEST_BIN) scenario $(SCENARIO) --keep-cluster --keep-artifacts

## awareness-train-day0 — run Day-0 bootstrap training scenario with full awareness
awareness-train-day0:
	@AWARENESS_TRAINING=1 AWARENESS_INCLUDE_RUNTIME=1 \
		tests/harness/bin/globular-test scenario \
		tests/scenarios/training/day0-single-node-awareness.yaml

## awareness-train-day1 — run Day-1 join training scenario with full awareness
awareness-train-day1:
	@AWARENESS_TRAINING=1 AWARENESS_INCLUDE_RUNTIME=1 \
		tests/harness/bin/globular-test scenario \
		tests/scenarios/training/day1-join-second-node-awareness.yaml

## awareness-train-scenario — run a single training scenario (SCENARIO=path)
## Usage: make awareness-train-scenario SCENARIO=tests/scenarios/training/my-scenario.yaml
awareness-train-scenario:
	@if [ -z "$(SCENARIO)" ]; then \
		echo "Usage: make awareness-train-scenario SCENARIO=tests/scenarios/training/<name>.yaml"; \
		exit 1; \
	fi
	@AWARENESS_TRAINING=1 AWARENESS_INCLUDE_RUNTIME=1 \
		tests/harness/bin/globular-test scenario "$(SCENARIO)"

## awareness-training-suite — run all training scenarios sequentially
awareness-training-suite:
	@echo "=== Awareness Training Suite ===" && \
	AWARENESS_TRAINING=1 AWARENESS_INCLUDE_RUNTIME=1 \
		tests/harness/bin/globular-test suite training

## awareness-reset — reset cluster containers, preserve training ledger
awareness-reset:
	@echo "[awareness-reset] Stopping cluster..."
	@docker compose down -v 2>&1 | sed 's/^/  /'
	@echo "[awareness-reset] Starting cluster..."
	@docker compose up -d 2>&1 | sed 's/^/  /'
	@echo "[awareness-reset] Done. Ledger preserved at tests/reports/awareness-training-ledger.jsonl"

## awareness-ledger — print the last 20 training ledger entries
awareness-ledger:
	@LEDGER=tests/reports/awareness-training-ledger.jsonl; \
	if [ ! -f "$$LEDGER" ]; then \
		echo "No ledger yet. Run a training scenario first."; exit 0; \
	fi; \
	echo "=== Training Ledger (last 20 entries) ==="; \
	tail -20 "$$LEDGER" | python3 -c " \
import json,sys \
for line in sys.stdin: \
    line=line.strip() \
    if not line: continue \
    try: \
        d=json.loads(line) \
        print(f\"  {d.get('timestamp','')}  {d.get('scenario','?'):<40}  {d.get('result','?'):<12}  awareness={d.get('awareness_status','?')}\") \
    except Exception: \
        print(f'  {line[:120]}') \
"

## awareness-patterns — run all pattern simulation scenarios
awareness-patterns:
	@echo "=== Awareness Pattern Simulations ===" && \
	AWARENESS_TRAINING=1 AWARENESS_INCLUDE_RUNTIME=1 \
		tests/harness/bin/globular-test suite patterns

## awareness-pattern — run one pattern scenario (SCENARIO=path)
## Usage: make awareness-pattern SCENARIO=tests/scenarios/patterns/desired-state-reconciliation.yaml
awareness-pattern:
	@if [ -z "$(SCENARIO)" ]; then \
		echo "Usage: make awareness-pattern SCENARIO=tests/scenarios/patterns/<name>.yaml"; \
		exit 1; \
	fi
	@AWARENESS_TRAINING=1 AWARENESS_INCLUDE_RUNTIME=1 \
		tests/harness/bin/globular-test scenario "$(SCENARIO)"

## awareness-pattern-latest — print latest pattern report PATTERNS.md summaries
awareness-pattern-latest:
	@LATEST=$$(readlink -f tests/reports/latest 2>/dev/null); \
	if [ -z "$$LATEST" ] || [ ! -d "$$LATEST" ]; then \
		echo "No latest run found. Run a pattern scenario first."; exit 1; \
	fi; \
	echo "Latest run: $$LATEST"; \
	echo ""; \
	for pmd in "$$LATEST"/*/PATTERNS.md; do \
		[ -f "$$pmd" ] || continue; \
		scenario=$$(basename "$$(dirname "$$pmd")"); \
		echo "── $$scenario ──"; \
		cat "$$pmd"; \
		echo ""; \
	done; \
	LEDGER=tests/reports/awareness-pattern-ledger.jsonl; \
	if [ -f "$$LEDGER" ]; then \
		echo "=== Pattern Ledger (last 10) ==="; \
		tail -10 "$$LEDGER" | python3 -c " \
import json,sys \
for line in sys.stdin: \
    line=line.strip() \
    if not line: continue \
    try: \
        d=json.loads(line) \
        tested=','.join(d.get('patterns_tested',[])[:2]) \
        print(f\"  {d.get('timestamp','')}  {d.get('scenario','?'):<40}  {d.get('pattern_result','?'):<8}  patterns={tested}\") \
    except: pass \
"; \
	fi

## awareness-pattern-day1 — run the Day-1 bootstrap pattern scenario
awareness-pattern-day1:
	@AWARENESS_TRAINING=1 AWARENESS_INCLUDE_RUNTIME=1 \
		tests/harness/bin/globular-test scenario \
		tests/scenarios/patterns/bootstrap-then-promote-day1.yaml

## awareness-latest — print path to latest awareness artifacts and show preflight/debug-session
awareness-latest:
	@LATEST=$$(readlink -f tests/reports/latest 2>/dev/null); \
	if [ -z "$$LATEST" ] || [ ! -d "$$LATEST" ]; then \
		echo "No latest run found. Run a scenario first."; exit 1; \
	fi; \
	echo "Latest run: $$LATEST"; \
	echo ""; \
	for adir in "$$LATEST"/*/awareness; do \
		[ -d "$$adir" ] || continue; \
		scenario=$$(basename "$$(dirname "$$adir")"); \
		echo "── $$scenario/awareness ──"; \
		ls "$$adir/" 2>/dev/null; \
		echo ""; \
		if [ -f "$$adir/preflight.agent.txt" ]; then \
			echo "=== preflight.agent.txt ==="; \
			cat "$$adir/preflight.agent.txt"; \
			echo ""; \
		fi; \
		if [ -f "$$adir/debug-session.agent.txt" ]; then \
			echo "=== debug-session.agent.txt ==="; \
			cat "$$adir/debug-session.agent.txt"; \
			echo ""; \
		fi; \
	done
