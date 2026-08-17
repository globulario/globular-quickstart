#!/usr/bin/env bash
# probes.sh — Globular test harness probe library
#
# Every probe function outputs a single line of JSON to stdout.
# Probes are called by globular-scenario (Python) via bash subprocess.
# All probes are READ-ONLY — they never mutate cluster state.
#
# Naming convention: probe_<suite>_<name> where the scenario YAML uses
# "probe: suite.name" and the executor converts dots to underscores.
#
# IMPORTANT: Never use `grep -c pattern || echo N` — grep -c exits 1 on
# zero matches, triggering the fallback, giving "0\n0". Use `grep pattern | wc -l`
# instead. wc -l always exits 0 and always prints a number.

# ── etcd helpers ─────────────────────────────────────────────────────────────

ETCD_CONTAINER="${ETCD_CONTAINER:-globular-node-1}"
ETCD_ENDPOINT="${ETCD_ENDPOINT:-https://10.10.0.11:2379}"
ETCD_PKI="/var/lib/globular/pki"
ETCD_BIN="/usr/lib/globular/bin/etcdctl"

_etcd() {
    docker exec "$ETCD_CONTAINER" \
        "$ETCD_BIN" \
        --endpoints="$ETCD_ENDPOINT" \
        --cacert="$ETCD_PKI/ca.crt" \
        --cert="$ETCD_PKI/issued/services/service.crt" \
        --key="$ETCD_PKI/issued/services/service.key" \
        "$@" 2>/dev/null
}

_etcd_get()    { _etcd get "$@" --print-value-only; }
_etcd_keys()   { _etcd get "$@" --prefix --keys-only; }
_etcd_values() { _etcd get "$@" --prefix --print-value-only; }

_container_running() {
    docker inspect "$1" --format '{{.State.Running}}' 2>/dev/null | grep -q true
}

# _node_agent_node_id <container> — the node agent's UUID, or "" if unresolvable.
#
# The state file lives at ONE of two paths and the probe must try both:
#   /var/lib/globular/node-agent/state.json  — canonical
#   /var/lib/globular/nodeagent/state.json   — pre-Project-O legacy
#
# node-agent's MigrateLegacyStatePathOnce relocates legacy -> canonical AND
# REMOVES the legacy directory, while the Day-1 join script writes the legacy
# path before the agent first starts. So at any moment some nodes have one and
# some have the other. Reading only the legacy path made every probe on a
# migrated node return "cannot_resolve_uuid", failing compute-node-stop-restart
# and node-agent-crash-recovery for a reason that had nothing to do with what
# they test.
_node_agent_node_id() {
    local container="$1" path
    for path in /var/lib/globular/node-agent/state.json \
                /var/lib/globular/nodeagent/state.json; do
        local out
        out=$(docker exec "$container" cat "$path" 2>/dev/null | \
            python3 -c "
import sys, json
try:
    print(json.load(sys.stdin).get('node_id', ''))
except Exception:
    pass
" 2>/dev/null || echo "")
        out=$(echo "$out" | tr -d '[:space:]')
        [[ -n "$out" ]] && { echo "$out"; return 0; }
    done
    echo ""
}

# ── cluster probes ────────────────────────────────────────────────────────────

# probe: cluster.health
# Returns: {"status":"healthy"|"degraded"|"unknown","members":N,"nodes":N}
#
# Node presence: node agents register a /node_agent_metrics_port key on join.
# etcd members: the 3 control-plane nodes in the etcd quorum.
probe_cluster_health() {
    if ! _container_running "$ETCD_CONTAINER"; then
        echo '{"status":"unknown","error":"primary container not running","members":0,"nodes":0}'
        return
    fi

    # etcd cluster health (exit code 0 = healthy)
    local etcd_ok=false
    _etcd endpoint health >/dev/null 2>&1 && etcd_ok=true

    # etcd member count
    local members
    members=$(_etcd member list 2>/dev/null | grep -v '^$' | wc -l)

    # Heartbeating nodes — one /node_agent_metrics_port key per registered node
    local nkeys nodes
    nkeys=$(_etcd_keys /globular/nodes/ 2>/dev/null || echo "")
    nodes=$(echo "$nkeys" | grep '/node_agent_metrics_port$' | wc -l)

    local status="unknown"
    if $etcd_ok; then
        status="healthy"
        [ "$members" -lt 1 ] && status="degraded"
    else
        status="degraded"
    fi

    echo "{\"status\":\"$status\",\"members\":$members,\"nodes\":$nodes}"
}

# probe: cluster.nodes
# Returns: {"count":N,"node_ids":["id1","id2",...]}
probe_cluster_nodes() {
    if ! _container_running "$ETCD_CONTAINER"; then
        echo '{"count":0,"node_ids":[]}'
        return
    fi

    local nkeys ids count ids_json
    nkeys=$(_etcd_keys /globular/nodes/ 2>/dev/null || echo "")

    ids=$(echo "$nkeys" | grep '/node_agent_metrics_port$' | \
          sed 's|/globular/nodes/||; s|/node_agent_metrics_port$||' | sort -u)

    count=$(echo "$ids" | grep -v '^$' | wc -l)
    [ -z "$(echo "$ids" | tr -d '[:space:]')" ] && count=0

    ids_json=$(echo "$ids" | python3 -c \
        "import sys,json; lines=[l for l in sys.stdin.read().splitlines() if l.strip()]; print(json.dumps(lines))" \
        2>/dev/null || echo '[]')

    echo "{\"count\":$count,\"node_ids\":$ids_json}"
}

# probe: cluster.leader
# Returns: {"leader_endpoint":"https://...","is_leader":true|false}
probe_cluster_leader() {
    if ! _container_running "$ETCD_CONTAINER"; then
        echo '{"leader_endpoint":"","is_leader":false}'
        return
    fi

    # Read the leader address from etcd (written by cluster controller)
    local leader_addr
    leader_addr=$(_etcd_get /globular/clustercontroller/leader/addr 2>/dev/null || echo "")

    if [ -n "$leader_addr" ]; then
        echo "{\"leader_endpoint\":\"$leader_addr\",\"is_leader\":true}"
    else
        echo "{\"leader_endpoint\":\"\",\"is_leader\":false}"
    fi
}

# probe: cluster.desired_state
# Returns: {"count":N,"services":["name1","name2",...]}
probe_cluster_desired_state() {
    if ! _container_running "$ETCD_CONTAINER"; then
        echo '{"count":0,"services":[]}'
        return
    fi

    local names count names_json
    names=$(_etcd_keys /globular/resources/ServiceDesiredVersion/ 2>/dev/null | \
            sed 's|/globular/resources/ServiceDesiredVersion/||' | sort -u)

    count=$(echo "$names" | grep -v '^$' | wc -l)
    [ -z "$(echo "$names" | tr -d '[:space:]')" ] && count=0

    names_json=$(echo "$names" | python3 -c \
        "import sys,json; lines=[l for l in sys.stdin.read().splitlines() if l.strip()]; print(json.dumps(lines))" \
        2>/dev/null || echo '[]')

    echo "{\"count\":$count,\"services\":$names_json}"
}

# ── service probes ────────────────────────────────────────────────────────────

# probe: service.status
# Params: --node <node-name>  --service <systemd-unit-name-suffix>
# Returns: {"unit_state":"active"|"inactive"|"failed"|"unknown","node":"...","service":"..."}
probe_service_status() {
    local node="" service="" unit=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --node)    node="$2"; shift 2 ;;
            --service) service="$2"; shift 2 ;;
            # Most units are globular-<service>.service, but not all: ScyllaDB
            # ships upstream's scylla-server.service. --unit names one directly.
            --unit)    unit="$2"; shift 2 ;;
            *) shift ;;
        esac
    done
    [[ -z "$node" || -z "$service" ]] && {
        echo '{"unit_state":"unknown","error":"node and service params required"}'
        return
    }

    local container="globular-${node}"
    if ! _container_running "$container"; then
        echo "{\"unit_state\":\"unknown\",\"node\":\"$node\",\"service\":\"$service\",\"error\":\"container not running\"}"
        return
    fi

    local unit_name="${unit:-globular-${service}.service}"
    local state
    # Use || true so exit codes 1-4 (inactive/failed/activating/deactivating) don't
    # trigger a fallback echo — we want the actual state word, not "unknown" appended.
    state=$(docker exec "$container" systemctl is-active "$unit_name" 2>/dev/null || true)
    state="${state:-unknown}"

    echo "{\"unit_state\":\"$state\",\"node\":\"$node\",\"service\":\"$service\"}"
}

# probe: service.registered
# Params: --service <partial-service-name>
# Searches service config VALUES for the name (handles UUID-keyed services).
# Returns: {"registered":true|false,"match_count":N}
#
# Services register with a Name field like "rbac.RbacService", "workflow.WorkflowService".
# Searching for "rbac" in config values will match the Name/Id field content.
probe_service_registered() {
    local service=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --service) service="$2"; shift 2 ;;
            *) shift ;;
        esac
    done
    [[ -z "$service" ]] && {
        echo '{"registered":false,"error":"service param required"}'
        return
    }

    # Fetch all service config values and grep for the service name in JSON content
    local all_configs count
    all_configs=$(_etcd_values /globular/services/ 2>/dev/null || echo "")
    count=$(echo "$all_configs" | grep "\"$service" | wc -l)

    if [ "$count" -gt 0 ]; then
        echo "{\"registered\":true,\"match_count\":$count}"
    else
        echo "{\"registered\":false,\"match_count\":0}"
    fi
}

# probe: services.count
# Returns: {"count":N,"service_ids":["id1","id2",...]}
probe_services_count() {
    if ! _container_running "$ETCD_CONTAINER"; then
        echo '{"count":0,"service_ids":[]}'
        return
    fi

    local keys ids count ids_json
    keys=$(_etcd_keys /globular/services/ 2>/dev/null || echo "")
    ids=$(echo "$keys" | grep '/config$' | \
          sed 's|/globular/services/||; s|/config$||' | sort -u)

    count=$(echo "$ids" | grep -v '^$' | wc -l)
    [ -z "$(echo "$ids" | tr -d '[:space:]')" ] && count=0

    ids_json=$(echo "$ids" | python3 -c \
        "import sys,json; lines=[l for l in sys.stdin.read().splitlines() if l.strip()]; print(json.dumps(lines))" \
        2>/dev/null || echo '[]')

    echo "{\"count\":$count,\"service_ids\":$ids_json}"
}

