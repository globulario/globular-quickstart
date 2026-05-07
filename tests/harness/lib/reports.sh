#!/usr/bin/env bash
# reports.sh — report generation helpers for the test harness
#
# Functions that produce markdown and JSON evidence outputs.
# REPORTS_DIR must be set by the caller.

# _awareness_artifact_line <adir>
# Print a compact one-line status string for awareness artifacts in adir.
_awareness_artifact_line() {
    local adir="$1"
    local skipped=false
    [ -f "$adir/SKIPPED.txt" ] && skipped=true

    _aw_status() {
        local label="$1"; shift
        local status="SKIPPED"
        if $skipped; then
            printf '%s=SKIPPED' "$label"
            return
        fi
        for f in "$@"; do
            [ -f "$adir/$f" ] && status="PASS" && break
        done
        printf '%s=%s' "$label" "$status"
    }

    local preflight debug_s snapshot incident

    if $skipped; then
        printf 'preflight=SKIPPED debug-session=SKIPPED runtime-snapshot=SKIPPED incident=SKIPPED'
        return
    fi

    # preflight
    if [ -f "$adir/preflight.agent.txt" ] || [ -f "$adir/preflight.json" ]; then
        preflight="PASS"
    else
        preflight="SKIPPED"
    fi

    # debug-session
    if [ -f "$adir/debug-session.agent.txt" ] || [ -f "$adir/debug-session.json" ]; then
        debug_s="PASS"
    else
        debug_s="SKIPPED"
    fi

    # runtime-snapshot
    if [ -f "$adir/runtime-snapshot.json" ]; then
        snapshot="PASS"
    elif [ -f "$adir/runtime-snapshot.error.txt" ]; then
        snapshot="ERROR"
    else
        snapshot="SKIPPED"
    fi

    # incident
    if [ -f "$adir/incident.yaml" ]; then
        incident="CREATED"
    elif [ -f "$adir/incident.error.txt" ]; then
        incident="ERROR"
    else
        incident="SKIPPED"
    fi

    printf 'preflight=%s debug-session=%s runtime-snapshot=%s incident=%s' \
        "$preflight" "$debug_s" "$snapshot" "$incident"
}

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

        # Awareness artifact summary (one compact line per scenario)
        local adir="$scenario_dir/awareness"
        if [ -d "$adir" ]; then
            local aw_summary
            aw_summary="$(_awareness_artifact_line "$adir")"
            echo "  - Awareness: $aw_summary" >> "$summary_file"
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
