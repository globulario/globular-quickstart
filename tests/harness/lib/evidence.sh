#!/usr/bin/env bash
# evidence.sh — comprehensive non-awareness evidence collection
#
# Collects cluster state snapshots for durable post-mortem analysis.
# All functions write under <out_dir>/evidence/ and degrade gracefully
# when the cluster is not running.
#
# Functions:
#   evidence_collect_all        — collect all categories
#   evidence_collect_docker     — container status, events, logs
#   evidence_collect_etcd       — etcd key dumps
#   evidence_collect_systemd    — systemd unit states per node
#   evidence_collect_globular_state  — desired/installed state, workflows, doctor
#
# Environment:
#   EVIDENCE_NODES="node-1 node-2 node-3 node-4 node-5"  nodes to query
#   EVIDENCE_ETCD_NODE="node-1"                            etcd primary node

EVIDENCE_NODES="${EVIDENCE_NODES:-node-1 node-2 node-3 node-4 node-5}"
EVIDENCE_ETCD_NODE="${EVIDENCE_ETCD_NODE:-node-1}"
EVIDENCE_ETCD_EP="https://10.10.0.11:2379"
EVIDENCE_PKI="/var/lib/globular/pki"

# ── helpers ───────────────────────────────────────────────────────────────────

# _ev_dir <out_dir> [subdir]
# Print and create an evidence subdirectory.
_ev_dir() {
    local d="$1/evidence${2:+/$2}"
    mkdir -p "$d"
    printf '%s' "$d"
}

# _ev_log_error <ev_dir> <label> <msg>
_ev_log_error() {
    local ev_dir="$1" label="$2" msg="$3"
    printf '[%s] %s: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$label" "$msg" \
        >> "$ev_dir/evidence-errors.log"
}

# _ev_node_running <node>
# Returns 0 if the container globular-<node> is running.
_ev_node_running() {
    local node="$1"
    docker inspect "globular-${node}" --format '{{.State.Running}}' 2>/dev/null \
        | grep -q 'true'
}

# _ev_exec <node> <cmd...>
# Run a command in globular-<node>. Writes combined stdout+stderr to stdout.
_ev_exec() {
    local node="$1"; shift
    docker exec "globular-${node}" "$@" 2>&1
}

# _ev_etcdctl <args...>
# Run etcdctl in the primary etcd node with cluster credentials.
_ev_etcdctl() {
    docker exec "globular-${EVIDENCE_ETCD_NODE}" \
        /usr/lib/globular/bin/etcdctl \
        --endpoints="$EVIDENCE_ETCD_EP" \
        --cacert="${EVIDENCE_PKI}/ca.crt" \
        --cert="${EVIDENCE_PKI}/issued/services/service.crt" \
        --key="${EVIDENCE_PKI}/issued/services/service.key" \
        "$@" 2>&1
}

# _ev_run_to_file <ev_dir> <label> <out_file> <cmd...>
# Run command, write output to out_file. Log errors to evidence-errors.log.
_ev_run_to_file() {
    local ev_dir="$1" label="$2" out_file="$3"
    shift 3
    local tmp; tmp="$(mktemp)"
    if "$@" > "$tmp" 2>&1; then
        mv "$tmp" "$out_file"
    else
        local rc=$?
        mv "$tmp" "$out_file" 2>/dev/null || true  # keep partial output
        _ev_log_error "$ev_dir" "$label" "exit $rc"
    fi
}

# ── top-level ─────────────────────────────────────────────────────────────────

# evidence_collect_all <out_dir> [scenario_file] [result_json]
# Collect all available evidence.  Non-fatal even if cluster is down.
evidence_collect_all() {
    local out_dir="$1"
    local scenario_file="${2:-}"
    local result_json="${3:-}"

    local ev_dir
    ev_dir="$(_ev_dir "$out_dir")"
    echo "  [evidence] collecting cluster evidence → $ev_dir"

    # Copy in scenario file and result if provided.
    if [ -n "$scenario_file" ] && [ -f "$scenario_file" ]; then
        cp "$scenario_file" "$ev_dir/scenario.yaml" 2>/dev/null || true
    fi
    if [ -n "$result_json" ] && [ -f "$result_json" ]; then
        cp "$result_json" "$ev_dir/result.json" 2>/dev/null || true
    fi

    evidence_collect_docker    "$out_dir"
    evidence_collect_etcd      "$out_dir"
    evidence_collect_systemd   "$out_dir"
    evidence_collect_globular_state "$out_dir"

    echo "  [evidence] collection complete"
}