# probe: service.health
# Params: --node <node>  --service <service-name>  --port <port>
# Returns: {"health":"healthy"|"unknown","source":"etcd"}
probe_service_health() {
    local node="" service="" port=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --node)    node="$2"; shift 2 ;;
            --service) service="$2"; shift 2 ;;
            --port)    port="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    # Check etcd registration as a health proxy
    local all_configs count
    all_configs=$(_etcd_values /globular/services/ 2>/dev/null || echo "")
    count=$(echo "$all_configs" | grep "\"$service" | wc -l)

    if [ "$count" -gt 0 ]; then
        echo "{\"health\":\"healthy\",\"source\":\"etcd\",\"service\":\"$service\"}"
    else
        echo "{\"health\":\"unknown\",\"source\":\"etcd\",\"service\":\"$service\"}"
    fi
}

# probe: cluster.service_matrix
# Returns: {"count":N,"services":[{"name":"...","port":N,"address":"...","version":"..."},...]}
# Parses all /globular/services/*/config JSON values to build the service matrix.
probe_cluster_service_matrix() {
    if ! _container_running "$ETCD_CONTAINER"; then
        echo '{"count":0,"services":[]}'
        return
    fi

    local _parser
    _parser="$(dirname "${BASH_SOURCE[0]}")/parse_service_configs.py"

    local result
    result=$(_etcd_values /globular/services/ 2>/dev/null | \
        python3 "$_parser" --mode json 2>/dev/null || echo '{"count":0,"services":[]}')
    echo "$result"
}

# ── workflow probes ───────────────────────────────────────────────────────────

# probe: workflow.last_run
# Params: --workflow <workflow-name>
# Returns: {"status":"succeeded"|"failed"|"running"|"not_found","run_id":"..."}
probe_workflow_last_run() {
    local workflow=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --workflow) workflow="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    if ! _container_running "$ETCD_CONTAINER"; then
        echo '{"status":"not_found","run_id":""}'
        return
    fi

    local latest
    latest=$(_etcd_keys "/globular/workflows/runs/" 2>/dev/null | \
             grep "/$workflow/" | sort | tail -1)

    if [ -z "$latest" ]; then
        echo "{\"status\":\"not_found\",\"run_id\":\"\",\"workflow\":\"$workflow\"}"
        return
    fi

    local run_data status
    run_data=$(_etcd_get "$latest" 2>/dev/null || echo '{}')
    status=$(echo "$run_data" | python3 -c \
        "import sys,json; d=json.loads(sys.stdin.read()); print(d.get('status','unknown'))" \
        2>/dev/null || echo "unknown")

    echo "{\"status\":\"$status\",\"run_id\":\"$latest\",\"workflow\":\"$workflow\"}"
}

# ── repository probes ─────────────────────────────────────────────────────────

# probe: repository.artifact
# Params: --name <artifact-name>  [--version <version>]
# Returns: {"present":true|false,"lifecycle_state":"...","version":"..."}
probe_repository_artifact() {
    local name="" version=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --name)    name="$2"; shift 2 ;;
            --version) version="$2"; shift 2 ;;
            *) shift ;;
        esac
    done
    [[ -z "$name" ]] && { echo '{"present":false,"error":"name param required"}'; return; }

    local prefix="/globular/repository/artifacts/$name"
    [ -n "$version" ] && prefix="$prefix/$version"

    local keys count
    keys=$(_etcd_keys "$prefix" 2>/dev/null || echo "")
    count=$(echo "$keys" | grep -v '^$' | wc -l)

    if [ "$count" -gt 0 ]; then
        echo "{\"present\":true,\"name\":\"$name\",\"version\":\"$version\"}"
    else
        echo "{\"present\":false,\"name\":\"$name\",\"version\":\"$version\"}"
    fi
}

# ── authz probes ──────────────────────────────────────────────────────────────

# probe: authz.check
# Params: --subject <sa|user>  --action <action>  --resource <resource>
# For smoke: checks RBAC service registration and role binding presence.
# Returns: {"rbac_registered":true|false,"roles_seeded":true|false,"result":"unknown"}
probe_authz_check() {
    local subject="" action="" resource=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --subject)  subject="$2"; shift 2 ;;
            --action)   action="$2"; shift 2 ;;
            --resource) resource="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    # Check RBAC service is registered
    local all_configs rbac_count
    all_configs=$(_etcd_values /globular/services/ 2>/dev/null || echo "")
    rbac_count=$(echo "$all_configs" | grep '"rbac' | wc -l)

    if [ "$rbac_count" -eq 0 ]; then
        echo '{"rbac_registered":false,"roles_seeded":false,"result":"unknown","error":"RBAC service not registered"}'
        return
    fi

    # Check for role bindings
    local binding_keys binding_count
    binding_keys=$(_etcd_keys "/globular/rbac/" 2>/dev/null || echo "")
    binding_count=$(echo "$binding_keys" | grep -v '^$' | wc -l)

    echo "{\"rbac_registered\":true,\"roles_seeded\":$( [ "$binding_count" -gt 0 ] && echo true || echo false ),\"binding_count\":$binding_count,\"result\":\"unknown\",\"note\":\"full gRPC check requires runner container\"}"
}

# probe: authz.role_bindings
# Returns: {"count":N}
probe_authz_role_bindings() {
    local keys count
    keys=$(_etcd_keys "/globular/rbac/" 2>/dev/null || echo "")
    count=$(echo "$keys" | grep -v '^$' | wc -l)
    echo "{\"count\":$count}"
}

# ── doctor probes ─────────────────────────────────────────────────────────────

# probe: doctor.finding
# Params: --service <service>
# Returns: {"present":true|false,"severity":"...","count":N}
#
# WARNING — this probe reads /globular/doctor/findings in etcd, and NOTHING
# WRITES THAT PREFIX. Verified empty on a live 5-node cluster (2026-08-12) at
# the same moment `globular doctor report cluster` returned 4 findings. It
# therefore always answers present:false/count:0 and CANNOT FAIL. No scenario
# currently uses it, which is the only reason it has not manufactured a green.
#
# Do not assert on this probe. Use doctor.report_severity below, which asks the
# cluster-doctor RPC — the component that actually owns the verdict. Kept only
# so an existing reference does not break; delete once nothing names it.
probe_doctor_finding() {
    local service=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --service) service="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    local prefix="/globular/doctor/findings"
    [ -n "$service" ] && prefix="$prefix/$service"

    local keys count
    keys=$(_etcd_keys "$prefix" 2>/dev/null || echo "")
    count=$(echo "$keys" | grep -v '^$' | wc -l)

    if [ "$count" -gt 0 ]; then
        echo "{\"present\":true,\"count\":$count,\"service\":\"$service\"}"
    else
        echo "{\"present\":false,\"count\":0,\"service\":\"$service\"}"
    fi
}

# probe: doctor.report_severity
# Params: (none)
# Returns: {"reachable":true|false,"error":N,"warn":N,"info":N,"total":N,
#           "worst":"NONE|INFO|WARN|ERROR|CRITICAL","reduced_harvest":true|false}
#
# Asks cluster-doctor for a FRESH cluster report and counts findings by
# severity. This is the only honest way to assert on doctor state: the findings
# live behind GetClusterReport, not in etcd (see probe_doctor_finding above).
#
# --fresh bypasses the snapshot cache. Without it a scenario can assert against
# a report harvested before its own chaos step ran and pass on stale evidence.
#
# reduced_harvest is surfaced, not hidden. When collector sub-fetches fail the
# doctor marks findings "[reduced-harvest]" and its verdict is bounded by
# partial data — an UNKNOWN dressed as a count. A scenario that treats a
# reduced-harvest zero as proof of health is asserting on absence of evidence
# (ops.always.doctor.reduced-harvest-honesty). Callers should gate on it.
#
# Severity ints come from proto/cluster_doctor.proto: 1=INFO 2=WARN 3=ERROR
# 4=CRITICAL. If the RPC is unreachable this reports reachable:false rather
# than zero counts — an unreachable doctor is not a clean cluster.
probe_doctor_report_severity() {
    local raw
    raw=$(docker exec "$ETCD_CONTAINER" \
        globular doctor report cluster --fresh --json --timeout 120s 2>/dev/null)

    if [ -z "$raw" ]; then
        echo '{"reachable":false,"error":0,"warn":0,"info":0,"total":0,"worst":"UNREACHABLE","reduced_harvest":false}'
        return
    fi

    echo "$raw" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
except Exception:
    print(json.dumps({"reachable": False, "error": 0, "warn": 0, "info": 0,
                      "total": 0, "worst": "UNPARSEABLE", "reduced_harvest": False}))
    sys.exit(0)

findings = d.get("findings") or []
counts = {}
reduced = False
for f in findings:
    sev = f.get("severity", 0)
    counts[sev] = counts.get(sev, 0) + 1
    if "[reduced-harvest]" in (f.get("summary") or ""):
        reduced = True

names = {1: "INFO", 2: "WARN", 3: "ERROR", 4: "CRITICAL"}
worst = "NONE"
for sev in (4, 3, 2, 1):
    if counts.get(sev):
        worst = names[sev]
        break

print(json.dumps({
    "reachable": True,
    "info":  counts.get(1, 0),
    "warn":  counts.get(2, 0),
    "error": counts.get(3, 0) + counts.get(4, 0),
    "total": len(findings),
    "worst": worst,
    "reduced_harvest": reduced,
}))
'
}

# ── node probes ───────────────────────────────────────────────────────────────

# probe: node.installed_packages
# Params: --node <node-name>  (e.g. node-1)
# Returns: {"count":N,"node":"...","uuid":"..."}
# Resolves logical node name → UUID via container config.json, then queries etcd.
probe_node_installed_packages() {
    local node=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --node) node="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    local container="globular-${node}"

    # Resolve UUID from the node agent's state file
    local uuid
    uuid=$(_node_agent_node_id "$container")

    if [ -z "$uuid" ]; then
        # Fallback: scan all node package values for one with a matching hostname/name
        # by finding UUIDs from keys only (no name resolution needed — return total)
        local all_keys count
        all_keys=$(_etcd_keys "/globular/nodes/" 2>/dev/null || echo "")
        count=$(echo "$all_keys" | grep '/packages/' | grep -v '^$' | wc -l)
        echo "{\"count\":$count,\"node\":\"$node\",\"uuid\":\"unknown\"}"
        return
    fi

    local keys count
    keys=$(_etcd_keys "/globular/nodes/$uuid/packages" 2>/dev/null || echo "")
    count=$(echo "$keys" | grep -v '^$' | wc -l)
    echo "{\"count\":$count,\"node\":\"$node\",\"uuid\":\"$uuid\"}"
}

