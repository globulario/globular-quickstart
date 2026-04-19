SERVICES_DIR ?= ../services
BIN_SRC       = /usr/lib/globular/bin
UNIT_SRC      = /etc/systemd/system

# ── Binaries to include in the image ─────────────────────
# Core services (always needed)
CORE_BINS = \
	etcd etcdctl \
	node_agent_server \
	cluster_controller_server \
	workflow_server \
	cluster_doctor_server \
	dns_server \
	authentication_server \
	rbac_server \
	resource_server \
	discovery_server \
	event_server \
	log_server \
	xds envoy gateway

# Storage / monitoring
STORAGE_BINS = \
	minio mc \
	repository_server \
	monitoring_server \
	prometheus promtool \
	alertmanager amtool \
	node_exporter \
	backup_manager_server

# AI stack
AI_BINS = \
	ai_memory_server \
	ai_executor_server \
	ai_watcher_server \
	ai_router_server \
	globular-mcp-server

# Optional / user-facing
EXTRA_BINS = \
	echo_server \
	file_server \
	mcp \
	persistence_server \
	search_server \
	title_server \
	blog_server \
	media_server \
	globularcli

ALL_BINS = $(CORE_BINS) $(STORAGE_BINS) $(AI_BINS) $(EXTRA_BINS)

# ── Unit files to include ────────────────────────────────
UNITS = $(wildcard $(UNIT_SRC)/globular-*.service)

.PHONY: collect build up down clean logs status shell test \
	quickstart-up quickstart-down quickstart-reset quickstart-logs \
	test-wait test-smoke test-functional test-security test-resilience \
	test-recovery test-soak test-v1-certification ci-smoke \
	test-scenario test-scenario-keep \
	test-parity-report test-health-matrix test-authz-report test-recovery-report \
	check-test-schemas check-test-scenarios test-debug-shell

## collect — copy binaries + units into build context
collect:
	@echo "=== Collecting binaries ==="
	@mkdir -p binaries units
	@for b in $(ALL_BINS); do \
		if [ -f "$(BIN_SRC)/$$b" ]; then \
			cp "$(BIN_SRC)/$$b" binaries/; \
			echo "  ✓ $$b"; \
		else \
			echo "  ✗ $$b (not found, skipping)"; \
		fi \
	done
	@echo "=== Collecting unit files ==="
	@for u in $(UNITS); do \
		cp "$$u" units/; \
		echo "  ✓ $$(basename $$u)"; \
	done
	@echo "=== Done ==="

## build — build the Docker image (runs collect first)
build: collect
	docker build -t globulario/globular-node:latest .

## up — start the 5-node cluster
up: build
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
	rm -rf binaries/ units/

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

## test-v1-certification — full V1 certification run (all suites)
test-v1-certification:
	@echo "=== V1 CERTIFICATION RUN ==="
	$(TEST_BIN) suite smoke && \
	$(TEST_BIN) suite functional && \
	$(TEST_BIN) suite security && \
	$(TEST_BIN) suite resilience && \
	$(TEST_BIN) suite recovery
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
