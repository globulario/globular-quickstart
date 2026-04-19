#!/usr/bin/env bash
# cluster.sh — cluster lifecycle helpers for the test harness
#
# Wraps docker compose and the existing Makefile targets.
# ROOT_DIR must be set by the caller (path to globular-quickstart root).

COMPOSE_FILE="${ROOT_DIR}/docker-compose.yml"
COMPOSE_CMD="docker compose -f $COMPOSE_FILE"

# cluster_up [profile]
# Start the cluster. Builds image if not present.
cluster_up() {
    local profile="${1:-quickstart-5node}"
    echo "[cluster] Starting $profile..."
    cd "$ROOT_DIR"
    $COMPOSE_CMD up -d
    echo "[cluster] Cluster started. Use 'make logs' to follow."
}

# cluster_down [profile]
# Stop the cluster. Preserves volumes (state).
cluster_down() {
    echo "[cluster] Stopping cluster..."
    cd "$ROOT_DIR"
    $COMPOSE_CMD down
    echo "[cluster] Cluster stopped."
}

# cluster_reset [profile]
# Full reset: stop + remove volumes + start fresh.
cluster_reset() {
    echo "[cluster] Resetting cluster (removes all state)..."
    cd "$ROOT_DIR"
    $COMPOSE_CMD down -v
    $COMPOSE_CMD up -d
    echo "[cluster] Cluster reset and starting."
}

# cluster_logs [node]
# Follow logs. If node specified (e.g. "node-1"), follows that container only.
cluster_logs() {
    local node="${1:-}"
    cd "$ROOT_DIR"
    if [ -n "$node" ]; then
        $COMPOSE_CMD logs -f "$node"
    else
        $COMPOSE_CMD logs -f
    fi
}

# cluster_status
# Print compose status + etcd health (same as make status).
cluster_status() {
    cd "$ROOT_DIR"
    echo "=== Container status ==="
    $COMPOSE_CMD ps
    echo ""
    echo "=== etcd health ==="
    docker exec globular-node-1 \
        /usr/lib/globular/bin/etcdctl \
        --endpoints=https://10.10.0.11:2379 \
        --cacert=/var/lib/globular/pki/ca.crt \
        --cert=/var/lib/globular/pki/issued/services/service.crt \
        --key=/var/lib/globular/pki/issued/services/service.key \
        endpoint health 2>/dev/null || echo "etcd not ready"
}

# cluster_wait_healthy [timeout_seconds]
# Poll until the cluster reports healthy or timeout expires.
# Uses the same etcdctl pattern as make status.
cluster_wait_healthy() {
    local timeout="${1:-300}"
    local poll=5
    local deadline=$(($(date +%s) + timeout))

    echo "[cluster] Waiting for cluster to become healthy (timeout: ${timeout}s)..."

    while [ "$(date +%s)" -lt "$deadline" ]; do
        if docker exec globular-node-1 \
                /usr/lib/globular/bin/etcdctl \
                --endpoints=https://10.10.0.11:2379 \
                --cacert=/var/lib/globular/pki/ca.crt \
                --cert=/var/lib/globular/pki/issued/services/service.crt \
                --key=/var/lib/globular/pki/issued/services/service.key \
                endpoint health >/dev/null 2>&1; then
            # Check that at least 1 node agent has registered (has metrics port key)
            local node_keys nodes
            node_keys=$(docker exec globular-node-1 \
                /usr/lib/globular/bin/etcdctl \
                --endpoints=https://10.10.0.11:2379 \
                --cacert=/var/lib/globular/pki/ca.crt \
                --cert=/var/lib/globular/pki/issued/services/service.crt \
                --key=/var/lib/globular/pki/issued/services/service.key \
                get /globular/nodes/ --prefix --keys-only 2>/dev/null || echo "")
            nodes=$(echo "$node_keys" | grep '/node_agent_metrics_port$' | wc -l)
            if [ "$nodes" -gt 0 ]; then
                echo "[cluster] Healthy (${nodes} nodes heartbeating)."
                return 0
            fi
        fi
        echo "[cluster] Not ready yet, waiting ${poll}s..."
        sleep "$poll"
    done

    echo "[cluster] ERROR: cluster did not become healthy within ${timeout}s." >&2
    return 1
}

# cluster_collect_logs <output_dir> [node]
# Capture container logs to output_dir for evidence.
cluster_collect_logs() {
    local output_dir="$1"
    local node="${2:-}"
    mkdir -p "$output_dir"
    cd "$ROOT_DIR"

    if [ -n "$node" ]; then
        $COMPOSE_CMD logs --no-color "$node" > "$output_dir/${node}.log" 2>&1
    else
        for n in node-1 node-2 node-3 node-4 node-5 scylladb; do
            $COMPOSE_CMD logs --no-color "$n" > "$output_dir/${n}.log" 2>&1 || true
        done
    fi
}

# cluster_exec <node> <command...>
# Run a command in a cluster node container.
cluster_exec() {
    local node="$1"; shift
    docker exec "globular-${node}" "$@"
}