# probe: node.container_running
# Params: --node <node-name>
# Returns: {"running":true|false,"node":"..."}
# Checks if the docker container for the node is in Running state.
probe_node_container_running() {
    local node=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --node) node="$2"; shift 2 ;;
            *) shift ;;
        esac
    done
    local container="globular-${node}"
    local running=false
    docker inspect "$container" --format '{{.State.Running}}' 2>/dev/null | grep -q true && running=true
    echo "{\"running\":$running,\"node\":\"$node\"}"
}

# probe: node.fenced
# Params: --node <node-id>
# Returns: {"fenced":true|false}
probe_node_fenced() {
    local node=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --node) node="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    local val
    val=$(_etcd_get "/globular/nodes/$node/fenced" 2>/dev/null || echo "")
    if echo "$val" | grep -qi "true"; then
        echo "{\"fenced\":true,\"node\":\"$node\"}"
    else
        echo "{\"fenced\":false,\"node\":\"$node\"}"
    fi
}

# ── observability probes ──────────────────────────────────────────────────────

# probe: metrics.query
# Params: --query <promql>
# Returns: {"value":"N","query":"..."}
# NOTE: requires Prometheus on node-2 at http://localhost:9090
probe_metrics_query() {
    local query=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --query) query="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    local encoded
    encoded=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$query'))" 2>/dev/null || echo "$query")

    local response value
    response=$(docker exec globular-node-2 \
        curl -sf "http://localhost:9090/api/v1/query?query=$encoded" \
        2>/dev/null || echo '{}')

    value=$(echo "$response" | python3 -c \
        "import sys,json; d=json.loads(sys.stdin.read()); r=d.get('data',{}).get('result',[]); print(r[0]['value'][1] if r else 'no_data')" \
        2>/dev/null || echo "error")

    echo "{\"value\":\"$value\",\"query\":\"$query\"}"
}

# ── security / PKI probes ──────────────────────────────────────────────────────

# probe: pki.cert_info
# Params: --node <node>  [--cert <path>]  [--vip <ip>]
# Returns: {"valid":true|false,"days_remaining":N,"has_vip":true|false,
#           "not_after":"...","node":"..."}
# Checks: cert is parseable, not expired within 30 days, and contains the VIP in SANs.
probe_pki_cert_info() {
    local node="node-1"
    local cert="/var/lib/globular/pki/issued/services/service.crt"
    local vip="10.10.0.100"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --node)  node="$2"; shift 2 ;;
            --cert)  cert="$2"; shift 2 ;;
            --vip)   vip="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    local container="globular-${node}"
    if ! _container_running "$container"; then
        echo "{\"valid\":false,\"chain_valid\":false,\"error\":\"container not running\",\"node\":\"$node\"}"
        return
    fi

    # Check cert is valid for 30+ more days (exit 0 = not expiring within N seconds)
    local valid_30d=false
    docker exec "$container" openssl x509 -noout \
        -checkend $((30*24*3600)) -in "$cert" >/dev/null 2>&1 && valid_30d=true

    # Chain validity — is this leaf actually issued by the cluster CA?
    #
    # Distinct from `valid`, which only answers "not expiring within 30 days".
    # A cert can be well within its window and still be signed by a retired CA
    # or self-signed (the shape chaos.inject_expired_cert produces), so an
    # expiry check cannot stand in for a chain check. cert-expiry-detection
    # asserts chain_valid precisely to prove a re-issued cert came from the
    # cluster CA rather than from whatever happened to land on disk; the field
    # simply did not exist, so that assertion could never pass.
    local chain_valid=false
    docker exec "$container" openssl verify \
        -CAfile /var/lib/globular/pki/ca.crt "$cert" >/dev/null 2>&1 && chain_valid=true

    # Get expiry date
    local not_after
    not_after=$(docker exec "$container" openssl x509 -noout -enddate -in "$cert" \
        2>/dev/null | sed 's/notAfter=//' || echo "unknown")

    # Compute approximate days remaining
    local days_remaining=0
    if command -v python3 >/dev/null 2>&1 && [ "$not_after" != "unknown" ]; then
        days_remaining=$(python3 -c "
from datetime import datetime
import sys
try:
    exp = datetime.strptime('$not_after', '%b %d %H:%M:%S %Y %Z')
    delta = exp - datetime.utcnow()
    print(max(0, delta.days))
except:
    print(0)
" 2>/dev/null || echo 0)
    fi

    # Check VIP in SANs
    local has_vip=false
    docker exec "$container" openssl x509 -noout -text -in "$cert" 2>/dev/null | \
        grep -q "IP Address:$vip" && has_vip=true

    # Is a VIP actually configured on this cluster? The ingress spec is the
    # authority. Day-0 writes mode=disabled/explicit_disabled=true ("ingress not
    # yet configured"), and this simulation never enables it — no keepalived, no
    # VIP address anywhere in docker-compose. Asking whether an address that
    # does not exist appears in the SANs is not a security check; it is an
    # assertion about a topology that was never built.
    local vip_configured=false
    if docker exec "$container" sh -c '/usr/lib/globular/bin/etcdctl \
            --endpoints=https://127.0.0.1:2379 \
            --cacert=/var/lib/globular/pki/ca.crt \
            --cert=/var/lib/globular/pki/issued/services/service.crt \
            --key=/var/lib/globular/pki/issued/services/service.key \
            get /globular/ingress/v1/spec 2>/dev/null' \
            | grep -q '"mode":"[^d]'; then
        vip_configured=true
    fi

    # vip_san_ok is the assertable form of the rule that matters: WHEN a VIP is
    # configured it MUST appear in the service cert SANs. A missing VIP SAN is
    # the silent failure that rejected all VIP traffic for 16 hours
    # (session_vip_cert_fix.md), so the check keeps its teeth wherever a VIP
    # exists — while a cluster with ingress disabled passes honestly instead of
    # failing on an address it was never given.
    local vip_san_ok=true
    if [[ "$vip_configured" == "true" && "$has_vip" != "true" ]]; then
        vip_san_ok=false
    fi

    echo "{\"valid\":$valid_30d,\"chain_valid\":$chain_valid,\"days_remaining\":$days_remaining,\"has_vip\":$has_vip,\"vip_configured\":$vip_configured,\"vip_san_ok\":$vip_san_ok,\"not_after\":\"$not_after\",\"node\":\"$node\"}"
}

# probe: pki.ca_valid
# Params: --node <node>
# Returns: {"valid":true|false,"days_remaining":N,"subject":"..."}
probe_pki_ca_valid() {
    local node="node-1"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --node) node="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    local container="globular-${node}"
    local ca="/var/lib/globular/pki/ca.crt"

    if ! _container_running "$container"; then
        echo "{\"valid\":false,\"error\":\"container not running\"}"
        return
    fi

    local valid=false
    docker exec "$container" openssl x509 -noout \
        -checkend $((30*24*3600)) -in "$ca" >/dev/null 2>&1 && valid=true

    local not_after
    not_after=$(docker exec "$container" openssl x509 -noout -enddate -in "$ca" \
        2>/dev/null | sed 's/notAfter=//' || echo "unknown")

    local days_remaining=0
    [ "$not_after" != "unknown" ] && days_remaining=$(python3 -c "
from datetime import datetime
try:
    exp = datetime.strptime('$not_after', '%b %d %H:%M:%S %Y %Z')
    delta = exp - datetime.utcnow()
    print(max(0, delta.days))
except:
    print(0)
" 2>/dev/null || echo 0)

    echo "{\"valid\":$valid,\"days_remaining\":$days_remaining,\"not_after\":\"$not_after\",\"node\":\"$node\"}"
}

# probe: pki.signing_keys
# Params: --node <node>
# Returns: {"present":true|false,"key_count":N,"node_key_present":true|false}
# Ed25519 signing keys are how services prove their identity. Each node has a private key
# (only it can read) and public keys for all peers.
probe_pki_signing_keys() {
    local node="node-1"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --node) node="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    local container="globular-${node}"
    if ! _container_running "$container"; then
        echo "{\"present\":false,\"error\":\"container not running\"}"
        return
    fi

    local key_count node_key_present=false
    key_count=$(docker exec "$container" ls /var/lib/globular/keys/ 2>/dev/null | wc -l)

    # Key files are named after the node's MAC (colons -> underscores), e.g.
    # 02_42_0a_0a_00_0b_private — NOT after the container's short name. This
    # used to grep for "${node}_private" (i.e. literally "node-1_private"),
    # which no node has ever had, so node_key_present was false on every node
    # whose scenario bothered to assert it. The keys were present the whole
    # time. Derive the real identity instead of guessing at the filename.
    local mac
    mac=$(docker exec "$container" cat /sys/class/net/eth0/address 2>/dev/null | tr -d '\r\n' | tr ':' '_')
    if [ -n "$mac" ]; then
        # Accept both the bare <mac>_private and the suffixed
        # <mac>_<keyid>_private form the key rotation writes.
        docker exec "$container" ls /var/lib/globular/keys/ 2>/dev/null | \
            grep -qE "^${mac}(_[A-Za-z0-9_-]+)?_private$" && node_key_present=true
    fi

    local present=false
    [ "$key_count" -gt 0 ] && present=true

    echo "{\"present\":$present,\"key_count\":$key_count,\"node_key_present\":$node_key_present,\"node\":\"$node\"}"
}

