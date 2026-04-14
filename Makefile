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

.PHONY: collect build up down clean logs status shell test

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

## test — run integration tests (Phase 5)
test:
	@echo "Integration tests not yet implemented (Phase 5)"