# ── docker evidence ───────────────────────────────────────────────────────────

# evidence_collect_docker <out_dir>
# Writes: evidence/docker-ps.txt, evidence/docker-events.log,
#         evidence/container-logs/<container>.log
evidence_collect_docker() {
    local out_dir="$1"
    local ev_dir; ev_dir="$(_ev_dir "$out_dir")"

    # Container status
    _ev_run_to_file "$ev_dir" "docker-ps" "$ev_dir/docker-ps.txt" \
        docker compose ps

    # Recent docker events (last 10 minutes via --since)
    local ten_min_ago
    ten_min_ago="$(date -u -d '10 minutes ago' '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null \
        || date -u -v-10M '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || true)"
    if [ -n "$ten_min_ago" ]; then
        _ev_run_to_file "$ev_dir" "docker-events" "$ev_dir/docker-events.log" \
            docker events --since "$ten_min_ago" --until "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
            --format '{{.Time}} {{.Type}} {{.Action}} {{.Actor.ID}}' 2>/dev/null || true
    fi

    # Container logs (last 500 lines each)
    local logs_dir; logs_dir="$(_ev_dir "$out_dir" "container-logs")"
    local containers=()
    IFS=' ' read -ra _nodes <<< "$EVIDENCE_NODES"
    for n in "${_nodes[@]}"; do
        containers+=("$n")
    done
    containers+=(scylladb)

    for container in "${containers[@]}"; do
        local cname="globular-${container}"
        if docker inspect "$cname" >/dev/null 2>&1; then
            _ev_run_to_file "$ev_dir" "logs($container)" "$logs_dir/${container}.log" \
                docker compose logs --no-color --tail=500 "$container"
        fi
    done
}

# ── etcd evidence ─────────────────────────────────────────────────────────────

# evidence_collect_etcd <out_dir>
# Writes key dumps under evidence/etcd/
evidence_collect_etcd() {
    local out_dir="$1"
    local etcd_dir; etcd_dir="$(_ev_dir "$out_dir" "etcd")"

    if ! _ev_node_running "$EVIDENCE_ETCD_NODE"; then
        _ev_log_error "$etcd_dir" "etcd" "node $EVIDENCE_ETCD_NODE not running"
        printf 'etcd node not running\n' > "$etcd_dir/UNAVAILABLE.txt"
        return 0
    fi

    # Etcd health
    _ev_run_to_file "$etcd_dir" "etcd-health" "$etcd_dir/health.txt" \
        _ev_etcdctl endpoint health

    # Key dumps for critical prefixes
    declare -A _prefixes=(
        ["services"]="/globular/services/"
        ["nodes"]="/globular/nodes/"
        ["desired"]="/globular/resources/DesiredService/"
        ["releases"]="/globular/resources/ServiceRelease/"
        ["config"]="/globular/system/config"
        ["domains"]="/globular/domains/v1/"
        ["ingress"]="/globular/ingress/v1/"
        ["ai-jobs"]="/globular/ai/jobs/"
    )

    for label in "${!_prefixes[@]}"; do
        local prefix="${_prefixes[$label]}"
        _ev_run_to_file "$etcd_dir" "etcd-keys($label)" "$etcd_dir/${label}.keys.txt" \
            _ev_etcdctl get "$prefix" --prefix --keys-only
    done

    # Selected values (compact view)
    _ev_run_to_file "$etcd_dir" "etcd-services-values" "$etcd_dir/services.values.txt" \
        _ev_etcdctl get /globular/services/ --prefix --print-value-only

    _ev_run_to_file "$etcd_dir" "etcd-desired-values" "$etcd_dir/desired.values.txt" \
        _ev_etcdctl get /globular/resources/DesiredService/ --prefix --print-value-only
}

# ── systemd evidence ──────────────────────────────────────────────────────────

# _SYSTEMD_SERVICES: key services to check per node
_SYSTEMD_SERVICES=(
    cluster-controller node-agent workflow cluster-doctor
    authentication rbac resource discovery event log dns
    repository monitoring ai-memory ai-executor
    minio sidekick scylla-manager etcd xds envoy
)