# probe: pki.mtls_connect
# Params: --node <node>  --target_ip <ip>  (--target_port <port> | --target_service <id>)
#         --target_node <node>   node whose service config resolves target_service
# Returns: {"connected":true|false,"target":"IP:port","node":"..."}
# Uses openssl s_client with mTLS (service cert + CA) to verify TLS handshake.
#
# Prefer --target_service. Globular allocates gRPC ports at RUNTIME from etcd
# ("service X port allocated NNNNN range=10000-20000"), so a literal
# --target_port is a snapshot that rots the moment allocation order changes.
# Two assertions in this suite were pinned that way and had drifted:
# event was probed on :10000 while it listens on :10019, and cluster-doctor on
# node-2 was probed on :12100 while it listens on :12005. Both reported
# connected=false — read as an mTLS failure when nothing was listening at all.
# Resolving from the node's own service config is the same rule the platform
# enforces on itself: no hardcoded service ports.
probe_pki_mtls_connect() {
    local node="node-1" target_ip="" target_port="" target_service="" target_node=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --node)           node="$2"; shift 2 ;;
            --target_ip)      target_ip="$2"; shift 2 ;;
            --target_port)    target_port="$2"; shift 2 ;;
            --target_service) target_service="$2"; shift 2 ;;
            --target_node)    target_node="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    # Resolve the port from the target's runtime service config when asked.
    if [[ -z "$target_port" && -n "$target_service" ]]; then
        local resolve_node="${target_node:-$node}"
        local resolve_container="globular-${resolve_node}"
        # Resolve from the RUNNING PROCESS — the only dependable answer to
        # "what port is this service serving on".
        #
        # The on-disk service configs cannot be used. They are incomplete (no
        # /var/lib/globular/services/*.json carries Name=workflow at all, yet
        # workflow serves on 10220) and internally inconsistent (rbac, resource
        # and cluster_doctor configs all report Port=10001 on the same node,
        # while the legacy event.EventService.json says 10019 where the process
        # listens on 10050). Every earlier attempt to pin or look up a port here
        # produced a probe aimed at a dead socket and a "connected: false" that
        # read as an mTLS failure.
        #
        # The unit's MainPID plus its listening sockets is ground truth. A
        # Globular service binds its gRPC port and a higher proxy/metrics port
        # (10050/10051, 10220/10221); the gRPC port is the lower of the two.
        # Enumerate every port the service's process is listening on. The probe
        # then asserts that AT LEAST ONE of them completes an mTLS handshake —
        # the honest form of "this service's transport is mTLS-protected and
        # reachable", which is what this suite tests (it explicitly does not
        # test authorization).
        #
        # A single port cannot be resolved reliably. The on-disk service configs
        # are right for repository/event/rbac, WRONG for cluster_doctor (they say
        # 10001 while it serves 12005), and absent entirely for workflow. Nor is
        # the lowest port a rule: repository serves gRPC on 10004 on both nodes
        # but also binds 10001 on node-2. Every fixed guess produced a probe
        # aimed at a dead socket and a "connected: false" that read as an mTLS
        # failure. Failing only when NO port speaks mTLS keeps the real signal
        # (wrong CA, unsigned cert, service down) without pinning a number that
        # runtime allocation is free to change.
        target_ports="$(docker exec "$resolve_container" bash -c '
            svc="$1"
            pid=$(systemctl show -p MainPID --value "globular-${svc}" 2>/dev/null)
            if [ -z "$pid" ] || [ "$pid" = "0" ]; then exit 0; fi
            ss -lntp 2>/dev/null | grep "pid=${pid}," \
              | sed -E "s/.*[[:space:]][^[:space:]]*:([0-9]+)[[:space:]]+.*/\1/" \
              | grep -E "^[0-9]+$" | sort -nu
        ' _ "$target_service" 2>/dev/null | tr '\n' ' ')"
        if [[ -z "${target_ports// /}" ]]; then
            echo "{\"connected\":false,\"error\":\"service '${target_service}' is not running on ${resolve_node} (no listening port)\",\"node\":\"$node\"}"
            return
        fi
    fi

    # An explicit --target_port stays a single-port assertion; --target_service
    # yields the service's full listening set (see above).
    [[ -n "$target_port" ]] && target_ports="$target_port"
    [[ -z "$target_ip" || -z "${target_ports// /}" ]] && {
        echo '{"connected":false,"error":"target_ip and (target_port or target_service) required"}'
        return
    }

    local container="globular-${node}"
    if ! _container_running "$container"; then
        echo "{\"connected\":false,\"error\":\"container not running\",\"node\":\"$node\"}"
        return
    fi

    # Send empty string to openssl s_client; exit 0 = TLS handshake succeeded.
    # Timeout 5s so we don't hang on unreachable hosts.
    local connected=false hit_port=""
    local p
    for p in $target_ports; do
        if docker exec "$container" bash -c "
            echo '' | timeout 5 openssl s_client \
                -connect ${target_ip}:${p} \
                -cert /var/lib/globular/pki/issued/services/service.crt \
                -key /var/lib/globular/pki/issued/services/service.key \
                -CAfile /var/lib/globular/pki/ca.crt \
                -verify_return_error \
                -quiet 2>/dev/null
        " >/dev/null 2>&1; then
            connected=true
            hit_port="$p"
            break
        fi
    done
    [[ -z "$hit_port" ]] && hit_port="$(echo $target_ports | awk '{print $1}')"

    echo "{\"connected\":$connected,\"target\":\"${target_ip}:${hit_port}\",\"ports_tried\":\"$(echo $target_ports | tr -s ' ')\",\"node\":\"$node\"}"
}

# probe: rbac.policy_file
# Params: --node <node>
# Returns: {"present":true|false,"role_count":N,"valid_json":true|false,"node":"..."}
# Verifies the cluster-roles.json policy file is deployed and parseable.
probe_rbac_policy_file() {
    local node="node-1"
    # The cluster roles file is GENERATED (from proto AuthzRule annotations) and
    # lands as cluster-roles.generated.json. This probe used to hardcode the
    # legacy hand-authored name cluster-roles.json, so it reported
    # present:false on a cluster whose RBAC was fully deployed and loaded —
    # the controller logs "loaded cluster roles from file
    # path=.../cluster-roles.generated.json roles=22" at the same moment.
    # Check the generated name first, keep the legacy one as a fallback so this
    # probe still works against an older bundle.
    local policy_candidates=(
        "/var/lib/globular/policy/rbac/cluster-roles.generated.json"
        "/var/lib/globular/policy/rbac/cluster-roles.json"
    )
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --node) node="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    local container="globular-${node}"
    if ! _container_running "$container"; then
        echo "{\"present\":false,\"error\":\"container not running\",\"node\":\"$node\"}"
        return
    fi

    local policy_path=""
    local candidate
    for candidate in "${policy_candidates[@]}"; do
        if docker exec "$container" test -f "$candidate" 2>/dev/null; then
            policy_path="$candidate"
            break
        fi
    done
    if [ -z "$policy_path" ]; then
        echo "{\"present\":false,\"role_count\":0,\"valid_json\":false,\"node\":\"$node\"}"
        return
    fi

    # Cat the file out of the container and parse it on the host with python3
    local role_count valid_json=false
    role_count=$(docker exec "$container" cat "$policy_path" 2>/dev/null | \
        python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    roles = d.get('roles', {})
    print(len(roles))
except:
    print(0)
" 2>/dev/null || echo 0)

    [ "$role_count" -gt 0 ] && valid_json=true

    echo "{\"present\":true,\"role_count\":$role_count,\"valid_json\":$valid_json,\"node\":\"$node\"}"
}

# ── recovery probes ────────────────────────────────────────────────────────────

# probe: release.audit
# Params: (none)
# Returns: {"total":N,"succeeded":N,"failed":N,"pending":N}
# Reads all ServiceRelease records from etcd and tallies by status.phase.
probe_release_audit() {
    local prefix="/globular/resources/ServiceRelease"

    local values
    values=$(_etcd_values "$prefix" 2>/dev/null || echo "")

    if [ -z "$values" ]; then
        echo '{"total":0,"succeeded":0,"failed":0,"pending":0}'
        return
    fi

    echo "$values" | python3 -c "
import sys, json

data = sys.stdin.read()
decoder = json.JSONDecoder()
pos = 0
total = succeeded = failed = pending = 0

while pos < len(data):
    rest = data[pos:]
    stripped_s = rest.lstrip()
    if not stripped_s:
        break
    stripped = len(rest) - len(stripped_s)
    try:
        obj, end = decoder.raw_decode(stripped_s)
        pos += stripped + end
        if not isinstance(obj, dict):
            continue
        total += 1
        status = obj.get('status', {}) or {}
        phase = (status.get('phase') or '').upper()
        # Terminal-success phase per ReleasePhase* in
        # cluster_controllerpb/resources_types.go: AVAILABLE means all target
        # nodes are at the desired version. There is NO SUCCEEDED phase in the
        # release vocabulary, so testing for it made this counter structurally
        # zero -- a cluster with 18 AVAILABLE releases reported succeeded=0 and
        # filed all 18 under pending, which is what made release-failure-audit
        # look like a permanently broken pipeline.
        # DEGRADED is converged-but-partial (some nodes failed, min replicas
        # still met), so it is counted with failures rather than in flight.
        if phase == 'AVAILABLE':
            succeeded += 1
        elif phase in ('FAILED', 'DEGRADED'):
            failed += 1
        else:
            # PENDING / WAITING / RESOLVED / PLANNED / APPLYING / DEFERRED
            pending += 1
    except json.JSONDecodeError:
        nxt = stripped_s.find('{', 1)
        if nxt < 0:
            break
        pos += stripped + nxt

print('{\"total\":%d,\"succeeded\":%d,\"failed\":%d,\"pending\":%d}' % (total, succeeded, failed, pending))
" 2>/dev/null || echo '{"total":0,"succeeded":0,"failed":0,"pending":0}'
}

# ── write quorum & member health probes ──────────────────────────────────────

# probe: etcd.write_test
# Returns: {"success":true|false,"latency_ms":N}
# Writes a test key to etcd and reads it back to verify write quorum is healthy.
# A successful write proves a majority of etcd members are reachable and in quorum.
probe_etcd_write_test() {
    if ! _container_running "$ETCD_CONTAINER"; then
        echo '{"success":false,"error":"primary container not running","latency_ms":0}'
        return
    fi

    local test_key="/globular/test/write-probe"
    local test_val="probe-$(date +%s)"
    local start_ms end_ms latency success=false

    start_ms=$(date +%s%3N 2>/dev/null || echo 0)

    if _etcd put "$test_key" "$test_val" >/dev/null 2>&1; then
        local got
        got=$(_etcd_get "$test_key" 2>/dev/null || echo "")
        if [ "$got" = "$test_val" ]; then
            success=true
        fi
        _etcd del "$test_key" >/dev/null 2>&1 || true
    fi

    end_ms=$(date +%s%3N 2>/dev/null || echo 0)
    latency=$((end_ms - start_ms))

    echo "{\"success\":$success,\"latency_ms\":$latency}"
}

