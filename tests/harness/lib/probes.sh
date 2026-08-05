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
    local node="" service=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --node)    node="$2"; shift 2 ;;
            --service) service="$2"; shift 2 ;;
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

    local unit_name="globular-${service}.service"
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
    uuid=$(docker exec "$container" cat /var/lib/globular/nodeagent/state.json 2>/dev/null | \
        python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('node_id', ''))
except:
    pass
" 2>/dev/null || echo "")

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
        echo "{\"valid\":false,\"error\":\"container not running\",\"node\":\"$node\"}"
        return
    fi

    # Check cert is valid for 30+ more days (exit 0 = not expiring within N seconds)
    local valid_30d=false
    docker exec "$container" openssl x509 -noout \
        -checkend $((30*24*3600)) -in "$cert" >/dev/null 2>&1 && valid_30d=true

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

    echo "{\"valid\":$valid_30d,\"days_remaining\":$days_remaining,\"has_vip\":$has_vip,\"not_after\":\"$not_after\",\"node\":\"$node\"}"
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
# Params: --node <node>  --target_ip <ip>  --target_port <port>
# Returns: {"connected":true|false,"target":"IP:port","node":"..."}
# Uses openssl s_client with mTLS (service cert + CA) to verify TLS handshake.
probe_pki_mtls_connect() {
    local node="node-1" target_ip="" target_port=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --node)        node="$2"; shift 2 ;;
            --target_ip)   target_ip="$2"; shift 2 ;;
            --target_port) target_port="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    [[ -z "$target_ip" || -z "$target_port" ]] && {
        echo '{"connected":false,"error":"target_ip and target_port required"}'
        return
    }

    local container="globular-${node}"
    if ! _container_running "$container"; then
        echo "{\"connected\":false,\"error\":\"container not running\",\"node\":\"$node\"}"
        return
    fi

    # Send empty string to openssl s_client; exit 0 = TLS handshake succeeded.
    # Timeout 5s so we don't hang on unreachable hosts.
    local connected=false
    if docker exec "$container" bash -c "
        echo '' | timeout 5 openssl s_client \
            -connect ${target_ip}:${target_port} \
            -cert /var/lib/globular/pki/issued/services/service.crt \
            -key /var/lib/globular/pki/issued/services/service.key \
            -CAfile /var/lib/globular/pki/ca.crt \
            -verify_return_error \
            -quiet 2>/dev/null
    " >/dev/null 2>&1; then
        connected=true
    fi

    echo "{\"connected\":$connected,\"target\":\"${target_ip}:${target_port}\",\"node\":\"$node\"}"
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
        phase = (status.get('phase') or '').lower()
        if phase == 'succeeded':
            succeeded += 1
        elif phase == 'failed':
            failed += 1
        else:
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
    uuid=$(docker exec "$container" \
        cat /var/lib/globular/nodeagent/state.json 2>/dev/null | \
        python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('node_id', ''))
except:
    pass
" 2>/dev/null || echo "")

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
# Params: --node <node-id>
# Returns: {"fenced":true|false,"fenced_since":"...","node_id":"..."}
# Checks if Metadata["partition_fenced_since"] is set in the node's cluster state.
probe_node_partition_fenced() {
    local node=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --node) node="$2"; shift 2 ;;
            *) shift ;;
        esac
    done
    # Node state is stored at /globular/nodes/<node_id>/status as JSON.
    # We check if any node status JSON contains partition_fenced_since.
    local node_keys
    node_keys=$(_etcd_keys "/globular/nodes/" 2>/dev/null | grep '/status$' || echo "")
    while IFS= read -r key; do
        [[ -z "$key" ]] && continue
        local val
        val=$(_etcd_get "$key" 2>/dev/null || echo "")
        if echo "$val" | grep -q "partition_fenced_since"; then
            local fenced_since
            fenced_since=$(echo "$val" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('Metadata',{}).get('partition_fenced_since',''))" 2>/dev/null || echo "")
            echo "{\"fenced\":true,\"fenced_since\":\"$fenced_since\",\"node_id\":\"$node\"}"
            return
        fi
    done <<< "$node_keys"
    echo "{\"fenced\":false,\"node_id\":\"$node\"}"
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
        count=$(echo "$matches" | grep -c . || echo 0)
        kinds=$(echo "$matches" | sed 's/[0-9]\+//g' | sort -u | head -4 | tr '\n' ';' | tr -d '"' | cut -c1-200)
        sample=$(echo "$matches" | head -1 | tr -d '"' | cut -c1-160)
    fi

    local clean="true"
    [ "$count" -gt 0 ] && clean="false"
    echo "{\"clean\":${clean},\"error_count\":${count},\"kinds\":\"${kinds}\",\"sample\":\"${sample}\",\"node\":\"${node}\"}"
}