# evidence_collect_systemd <out_dir>
# Writes per-node unit states under evidence/systemd/<node>/
evidence_collect_systemd() {
    local out_dir="$1"
    local sd_dir; sd_dir="$(_ev_dir "$out_dir" "systemd")"

    IFS=' ' read -ra _nodes <<< "$EVIDENCE_NODES"
    for node in "${_nodes[@]}"; do
        if ! _ev_node_running "$node"; then
            mkdir -p "$sd_dir/$node"
            printf 'node not running\n' > "$sd_dir/$node/UNAVAILABLE.txt"
            continue
        fi

        local node_dir="$sd_dir/$node"
        mkdir -p "$node_dir"

        # Overall unit list
        _ev_run_to_file "$sd_dir" "systemctl-list($node)" \
            "$node_dir/units-list.txt" \
            docker exec "globular-${node}" systemctl list-units --no-pager --all \
            --type=service 'globular-*'

        # Per-service status
        for svc in "${_SYSTEMD_SERVICES[@]}"; do
            local unit="globular-${svc}.service"
            _ev_run_to_file "$sd_dir" "systemctl-status($node/$svc)" \
                "$node_dir/${svc}.status.txt" \
                docker exec "globular-${node}" systemctl status "$unit" --no-pager
        done
    done
}

# ── globular state evidence ───────────────────────────────────────────────────

# evidence_collect_globular_state <out_dir>
# Writes per-category state under evidence/globular/, workflow/, doctor/, etc.
evidence_collect_globular_state() {
    local out_dir="$1"

    if ! _ev_node_running "$EVIDENCE_ETCD_NODE"; then
        _ev_log_error "$(_ev_dir "$out_dir")" "globular-state" \
            "primary node not running"
        return 0
    fi

    # ── installed packages per node ──────────────────────────────────────────
    local pkg_dir; pkg_dir="$(_ev_dir "$out_dir" "node-agent")"
    IFS=' ' read -ra _nodes <<< "$EVIDENCE_NODES"
    for node in "${_nodes[@]}"; do
        if _ev_node_running "$node"; then
            # Read packages from etcd (node agent writes them there)
            local node_id
            node_id=$(_ev_exec "$node" hostname 2>/dev/null | tr -d '[:space:]' || echo "$node")
            _ev_run_to_file "$pkg_dir" "packages($node)" \
                "$pkg_dir/${node}-packages.txt" \
                _ev_etcdctl get "/globular/nodes/$node_id/packages/" --prefix --keys-only
        fi
    done

    # ── workflow state ───────────────────────────────────────────────────────
    local wf_dir; wf_dir="$(_ev_dir "$out_dir" "workflow")"
    _ev_run_to_file "$wf_dir" "workflow-keys" "$wf_dir/runs.keys.txt" \
        _ev_etcdctl get /globular/workflows/ --prefix --keys-only

    # ── cluster doctor ───────────────────────────────────────────────────────
    local dr_dir; dr_dir="$(_ev_dir "$out_dir" "doctor")"
    _ev_run_to_file "$dr_dir" "doctor-findings" "$dr_dir/findings.txt" \
        _ev_etcdctl get /globular/doctor/ --prefix --print-value-only

    # ── controller state ─────────────────────────────────────────────────────
    local ctrl_dir; ctrl_dir="$(_ev_dir "$out_dir" "controller")"
    _ev_run_to_file "$ctrl_dir" "controller-leader" "$ctrl_dir/leader.txt" \
        _ev_etcdctl get /globular/leader --print-value-only

    # ── repository ───────────────────────────────────────────────────────────
    local repo_dir; repo_dir="$(_ev_dir "$out_dir" "repository")"
    _ev_run_to_file "$repo_dir" "releases" "$repo_dir/releases.keys.txt" \
        _ev_etcdctl get /globular/resources/ServiceRelease/ --prefix --keys-only

    # ── objectstore / xds ────────────────────────────────────────────────────
    local xds_dir; xds_dir="$(_ev_dir "$out_dir" "xds")"
    _ev_run_to_file "$xds_dir" "xds-config" "$xds_dir/xds-keys.txt" \
        _ev_etcdctl get /globular/xds/ --prefix --keys-only

    local obj_dir; obj_dir="$(_ev_dir "$out_dir" "objectstore")"
    _ev_run_to_file "$obj_dir" "minio-status" "$obj_dir/minio-status.txt" \
        _ev_etcdctl get /globular/minio/ --prefix --keys-only
}