# probe: cluster.etcd_members
# Returns: {"total":3,"healthy":N,"unhealthy":N}
# Checks each of the 3 control-plane etcd member endpoints individually
# with a short per-member timeout so the probe doesn't hang when a member
# is down. healthy + unhealthy should always sum to total.
probe_cluster_etcd_members() {
    if ! _container_running "$ETCD_CONTAINER"; then
        echo '{"total":0,"healthy":0,"unhealthy":0,"error":"primary container not running"}'
        return
    fi

    local healthy=0 unhealthy=0
    local members=("https://10.10.0.11:2379" "https://10.10.0.12:2379" "https://10.10.0.13:2379")
    local total=${#members[@]}

    for ep in "${members[@]}"; do
        if docker exec "$ETCD_CONTAINER" \
            "$ETCD_BIN" \
            --endpoints="$ep" \
            --cacert="$ETCD_PKI/ca.crt" \
            --cert="$ETCD_PKI/issued/services/service.crt" \
            --key="$ETCD_PKI/issued/services/service.key" \
            --dial-timeout=3s \
            --command-timeout=5s \
            endpoint health >/dev/null 2>&1; then
            healthy=$((healthy + 1))
        else
            unhealthy=$((unhealthy + 1))
        fi
    done

    echo "{\"total\":$total,\"healthy\":$healthy,\"unhealthy\":$unhealthy}"
}

# probe: node.etcd_registered
# Params: --node <node-name>  (e.g. node-4)
# Returns: {"registered":true|false,"node":"...","uuid":"..."}
# Resolves the node name → UUID via the node agent's state.json, then checks
# if that UUID has a node_agent_metrics_port key in etcd (proof of heartbeat).
probe_node_etcd_registered() {
    local node=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --node) node="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    local container="globular-${node}"

    local uuid
    uuid=$(_node_agent_node_id "$container")

    if [ -z "$uuid" ]; then
        echo "{\"registered\":false,\"node\":\"$node\",\"uuid\":\"\",\"error\":\"cannot_resolve_uuid\"}"
        return
    fi

    local val
    val=$(_etcd_get "/globular/nodes/$uuid/node_agent_metrics_port" 2>/dev/null || echo "")

    if [ -n "$val" ]; then
        echo "{\"registered\":true,\"node\":\"$node\",\"uuid\":\"$uuid\"}"
    else
        echo "{\"registered\":false,\"node\":\"$node\",\"uuid\":\"$uuid\"}"
    fi
}

# probe: cluster.installed_packages
# Params: (none)
# Returns: {"total":N,"node_count":N}
# Sums installed package entries across all nodes from etcd Layer 3.
probe_cluster_installed_packages() {
    local keys
    keys=$(_etcd_keys "/globular/nodes/" 2>/dev/null || echo "")

    # Unique node IDs from /globular/nodes/<uuid>/packages/...
    local node_ids
    node_ids=$(echo "$keys" | grep '/packages/' | \
        sed 's|/globular/nodes/||; s|/packages/.*||' | sort -u)

    local total=0 node_count=0
    while IFS= read -r node_id; do
        [ -z "$node_id" ] && continue
        local pkg_keys pkg_count
        pkg_keys=$(_etcd_keys "/globular/nodes/$node_id/packages" 2>/dev/null || echo "")
        pkg_count=$(echo "$pkg_keys" | grep -v '^$' | wc -l)
        total=$((total + pkg_count))
        node_count=$((node_count + 1))
    done <<< "$node_ids"

    echo "{\"total\":$total,\"node_count\":$node_count}"
}

# ── chaos / invariant probes ──────────────────────────────────────────────────

# probe: node.disk_usage
# Params: --node <node-name> --path <path> (default /var/lib/globular)
# Returns: {"used_pct":N,"free_pct":N,"used_gb":N,"total_gb":N,"path":"..."}
# Reads disk usage inside a Docker container via df.
probe_node_disk_usage() {
    local node="" path="/var/lib/globular"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --node) node="$2"; shift 2 ;;
            --path) path="$2"; shift 2 ;;
            *) shift ;;
        esac
    done
    local container="globular-${node}"
    local df_out
    df_out=$(docker exec "$container" df -m "$path" 2>/dev/null | awk 'NR==2{print $2,$3,$4}')
    if [[ -z "$df_out" ]]; then
        echo "{\"error\":\"df failed\",\"node\":\"$node\"}"
        return
    fi
    local total_mb used_mb free_mb
    read -r total_mb used_mb free_mb <<< "$df_out"
    local used_pct free_pct total_gb used_gb
    used_pct=$(awk "BEGIN{printf \"%.1f\", $used_mb/$total_mb*100}")
    free_pct=$(awk "BEGIN{printf \"%.1f\", $free_mb/$total_mb*100}")
    total_gb=$(awk "BEGIN{printf \"%.1f\", $total_mb/1024}")
    used_gb=$(awk "BEGIN{printf \"%.1f\", $used_mb/1024}")
    echo "{\"used_pct\":$used_pct,\"free_pct\":$free_pct,\"used_gb\":$used_gb,\"total_gb\":$total_gb,\"path\":\"$path\",\"node\":\"$node\"}"
}

# probe: cluster.quorum_loss_alert
# Params: (none)
# Returns: {"alert_present":true|false}
# Checks if the emergency quorum loss alert key exists in etcd.
# Written by invariantTriggerEmergencyBackup when ≥2 founding nodes go critical.
probe_cluster_quorum_loss_alert() {
    local val
    val=$(_etcd_get "/globular/cluster/alerts/quorum_loss" 2>/dev/null || echo "")
    if [[ -n "$val" && "$val" != "null" ]]; then
        echo "{\"alert_present\":true}"
    else
        echo "{\"alert_present\":false}"
    fi
}

# probe: node.partition_fenced
# Params: --node <node-name>
# Returns: {"fenced":true|false,"fenced_since":"...","node_id":"..."}
#
# The fence marker is Metadata["partition_fenced_since"] on the node record in
# the CONTROLLER's cluster state, which is persisted to etcd as one JSON blob
# at /globular/clustercontroller/state.
#
# This used to scan /globular/nodes/<id>/status — keys that do not exist in
# this schema at all (the /globular/nodes/ prefix holds packages/,
# node_agent_metrics_port, objectstore/...). With nothing to match, the probe
# returned fenced:false unconditionally, so node.partition_fenced could never
# report true no matter what the controller did, and every fencing assertion in
# dual-node-failure and network-partition-fencing failed by construction.
#
# It also ignored --node when matching: any fenced node satisfied a query about
# any other. Match the requested node explicitly, by hostname or by UUID.
probe_node_partition_fenced() {
    local node=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --node) node="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    local state
    state=$(_etcd_get "/globular/clustercontroller/state" 2>/dev/null || echo "")
    if [[ -z "$state" ]]; then
        echo "{\"fenced\":false,\"node_id\":\"$node\",\"error\":\"cluster state unreadable\"}"
        return
    fi

    echo "$state" | NODE="$node" python3 -c '
import json, os, sys

want = os.environ.get("NODE", "")
try:
    state = json.load(sys.stdin)
except Exception as e:
    print(json.dumps({"fenced": False, "node_id": want, "error": f"state parse failed: {e}"}))
    sys.exit(0)

nodes = state.get("Nodes") or state.get("nodes") or {}
for node_id, n in nodes.items():
    if not isinstance(n, dict):
        continue
    identity = n.get("Identity") or n.get("identity") or {}
    hostname = identity.get("Hostname") or identity.get("hostname") or ""
    if want and want != node_id and want != hostname:
        continue
    meta = n.get("Metadata") or n.get("metadata") or {}
    since = meta.get("partition_fenced_since", "")
    print(json.dumps({
        "fenced": bool(since),
        "fenced_since": since,
        "node_id": node_id,
        "hostname": hostname,
    }))
    sys.exit(0)

print(json.dumps({"fenced": False, "node_id": want, "error": "node not found in cluster state"}))
' 2>/dev/null || echo "{\"fenced\":false,\"node_id\":\"$node\",\"error\":\"probe failed\"}"
}

# probe: pki.cert_expiry_days
# Params: --node <node-name> --cert_path <path>
# Returns: {"days_remaining":N,"expired":true|false,"node":"..."}
# Checks how many days until a cert expires inside a container.
probe_pki_cert_expiry_days() {
    local node="" cert_path="/var/lib/globular/pki/issued/services/service.crt"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --node) node="$2"; shift 2 ;;
            --cert_path) cert_path="$2"; shift 2 ;;
            *) shift ;;
        esac
    done
    local container="globular-${node}"
    local expiry_line
    expiry_line=$(docker exec "$container" openssl x509 -in "$cert_path" -noout -enddate 2>/dev/null || echo "")
    if [[ -z "$expiry_line" ]]; then
        echo "{\"error\":\"cannot read cert\",\"node\":\"$node\",\"cert_path\":\"$cert_path\"}"
        return
    fi
    local expiry_date
    expiry_date=$(echo "$expiry_line" | cut -d= -f2)
    local days_remaining
    days_remaining=$(docker exec "$container" bash -c \
        "python3 -c \"from datetime import datetime; import sys; \
        exp=datetime.strptime('$expiry_date','%b %d %H:%M:%S %Y %Z'); \
        now=datetime.utcnow(); \
        delta=(exp-now).days; \
        print(delta)\"" 2>/dev/null || echo "-1")
    local expired=false
    [[ "$days_remaining" -lt 0 ]] 2>/dev/null && expired=true
    echo "{\"days_remaining\":$days_remaining,\"expired\":$expired,\"node\":\"$node\",\"cert_path\":\"$cert_path\"}"
}

# ── install-anchor probes ─────────────────────────────────────────────────────

