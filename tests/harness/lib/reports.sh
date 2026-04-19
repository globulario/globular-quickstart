#!/usr/bin/env bash
# reports.sh — report generation helpers for the test harness
#
# Functions that produce markdown and JSON evidence outputs.
# REPORTS_DIR must be set by the caller.

# report_suite_summary <suite> <pass> <fail> <skip> <run_dir>
# Writes a markdown summary for a completed suite run.
report_suite_summary() {
    local suite="$1" pass="$2" fail="$3" skip="$4" run_dir="$5"
    local total=$((pass + fail + skip))
    local ts
    ts=$(date -u '+%Y-%m-%d %H:%M:%S UTC')
    local result_icon="PASS"
    [ "$fail" -gt 0 ] && result_icon="FAIL"

    local summary_file="$run_dir/SUMMARY.md"
    cat > "$summary_file" <<EOF
# Test Suite: $suite

**Result**: $result_icon
**Date**: $ts
**Total**: $total | **Pass**: $pass | **Fail**: $fail | **Skip**: $skip

## Scenarios

EOF

    # Append per-scenario result from evidence files
    for scenario_dir in "$run_dir"/*/; do
        [ -d "$scenario_dir" ] || continue
        local scenario_name
        scenario_name="$(basename "$scenario_dir")"
        local evidence_file="$scenario_dir/evidence.json"

        if [ -f "$evidence_file" ]; then
            local scenario_pass
            scenario_pass=$(python3 -c \
                "import json; d=json.load(open('$evidence_file')); print('PASS' if d.get('passed',False) else 'FAIL')" \
                2>/dev/null || echo "UNKNOWN")
            echo "- **[$scenario_pass]** $scenario_name" >> "$summary_file"
        else
            echo "- **[NO DATA]** $scenario_name" >> "$summary_file"
        fi
    done

    cat >> "$summary_file" <<EOF

## Evidence

See individual scenario directories for full evidence bundles:
\`\`\`
$(ls "$run_dir")
\`\`\`
EOF

    echo "[report] Summary written: $summary_file"
    cat "$summary_file"
}

# report_service_health
# Query all registered services from etcd and produce a health matrix.
# Resolves UUID keys → human-readable Names by parsing config JSON values.
report_service_health() {
    echo "# Service Health Matrix"
    echo "Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    echo ""

    if ! docker inspect globular-node-1 --format '{{.State.Running}}' 2>/dev/null | grep -q true; then
        echo "ERROR: cluster not running"
        return 1
    fi

    local ETCD_CMD="docker exec globular-node-1 /usr/lib/globular/bin/etcdctl --endpoints=https://10.10.0.11:2379 --cacert=/var/lib/globular/pki/ca.crt --cert=/var/lib/globular/pki/issued/services/service.crt --key=/var/lib/globular/pki/issued/services/service.key"

    # Fetch all config values and parse Name/Port/Address/Version from each JSON blob.
    # parse_service_configs.py handles etcdctl's concatenated-JSON output correctly.
    local _parser="${LIB_DIR:-$(dirname "${BASH_SOURCE[0]}")}/parse_service_configs.py"
    local service_table
    service_table=$($ETCD_CMD get /globular/services/ --prefix --print-value-only \
        2>/dev/null | python3 "$_parser" 2>/dev/null || echo "")

    echo "| Service Name | Port | Address | Version |"
    echo "|-------------|------|---------|---------|"
    if [ -n "$service_table" ]; then
        echo "$service_table"
    else
        echo "| (no services registered) | - | - | - |"
    fi

    echo ""
    echo "## Node Heartbeats"
    echo ""
    echo "| Node ID | Status |"
    echo "|---------|--------|"

    # Node agents register /node_agent_metrics_port — NOT /status
    local nkeys nodes
    nkeys=$($ETCD_CMD get /globular/nodes/ --prefix --keys-only 2>/dev/null || echo "")
    nodes=$(echo "$nkeys" | grep '/node_agent_metrics_port$' | \
            sed 's|/globular/nodes/||; s|/node_agent_metrics_port$||' | sort -u)

    local node_count=0
    while IFS= read -r node; do
        [ -z "$node" ] && continue
        echo "| $node | heartbeating |"
        node_count=$((node_count + 1))
    done <<< "$nodes"

    [ "$node_count" -eq 0 ] && echo "| (no nodes heartbeating) | - |"
}

# report_parity <run_dir>
# Placeholder: compare service list against golden baseline.
report_parity() {
    local run_dir="${1:-$REPORTS_DIR/latest}"
    local golden="$TESTS_DIR/golden/service-health-baseline.json"

    echo "# Feature Parity Report"
    echo "Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"

    if [ ! -f "$golden" ]; then
        echo "WARNING: No golden baseline found at $golden"
        return
    fi

    local expected_count
    expected_count=$(python3 -c \
        "import json; d=json.load(open('$golden')); print(d.get('expected_service_count',0))" \
        2>/dev/null || echo 0)

    echo ""
    echo "Expected services: $expected_count"
    report_service_health
}

# report_authz
# Placeholder authz report — full implementation requires runner container.
report_authz() {
    echo "# RBAC / Authz Report"
    echo "Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    echo ""
    echo "## Role Binding Count"

    local ETCD="docker exec globular-node-1 /usr/lib/globular/bin/etcdctl --endpoints=https://10.10.0.11:2379 --cacert=/var/lib/globular/pki/ca.crt --cert=/var/lib/globular/pki/issued/services/service.crt --key=/var/lib/globular/pki/issued/services/service.key"
    local bindings
    bindings=$($ETCD get /globular/rbac/bindings/ --prefix --keys-only 2>/dev/null | wc -l || echo 0)
    echo "Role bindings in etcd: $bindings"
    echo ""
    echo "NOTE: Full gRPC authz validation requires runner container (Wave 4)."
}

# report_recovery
# Placeholder recovery report.
report_recovery() {
    echo "# Recovery Report"
    echo "Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    echo ""
    echo "Recovery scenarios are implemented in Wave 7 (recovery suite)."
}