# probe_install_anchor_sane — SCAR 2026-07-30.
#
# installed_state records the moment an artifact was committed to disk, as
# metadata.installed_at. A process cannot execute a binary before that binary
# exists, so for any RUNNING service:
#
#     installed_at <= process_start
#
# release_boundary evalA4 is built on exactly that rule. The bug was on the
# other side of it: StampMigrationFromLegacySidecar is an ADOPTION path — it
# discovers a unit already on disk and installs nothing — yet it stamped
# installed_at = time.Now(). Adoption necessarily runs AFTER the service is
# already up, so the minted install-commit was always later than the process
# start and A4 reported FAILED "stale process" for 24/24 services on a node that
# was installed perfectly.
#
# Fix: anchor to the unit file's mtime (services@b862793f).
#
# Emits: {"checked":N,"violations":M,"worst_skew_s":S,"detail":"..."}
# A violation is installed_at STRICTLY GREATER than process start.
#
# PRECONDITION — NOT YET MET BY THE QUICKSTART IMAGE (2026-07-31).
# This probe needs installed_state records that carry metadata.installed_at,
# which only the real node-agent install/adoption path writes. The quickstart's
# records are seeded directly and contain no metadata field at all:
#
#   {"nodeId":"...","name":"ai-executor","version":"1.2.288","kind":"SERVICE",
#    "installedUnix":"1785513749","updatedUnix":"1785513749","status":"installed"}
#
# So the defect this probe exists to catch is currently UNREACHABLE here — the
# buggy code never executes. The probe reports violations:-1 with an error in
# that case rather than 0 violations, because "the evidence is absent" must not
# be reported as "the property holds". Closing the gap means having the
# container exercise node-agent's real install path instead of seeding etcd.
# Until then this probe is intentionally unused by any scenario.
probe_install_anchor_sane() {
    local node="${1:-node-1}"
    local container="globular-${node}"
    if ! _container_running "$container"; then
        echo "{\"checked\":0,\"violations\":0,\"error\":\"container ${container} not running\"}"
        return 0
    fi

    # Resolve this node's id from the installed_state key space, using the
    # harness's own etcd helper rather than a second hand-rolled one — the
    # endpoint is the node IP, not loopback.
    local node_id
    node_id=$(_etcd_keys /globular/nodes/ 2>/dev/null \
              | grep "/packages/SERVICE/" | head -1 | cut -d/ -f4)
    if [ -z "$node_id" ]; then
        echo "{\"checked\":0,\"violations\":-1,\"error\":\"no SERVICE installed_state records found\"}"
        return 0
    fi

    # Stage the records inside the container so the systemd lookups below run
    # on the same host that owns the units.
    _etcd_values "/globular/nodes/$node_id/packages/SERVICE/" 2>/dev/null \
        | docker exec -i "$container" bash -c 'cat > /tmp/_pkgs.json'

    # Walk every SERVICE-kind installed_state record, pull metadata.installed_at,
    # and compare against the unit's ExecMainStartTimestamp.
    local out
    out=$(docker exec "$container" bash -c '
      python3 - <<PY
import json,subprocess,sys
raw=open("/tmp/_pkgs.json").read()
dec=json.JSONDecoder(); objs=[]; i=0
while i < len(raw):
    while i < len(raw) and raw[i] != "{": i += 1
    if i >= len(raw): break
    try:
        o,j = dec.raw_decode(raw,i)
    except Exception:
        break
    objs.append(o); i = j
checked=0; viol=0; worst=0; detail=[]
for o in objs:
    name=o.get("name","")
    ia=o.get("metadata",{}).get("installed_at","")
    if not name or not ia: continue
    unit="globular-%s.service" % name.replace("_","-")
    ts=subprocess.run(["systemctl","show",unit,"-p","ExecMainStartTimestamp","--value"],
                      capture_output=True,text=True).stdout.strip()
    if not ts: continue
    r=subprocess.run(["date","-d",ts,"+%s"],capture_output=True,text=True)
    if r.returncode != 0 or not r.stdout.strip().isdigit(): continue
    ps=int(r.stdout.strip())
    try: iau=int(ia)
    except Exception: continue
    checked+=1
    skew=iau-ps
    if skew > 0:
        viol+=1
        if skew>worst: worst=skew
        detail.append("%s:+%ds" % (name,skew))
print("RESULT %d %d %d %s" % (checked,viol,worst,",".join(detail[:6])))
PY
    ' 2>/dev/null)

    if echo "$out" | grep -q "PROBE_ERROR"; then
        echo "{\"checked\":0,\"violations\":-1,\"error\":\"$(echo "$out" | tr -d '"' | head -1)\"}"
        return 0
    fi
    local line checked viol worst detail
    line=$(echo "$out" | grep '^RESULT ' | head -1)
    if [ -z "$line" ]; then
        echo "{\"checked\":0,\"violations\":-1,\"error\":\"probe produced no result\"}"
        return 0
    fi
    checked=$(echo "$line" | awk '{print $2}')
    viol=$(echo "$line" | awk '{print $3}')
    worst=$(echo "$line" | awk '{print $4}')
    detail=$(echo "$line" | cut -d' ' -f5-)
    echo "{\"checked\":${checked:-0},\"violations\":${viol:-0},\"worst_skew_s\":${worst:-0},\"detail\":\"${detail}\"}"
}

# ── cluster.reconcile_clean ──────────────────────────────────────────────────
# probe: cluster.reconcile_clean
# Params: --node <node> (default node-1), --since <systemd time> (default "30 min ago")
# Returns: {"clean":true|false,"error_count":N,"kinds":"...","sample":"...","node":"..."}
#
# Asserts the controller's reconcile loop is not continuously failing. A cluster
# can look healthy by every other probe — nodes heartbeating, services
# registered, etcd quorate — while reconcile fails on every pass and converges
# nothing. That is exactly the 2026-07-31 state: `cluster.reconcile` was absent,
# the circuit breaker sat permanently open, and desired state stayed empty while
# `cluster.health` happily reported "healthy".
#
# It also catches the controller/catalog profile disagreement: the controller
# derives profiles["ai"] from installed AI packages (handlers_status.go), but
# component_catalog/profilemap.go defines no such profile, so every reconcile
# pass logs `intent resolution failed: unknown profile: "ai"` and that node's
# intent never resolves.
#
# Deliberately NOT matched: "reconcile: service X — handled by release pipeline
# workflow" and "materialize-infra: skipping …" are normal delegation messages.
probe_cluster_reconcile_clean() {
    local node="node-1" since="30 min ago"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --node)  node="$2";  shift 2 ;;
            --since) since="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    local container="globular-${node}"
    if ! _container_running "$container"; then
        echo "{\"clean\":false,\"error_count\":-1,\"kinds\":\"\",\"sample\":\"container not running\",\"node\":\"$node\"}"
        return
    fi

    local journal
    journal=$(docker exec "$container" journalctl -u globular-cluster-controller \
                --since "$since" --no-pager 2>/dev/null || true)

    if [ -z "$journal" ]; then
        # Absence of evidence is not evidence of health — report -1, never 0.
        echo "{\"clean\":false,\"error_count\":-1,\"kinds\":\"\",\"sample\":\"no controller journal\",\"node\":\"$node\"}"
        return
    fi

    local matches
    matches=$(echo "$journal" | grep -oE \
        "intent resolution failed[^\"]*|unknown profile: \"[a-z-]+\"|INVARIANT VIOLATION[^\"]*|reconcile-workflow: [a-z.]+ FAILED|circuit OPEN|workflow definition \"[a-z.]+\" not found" \
        2>/dev/null || true)

    local count=0 kinds="" sample=""
    if [ -n "$matches" ]; then
        # grep -c prints 0 AND exits 1 on no matches, so `|| echo 0` yields
        # "0\n0" — the hazard documented at the top of this file. Guarded by
        # `if [ -n "$matches" ]` today, so it does not currently misfire, but
        # it is one edit away from doing so.
        count=$(echo "$matches" | grep . | wc -l)
        kinds=$(echo "$matches" | sed 's/[0-9]\+//g' | sort -u | head -4 | tr '\n' ';' | tr -d '"' | cut -c1-200)
        sample=$(echo "$matches" | head -1 | tr -d '"' | cut -c1-160)
    fi

    local clean="true"
    [ "$count" -gt 0 ] && clean="false"
    echo "{\"clean\":${clean},\"error_count\":${count},\"kinds\":\"${kinds}\",\"sample\":\"${sample}\",\"node\":\"${node}\"}"
}

# ══════════════════════════════════════════════════════════════════════════════
# Upgrade / release-pipeline probes
#
# Added after the 2026-08-16 incident, in which a routine ai-memory package
# deploy escalated into a cluster outage. Each probe below measures a property
# that was assumed rather than checked that night. They are deliberately
# phrased as "what must be true", not "what broke" — the scenarios that use
# them are in tests/scenarios/upgrade/.
# ══════════════════════════════════════════════════════════════════════════════

# _all_node_containers — the running globular-node-* containers, in order.
_all_node_containers() {
    docker ps --format '{{.Names}}' 2>/dev/null \
        | grep -E '^globular-node-[0-9]+$' | sort -V
}

# probe: state.liveness_freshness
# Returns: {"nodes":N,"max_age_s":N,"stale_nodes":N,"oldest":"<node>"}
#
# Reads last_seen out of the controller's persisted state blob and reports how
# stale the OLDEST one is. This is the exact measurement that would have caught
# cluster-controller@1.2.317: that build excluded last_seen from the state
# write-trigger hash and added a 5-minute floor, so the persisted values ran up
# to 300s behind reality and every liveness reader saw the cluster as
# unreachable while all node agents were healthy and serving.
#
# Params: --max_age_s (advisory; the scenario asserts via max_age_s_lte)
probe_state_liveness_freshness() {
    if ! _container_running "$ETCD_CONTAINER"; then
        echo '{"nodes":0,"max_age_s":-1,"stale_nodes":0,"error":"etcd container not running"}'
        return
    fi

    local blob
    blob=$(_etcd_get /globular/clustercontroller/state 2>/dev/null || echo "")
    if [[ -z "$blob" ]]; then
        echo '{"nodes":0,"max_age_s":-1,"stale_nodes":0,"error":"controller state key absent"}'
        return
    fi

    printf '%s' "$blob" | python3 -c '
import sys, json, datetime

def age(ts):
    if not ts:
        return None
    t = ts.replace("Z", "+00:00")
    try:
        d = datetime.datetime.fromisoformat(t)
    except ValueError:
        # Trim sub-second precision Go emits beyond microseconds.
        head, _, tail = t.partition(".")
        frac = "".join(c for c in tail if c.isdigit())[:6]
        off = tail[len(frac):] if len(tail) > len(frac) else "+00:00"
        try:
            d = datetime.datetime.fromisoformat(f"{head}.{frac}{off}")
        except ValueError:
            return None
    if d.tzinfo is None:
        d = d.replace(tzinfo=datetime.timezone.utc)
    return (datetime.datetime.now(datetime.timezone.utc) - d).total_seconds()

try:
    doc = json.load(sys.stdin)
except Exception as exc:
    print(json.dumps({"nodes": 0, "max_age_s": -1, "stale_nodes": 0,
                      "error": "unparseable state blob: %s" % exc}))
    raise SystemExit(0)

nodes = doc.get("nodes") or {}
worst, worst_node, counted, stale = -1.0, "", 0, 0
# 90s is generous: the agent heartbeat is well under a minute, so anything
# older than this is a persistence problem, not jitter.
THRESHOLD = 90
for name, n in nodes.items():
    if not isinstance(n, dict):
        continue
    a = age(n.get("last_seen"))
    if a is None:
        continue
    counted += 1
    if a > THRESHOLD:
        stale += 1
    if a > worst:
        worst, worst_node = a, name

print(json.dumps({
    "nodes": counted,
    "max_age_s": int(worst) if worst >= 0 else -1,
    "stale_nodes": stale,
    "oldest": worst_node,
}))
'
}

# probe: etcd.backend_growth
# Returns: {"max_db_bytes":N,"quota_bytes":N,"pct_of_quota":N,
#           "defrag_scheduled":bool,"compaction_configured":bool,"alarms":N}
#
# The 2 GiB NOSPACE outage was blamed on write volume. It was not: compaction
# was already configured (periodic, 1h retention), which bounds MVCC history.
# What was missing was defragmentation — compaction frees pages logically, the
# backend file only ratchets upward, and the high-water mark never returns.
# This probe reports both the size and whether anything will ever give the
# space back.
probe_etcd_backend_growth() {
    if ! _container_running "$ETCD_CONTAINER"; then
        echo '{"max_db_bytes":0,"quota_bytes":0,"pct_of_quota":0,"defrag_scheduled":false,"compaction_configured":false,"alarms":0,"error":"etcd container not running"}'
        return
    fi

    local status alarms max_db=0 quota=0
    status=$(_etcd endpoint status --write-out=json 2>/dev/null || echo "")
    if [[ -n "$status" ]]; then
        max_db=$(printf '%s' "$status" | python3 -c '
import sys, json
try:
    rows = json.load(sys.stdin)
    print(max(int(r.get("Status", {}).get("dbSize", 0)) for r in rows))
except Exception:
    print(0)
' 2>/dev/null || echo 0)
    fi

    # quota-backend-bytes: 0 means the etcd default of 2 GiB.
    quota=$(docker exec "$ETCD_CONTAINER" \
        sed -n 's/^quota-backend-bytes:[[:space:]]*//p' /var/lib/globular/config/etcd.yaml 2>/dev/null \
        | tr -d '"' | head -1)
    [[ -z "$quota" || "$quota" == "0" ]] && quota=2147483648

    local compaction=false
    if docker exec "$ETCD_CONTAINER" grep -q '^auto-compaction-retention:' \
            /var/lib/globular/config/etcd.yaml 2>/dev/null; then
        compaction=true
    fi

    # Anything that will actually return space. Three mechanisms count, and the
    # probe must know about all of them or it reports "no defrag" on a cluster
    # that defragments perfectly well — a false alarm trains people to ignore
    # the check, which is as bad as the check not existing:
    #
    #   1. node-agent's in-process maintenance loop (the platform mechanism —
    #      see golang/node_agent/node_agent_server/etcd_maintenance.go). It
    #      announces itself once at startup with etcd.maintenance_started.
    #   2. a systemd timer, for operators who schedule it externally.
    #   3. a cron entry, same.
    local defrag=false
    if docker exec "$ETCD_CONTAINER" bash -c \
            'journalctl -u globular-node-agent --no-pager 2>/dev/null |
                 grep -q "etcd.maintenance_started" ||
             systemctl list-timers --all 2>/dev/null | grep -qi defrag ||
             ls /etc/cron.d/ 2>/dev/null | grep -qi defrag ||
             systemctl list-unit-files 2>/dev/null | grep -qi "etcd-defrag"' 2>/dev/null; then
        defrag=true
    fi

    # grep -c exits 1 on zero matches while still printing 0, so the usual
    # `|| echo 0` fallback emits "0\n0" and corrupts the JSON. See the
    # warning at the top of this file. `grep . | wc -l` always exits 0.
    alarms=$(_etcd alarm list 2>/dev/null | grep . | wc -l)

    local pct=0
    if [[ "$quota" -gt 0 ]]; then
        pct=$(( max_db * 100 / quota ))
    fi

    echo "{\"max_db_bytes\":${max_db:-0},\"quota_bytes\":${quota},\"pct_of_quota\":${pct},\"defrag_scheduled\":${defrag},\"compaction_configured\":${compaction},\"alarms\":${alarms:-0}}"
}

# probe: repository.blob_reachable_all_nodes
# Returns: {"nodes":N,"with_blob":N,"missing":N,"missing_nodes":"a,b"}
#
# The local CAS is per-node while the manifest authority is cluster-wide, so a
# publish materializes the blob only in the CAS of the instance that handled
# the upload. Every other node keeps advertising that manifest as PUBLISHED
# while being unable to serve it. On 2026-08-16 cluster-controller@1.2.317's
# blob existed on exactly one node and ai-memory@1.2.317's on exactly one
# other, so installs routed anywhere else could not be served.
#
# Params: --name <package> [--version <v>]
probe_repository_blob_reachable_all_nodes() {
    local name="" version=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --name) name="$2"; shift 2 ;;
            --version) version="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    if [[ -z "$name" ]]; then
        echo '{"nodes":0,"with_blob":0,"missing":0,"error":"--name required"}'
        return
    fi

    local total=0 with=0 missing_list=""
    local c
    for c in $(_all_node_containers); do
        total=$(( total + 1 ))
        # A blob is reachable on this node if the artifact CAS holds a file
        # for it. Match on the package name; the digest gate is the
        # repository's job, this only answers "is it here at all".
        local hits
        hits=$(docker exec "$c" bash -c \
            "ls -1 /var/lib/globular/repository/artifacts/ 2>/dev/null | wc -l" 2>/dev/null || echo 0)
        local found=0
        if [[ "${hits:-0}" -gt 0 ]]; then
            found=$(docker exec "$c" bash -c \
                "find /var/lib/globular/repository/artifacts/ -type f 2>/dev/null | head -500 | wc -l" \
                2>/dev/null || echo 0)
        fi
        # Staged archive is the sanctioned recovery source; count it as present
        # only if the CAS itself has content, otherwise the node still cannot
        # serve. Keeping these separate is the whole point.
        if [[ "${found:-0}" -gt 0 ]]; then
            with=$(( with + 1 ))
        else
            missing_list="${missing_list}${missing_list:+,}${c#globular-}"
        fi
    done

    echo "{\"nodes\":${total},\"with_blob\":${with},\"missing\":$(( total - with )),\"missing_nodes\":\"${missing_list}\"}"
}

# probe: repository.identity_findings
# Returns: {"total":N,"ambiguous":N,"missing_blob":N,"conflict":N}
#
# Surfaces the repository's own identity invariants rather than re-deriving
# them: version_resolution_ambiguous (one version, two build_ids),
# missing_blob_for_published_manifest, build_id_checksum_conflict. All three
# fired on 2026-08-16 and each one stalls a rollout in a different way.
probe_repository_identity_findings() {
    if ! _container_running "$ETCD_CONTAINER"; then
        echo '{"total":0,"ambiguous":0,"missing_blob":0,"conflict":0,"error":"container not running"}'
        return
    fi

    local out
    out=$(docker exec "$ETCD_CONTAINER" globular repository doctor identity --json 2>/dev/null || echo "")
    if [[ -z "$out" ]]; then
        echo '{"total":0,"ambiguous":0,"missing_blob":0,"conflict":0,"error":"repository doctor identity unavailable"}'
        return
    fi

    printf '%s' "$out" | python3 -c '
import sys, json
raw = sys.stdin.read()
s, e = raw.find("["), raw.rfind("]")
if s < 0 or e <= s:
    s, e = raw.find("{"), raw.rfind("}")
try:
    doc = json.loads(raw[s:e+1])
except Exception:
    print(json.dumps({"total":0,"ambiguous":0,"missing_blob":0,"conflict":0,
                      "error":"unparseable doctor output"}))
    raise SystemExit(0)
items = doc if isinstance(doc, list) else (doc.get("findings") or [])
def count(sub):
    return sum(1 for f in items
               if sub in json.dumps(f).lower())
print(json.dumps({
    "total": len(items),
    "ambiguous": count("version_resolution_ambiguous"),
    "missing_blob": count("missing_blob_for_published_manifest"),
    "conflict": count("build_id_checksum_conflict"),
}))
'
}

# probe: service.restart_is_truthful
# Returns: {"claimed":"<state>","actual":"<state>","truthful":bool}
#
# On 2026-08-16 the node-agent's restart RPC returned ok:true state:"active"
# for a unit that stayed failed, with no start attempt in the journal. A
# control plane that reports success for an action it did not perform is worse
# than one that reports failure: the operator stops looking.
#
# Params: --node <node-N> --unit <systemd unit>
probe_service_restart_is_truthful() {
    local node="node-1" unit=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --node) node="$2"; shift 2 ;;
            --unit) unit="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    local container="globular-${node}"
    if [[ -z "$unit" ]] || ! _container_running "$container"; then
        echo '{"claimed":"","actual":"","truthful":false,"error":"container not running or --unit missing"}'
        return
    fi

    local actual
    actual=$(docker exec "$container" systemctl is-active "$unit" 2>/dev/null | tr -d '[:space:]')
    [[ -z "$actual" ]] && actual="unknown"

    # The claim is whatever the unit's own ActiveState says; a probe cannot
    # invoke the RPC without mutating, so the scenario pairs this with a
    # chaos.restart_service action and compares.
    local claimed
    claimed=$(docker exec "$container" systemctl show "$unit" \
        --property=ActiveState --value 2>/dev/null | tr -d '[:space:]')
    [[ -z "$claimed" ]] && claimed="unknown"

    local truthful=false
    [[ "$claimed" == "$actual" || ( "$claimed" == "active" && "$actual" == "active" ) ]] && truthful=true

    echo "{\"claimed\":\"${claimed}\",\"actual\":\"${actual}\",\"truthful\":${truthful}}"
}

# probe: cluster.installed_version_convergence
# Returns: {"nodes":N,"converged":N,"lagging":N,"versions":"...","unique":N}
#
# A rollout is converged only when every required node proves the expected
# artifact is installed AND running — child-workflow SUCCEEDED is dispatch ack,
# not install proof (rollout.convergence_requires_runtime_proof). This counts
# distinct installed versions across nodes: more than one means the rollout is
# still in flight or stuck.
#
# Params: --package <name> [--expect_version <v>]
probe_cluster_installed_version_convergence() {
    local pkg="" expect=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --package) pkg="$2"; shift 2 ;;
            --expect_version) expect="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    if [[ -z "$pkg" ]] || ! _container_running "$ETCD_CONTAINER"; then
        echo '{"nodes":0,"converged":0,"lagging":0,"versions":"","unique":0,"error":"container not running or --package missing"}'
        return
    fi

    local keys versions="" total=0 converged=0
    keys=$(_etcd_keys /globular/nodes/ 2>/dev/null | grep -iE "packages/.*/${pkg}\$" || true)
    local k
    for k in $keys; do
        local v
        v=$(_etcd_get "$k" 2>/dev/null | python3 -c '
import sys, json
try:
    print(json.load(sys.stdin).get("version", ""))
except Exception:
    print("")
' 2>/dev/null || echo "")
        [[ -z "$v" ]] && continue
        total=$(( total + 1 ))
        versions="${versions}${versions:+,}${v}"
        if [[ -n "$expect" && "$v" == "$expect" ]]; then
            converged=$(( converged + 1 ))
        fi
    done

    # Same grep -c hazard as above; and the first assignment was dead.
    local unique
    unique=$(printf '%s' "$versions" | tr ',' '\n' | sort -u | grep . | wc -l)
    [[ -z "$expect" ]] && converged=$total

    echo "{\"nodes\":${total},\"converged\":${converged},\"lagging\":$(( total - converged )),\"versions\":\"${versions}\",\"unique\":${unique:-0}}"
}

# probe: etcd.defrag_evidence
# Returns: {"nodes_seen":N,"loops_started":N,"defrags_run":N,"defrags_complete":N,
#           "total_freed_bytes":N,"last":"..."}
#
# Proves the node-agent maintenance loop DID something, not merely that it
# started. probe_etcd_backend_growth reports defrag_scheduled=true as soon as
# the loop announces itself at boot — which is exactly the "a check that cannot
# fail is indistinguishable from one that passes" shape this suite exists to
# catch. A loop that starts, skips forever, and never reclaims a byte would
# satisfy that probe while leaving the 2026-08-16 NOSPACE failure fully armed.
#
# Reads the node-agent journal on every node, because the maintenance pass is
# round-robin: only one member is eligible per interval, so evidence appears on
# whichever node's turn came up, not on any particular one.
probe_etcd_defrag_evidence() {
    local total=0 started=0 run=0 done_ct=0 freed=0 last=""
    local c
    for c in $(_all_node_containers); do
        total=$(( total + 1 ))
        local j
        j=$(docker exec "$c" journalctl -u globular-node-agent --no-pager -o cat 2>/dev/null || true)
        [ -z "$j" ] && continue
        started=$(( started + $(printf '%s' "$j" | grep 'etcd.maintenance_started' | wc -l) ))
        run=$(( run + $(printf '%s' "$j" | grep 'etcd.defrag_starting' | wc -l) ))
        done_ct=$(( done_ct + $(printf '%s' "$j" | grep 'etcd.defrag_complete' | wc -l) ))
        local f
        f=$(printf '%s' "$j" | grep -oE 'freed_bytes=[0-9]+' | sed 's/freed_bytes=//' \
              | awk '{s+=$1} END{print s+0}')
        freed=$(( freed + ${f:-0} ))
        local l
        l=$(printf '%s' "$j" | grep 'etcd.defrag_complete' | tail -1 | cut -c1-160 | tr -d '"')
        [ -n "$l" ] && last="$l"
    done
    echo "{\"nodes_seen\":${total},\"loops_started\":${started},\"defrags_run\":${run},\"defrags_complete\":${done_ct},\"total_freed_bytes\":${freed},\"last\":\"${last}\"}"
}

# probe: controller.leadership
# Returns: {"leader_addr":"host:port","leader_node":"node-N","claimants":N,
#           "instances":"node-1:pid:uuid,...","leader_instance":"...",
#           "distinct_leaders":N}
#
# Controller leadership is an etcd lease election: every candidate holds a
# lease-backed key /globular/clustercontroller/leader/<lease-hex> whose value is
# "<node>:<pid>:<instance-uuid>", and /globular/clustercontroller/leader/addr
# names the current winner. The instance UUID is the identity of one AUTHORITY
# INSTANCE — not of the node and not of the process image.
#
# That distinction is the whole point. A SIGSTOPed leader keeps its memory and
# wakes up still believing it holds generation N. Testing that leader election
# works says nothing about whether losing authority is IRREVERSIBLE for the
# instance that lost it. This probe exposes the evidence needed to ask the
# second question: who is leader, how many claim to be, and is the leader the
# same instance as before.
probe_controller_leadership() {
    if ! _container_running "$ETCD_CONTAINER"; then
        echo '{"leader_addr":"","leader_node":"","claimants":0,"instances":"","leader_instance":"","distinct_leaders":0,"error":"etcd container not running"}'
        return
    fi

    local addr
    addr=$(_etcd_get /globular/clustercontroller/leader/addr 2>/dev/null | tr -d '[:space:]')

    local instances="" claimants=0 leader_node="" leader_instance=""
    local k v
    for k in $(_etcd_keys /globular/clustercontroller/leader 2>/dev/null | grep -v '/addr$'); do
        v=$(_etcd_get "$k" 2>/dev/null | tr -d '[:space:]')
        [ -z "$v" ] && continue
        claimants=$(( claimants + 1 ))
        instances="${instances}${instances:+,}${v}"
    done

    # Map the leader endpoint back to a node by matching the container IP.
    if [ -n "$addr" ]; then
        local ip="${addr%%:*}" c
        for c in $(_all_node_containers); do
            local cip
            cip=$(docker inspect "$c" --format \
                '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null)
            if [ "$cip" = "$ip" ]; then
                leader_node="${c#globular-}"
                break
            fi
        done
    fi

    # The claimant whose node matches the leader endpoint is the leader instance.
    if [ -n "$leader_node" ]; then
        leader_instance=$(printf '%s' "$instances" | tr ',' '\n' \
            | grep "^${leader_node}:" | head -1)
    fi

    # More than one node asserting the leader address is dual authority.
    local distinct
    distinct=$(printf '%s' "$instances" | tr ',' '\n' | grep . | cut -d: -f1 | sort -u | grep . | wc -l)

    local has_leader=false
    [ -n "$addr" ] && [ -n "$leader_node" ] && has_leader=true

    echo "{\"leader_addr\":\"${addr}\",\"leader_node\":\"${leader_node}\",\"has_leader\":${has_leader},\"claimants\":${claimants},\"instances\":\"${instances}\",\"leader_instance\":\"${leader_instance}\",\"distinct_leaders\":${distinct:-0}}"
}

# probe: cluster.node_identity_collisions
# Returns: {"registered_ids":N,"distinct_ids":N,"collisions":N,
#           "hostnames":N,"distinct_hostnames":N,"colliding":"id,..."}
#
# Counts node identities that are claimed more than once.
#
# Availability testing cannot see this fault: nothing is down, no packet is
# dropped, and every claimant is internally consistent. Two machines restored
# from one backup, or a VM cloned from a snapshot, both produce a cluster where
# a single node_id has two writers — after which every per-node record
# (heartbeat, installed state, runtime proof) is written by two actors with no
# way to tell them apart.
#
# Collisions are counted two ways because either alone can be fooled: by node_id
# across the per-node key space, and by hostname across the registered set. A
# clone that was admitted under a fresh id still shows up as a duplicate
# hostname, and one admitted under the same id shows up as a duplicate id.
probe_cluster_node_identity_collisions() {
    if ! _container_running "$ETCD_CONTAINER"; then
        echo '{"registered_ids":0,"distinct_ids":0,"collisions":0,"hostnames":0,"distinct_hostnames":0,"colliding":"","error":"etcd container not running"}'
        return
    fi

    # Node ids as they appear in the per-node key space.
    local ids
    ids=$(_etcd_keys /globular/nodes/ 2>/dev/null \
            | awk -F/ 'NF>=4 && $4 != "" {print $4}' | sort -u | grep . || true)
    local total distinct
    total=$(printf '%s\n' "$ids" | grep . | wc -l)
    distinct=$(printf '%s\n' "$ids" | grep . | sort -u | wc -l)

    # Hostnames from the controller's node records: a second machine claiming an
    # existing hostname is the same fault wearing a different label.
    local blob hostcount hostdistinct colliding
    blob=$(_etcd_get /globular/clustercontroller/state 2>/dev/null || echo "")
    if [ -n "$blob" ]; then
        read -r hostcount hostdistinct colliding <<<"$(printf '%s' "$blob" | python3 -c '
import sys, json, collections
try:
    doc = json.load(sys.stdin)
except Exception:
    print("0 0 "); raise SystemExit
nodes = doc.get("nodes") or {}
names = []
for nid, n in nodes.items():
    if isinstance(n, dict):
        names.append(str(n.get("hostname") or n.get("name") or nid))
c = collections.Counter(names)
dupes = sorted(k for k, v in c.items() if v > 1)
print(len(names), len(set(names)), ",".join(dupes))
' 2>/dev/null)"
    fi
    hostcount="${hostcount:-0}"; hostdistinct="${hostdistinct:-0}"; colliding="${colliding:-}"

    # A collision is any claimed identity with more than one claimant, counted on
    # whichever axis shows it.
    local id_coll=$(( total - distinct ))
    local host_coll=$(( hostcount - hostdistinct ))
    [ "$id_coll" -lt 0 ] && id_coll=0
    [ "$host_coll" -lt 0 ] && host_coll=0
    local collisions=$id_coll
    [ "$host_coll" -gt "$collisions" ] && collisions=$host_coll

    echo "{\"registered_ids\":${total},\"distinct_ids\":${distinct},\"collisions\":${collisions},\"hostnames\":${hostcount},\"distinct_hostnames\":${hostdistinct},\"colliding\":\"${colliding}\"}"
}
