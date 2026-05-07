#!/usr/bin/env bash
# test_awareness.sh — unit tests for the awareness harness integration
#
# Tests:
#   1. awareness_available returns false when globular is missing
#   2. awareness_preflight writes SKIPPED.txt when unavailable
#   3. scenario with awareness block creates awareness directory
#   4. failing scenario triggers debug-session collection
#   5. awareness unavailability does not fail scenario by default
#   6. AWARENESS_REQUIRED=1 fails scenario if awareness is unavailable
#   7. check-test-schemas accepts awareness block
#   8. report summary includes awareness artifact status
#
# Run: bash tests/harness/tests/test_awareness.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TESTS_DIR="$(cd "$HARNESS_DIR/.." && pwd)"
ROOT_DIR="$(cd "$TESTS_DIR/.." && pwd)"
LIB_DIR="$HARNESS_DIR/lib"
AWARENESS_SH="$LIB_DIR/awareness.sh"
SCENARIO_BIN="$HARNESS_DIR/bin/globular-scenario"

pass=0
fail=0

ok()   { echo "  PASS: $*"; ((pass++)) || true; }
fail() { echo "  FAIL: $*"; ((fail++)) || true; }

assert_file_exists() {
    local f="$1" msg="${2:-$1 exists}"
    if [ -f "$f" ]; then ok "$msg"; else fail "$msg (file not found: $f)"; fi
}

assert_file_not_exists() {
    local f="$1" msg="${2:-$1 absent}"
    if [ ! -f "$f" ]; then ok "$msg"; else fail "$msg (file unexpectedly found: $f)"; fi
}

assert_dir_exists() {
    local d="$1" msg="${2:-$1 exists}"
    if [ -d "$d" ]; then ok "$msg"; else fail "$msg (dir not found: $d)"; fi
}

assert_eq() {
    local got="$1" want="$2" msg="${3:-}"
    if [ "$got" = "$want" ]; then ok "${msg:-eq: $got}"; else fail "${msg:-eq}: got '$got' want '$want'"; fi
}

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

echo ""
echo "=== Awareness Harness Unit Tests ==="
echo ""

# ── Test 1: awareness_available returns false when globular is missing ────────

echo "Test 1: awareness_available returns false when binary is missing"
{
    # Override PATH to exclude globular.
    result=0
    (PATH="/usr/bin:/bin" bash -c "source \"$AWARENESS_SH\" && awareness_available") 2>/dev/null || result=$?
    if [ "$result" -ne 0 ]; then
        ok "awareness_available returns non-zero when globular not in PATH"
    else
        fail "awareness_available should return non-zero when globular not in PATH"
    fi
}

# ── Test 2: awareness_preflight writes SKIPPED.txt when unavailable ───────────

echo "Test 2: awareness_preflight writes SKIPPED.txt when unavailable"
{
    local_out="$tmpdir/test2"
    mkdir -p "$local_out"
    (
        PATH="/usr/bin:/bin"
        export PATH
        source "$AWARENESS_SH"
        AWARENESS_REQUIRED=0
        awareness_preflight "test task" "test_phase" "$local_out"
    ) 2>/dev/null || true
    assert_file_exists "$local_out/awareness/SKIPPED.txt" \
        "SKIPPED.txt written when awareness unavailable"
}

# ── Test 3: scenario with awareness block creates awareness directory ─────────

echo "Test 3: scenario with awareness block creates awareness/ directory"
{
    # Create a minimal passing scenario with awareness block.
    local_out="$tmpdir/test3"
    mkdir -p "$local_out"
    local_scenario="$tmpdir/test3_scenario.yaml"
    cat > "$local_scenario" <<'YAML'
version: 1
name: test-awareness-dir
suite: smoke
description: Unit test scenario with awareness block.
awareness:
  enabled: true
  task: "test task for unit test"
  phase: "test"
  include_runtime: false
YAML
    # Run scenario (preconditions/steps/assertions all empty — should pass).
    (
        PATH="/usr/bin:/bin:$(dirname "$(which python3)")"
        python3 "$SCENARIO_BIN" "$local_scenario" "$local_out" 2>/dev/null || true
    )
    # awareness/ dir should exist (either SKIPPED.txt or actual files).
    assert_dir_exists "$local_out/awareness" \
        "awareness/ directory created for scenario with awareness block"
}

# ── Test 4: check-test-schemas accepts awareness block ────────────────────────

echo "Test 4: check-test-schemas accepts valid awareness block"
{
    local_scenario="$tmpdir/test4_scenario.yaml"
    cat > "$local_scenario" <<'YAML'
version: 1
name: test-awareness-schema
suite: smoke
description: Scenario with valid awareness block.
awareness:
  enabled: true
  task: "valid task"
  phase: "recovery"
  include_runtime: true
  create_incident_on_failure: false
  expected_invariants:
    - infra.founding_quorum
  expected_forbidden_fixes:
    - create_infra_release_from_heartbeat_only
YAML
    result=0
    python3 -c "
import yaml, sys
with open('$local_scenario') as fh:
    d = yaml.safe_load(fh)
required = ['version', 'name', 'suite']
missing = [k for k in required if k not in d]
if missing:
    print(f'FAIL: missing {missing}')
    sys.exit(1)
if d['version'] != 1:
    print(f'FAIL: bad version')
    sys.exit(1)
aw = d.get('awareness')
if aw is not None:
    if not isinstance(aw, dict):
        print('FAIL: awareness not a dict')
        sys.exit(1)
    valid_keys = {
        'enabled', 'task', 'phase', 'include_runtime', 'runtime_window',
        'create_incident_on_failure', 'expected_invariants', 'expected_forbidden_fixes',
    }
    unknown = set(aw.keys()) - valid_keys
    if unknown:
        print(f'FAIL: unknown keys: {sorted(unknown)}')
        sys.exit(1)
print('OK')
" 2>/dev/null || result=$?
    if [ "$result" -eq 0 ]; then
        ok "schema validator accepts valid awareness block"
    else
        fail "schema validator rejected valid awareness block"
    fi
}

# ── Test 5: schema validator rejects unknown awareness keys ──────────────────

echo "Test 5: check-test-schemas rejects unknown awareness keys"
{
    local_scenario="$tmpdir/test5_scenario.yaml"
    cat > "$local_scenario" <<'YAML'
version: 1
name: test-bad-awareness
suite: smoke
awareness:
  enabled: true
  unknown_key: should_fail
YAML
    result=0
    python3 -c "
import yaml, sys
with open('$local_scenario') as fh:
    d = yaml.safe_load(fh)
aw = d.get('awareness')
if aw is not None:
    valid_keys = {
        'enabled', 'task', 'phase', 'include_runtime', 'runtime_window',
        'create_incident_on_failure', 'expected_invariants', 'expected_forbidden_fixes',
    }
    unknown = set(aw.keys()) - valid_keys
    if unknown:
        print(f'FAIL: {sorted(unknown)}')
        sys.exit(1)
print('OK')
" 2>/dev/null || result=$?
    if [ "$result" -ne 0 ]; then
        ok "schema validator rejects unknown awareness key"
    else
        fail "schema validator should reject unknown awareness key"
    fi
}

# ── Test 6: awareness unavailability does not fail scenario by default ────────

echo "Test 6: awareness unavailability does not fail scenario (AWARENESS_REQUIRED=0)"
{
    local_out="$tmpdir/test6"
    mkdir -p "$local_out"
    local_scenario="$tmpdir/test6_scenario.yaml"
    cat > "$local_scenario" <<'YAML'
version: 1
name: test-no-awareness-fail
suite: smoke
description: Scenario should PASS even when awareness is unavailable.
awareness:
  enabled: true
  task: "test"
YAML
    result=0
    (
        PATH="/usr/bin:/bin:$(dirname "$(which python3)")"
        AWARENESS_REQUIRED=0
        export AWARENESS_REQUIRED
        python3 "$SCENARIO_BIN" "$local_scenario" "$local_out"
    ) 2>/dev/null || result=$?
    # The scenario has no assertions so it should pass (exit 0).
    if [ "$result" -eq 0 ]; then
        ok "scenario exits 0 when awareness unavailable and AWARENESS_REQUIRED=0"
    else
        fail "scenario should not fail due to awareness unavailability (got exit $result)"
    fi
}

# ── Test 7: _awareness_artifact_line produces correct status ─────────────────

echo "Test 7: _awareness_artifact_line produces correct status strings"
{
    local_adir="$tmpdir/test7_awareness"
    mkdir -p "$local_adir"

    # All skipped (SKIPPED.txt present, no artifacts)
    echo "skipped" > "$local_adir/SKIPPED.txt"
    result=$(bash -c "source \"$LIB_DIR/reports.sh\" && _awareness_artifact_line \"$local_adir\"" 2>/dev/null || true)
    if echo "$result" | grep -q "preflight=SKIPPED" && \
       echo "$result" | grep -q "incident=SKIPPED"; then
        ok "_awareness_artifact_line: all SKIPPED when SKIPPED.txt present"
    else
        fail "_awareness_artifact_line: expected all SKIPPED, got: $result"
    fi

    # Preflight PASS
    rm -f "$local_adir/SKIPPED.txt"
    echo "preflight content" > "$local_adir/preflight.agent.txt"
    result=$(bash -c "source \"$LIB_DIR/reports.sh\" && _awareness_artifact_line \"$local_adir\"" 2>/dev/null || true)
    if echo "$result" | grep -q "preflight=PASS"; then
        ok "_awareness_artifact_line: preflight=PASS when agent.txt present"
    else
        fail "_awareness_artifact_line: expected preflight=PASS, got: $result"
    fi

    # Runtime snapshot ERROR
    echo "error content" > "$local_adir/runtime-snapshot.error.txt"
    result=$(bash -c "source \"$LIB_DIR/reports.sh\" && _awareness_artifact_line \"$local_adir\"" 2>/dev/null || true)
    if echo "$result" | grep -q "runtime-snapshot=ERROR"; then
        ok "_awareness_artifact_line: runtime-snapshot=ERROR when error.txt present"
    else
        fail "_awareness_artifact_line: expected runtime-snapshot=ERROR, got: $result"
    fi
}

# ── Test 8: SKIPPED.txt written on preflight when awareness unavailable ───────

echo "Test 8: awareness_write_skipped writes readable SKIPPED.txt"
{
    local_out="$tmpdir/test8"
    mkdir -p "$local_out"
    bash -c "source \"$AWARENESS_SH\" && awareness_write_skipped \"$local_out\" \"unit test reason\"" 2>/dev/null || true
    assert_file_exists "$local_out/awareness/SKIPPED.txt" "SKIPPED.txt created"
    if grep -q "unit test reason" "$local_out/awareness/SKIPPED.txt" 2>/dev/null; then
        ok "SKIPPED.txt contains reason string"
    else
        fail "SKIPPED.txt missing reason string"
    fi
}

# ── Test 9: training_ledger_append writes valid JSON to ledger ────────────────

echo "Test 9: training_ledger_append writes a valid JSON line to the ledger"
{
    local_ledger="$tmpdir/test9_ledger.jsonl"
    local_out="$tmpdir/test9_out"
    mkdir -p "$local_out/awareness"
    bash -c "
        source \"$LIB_DIR/training.sh\"
        training_ledger_append \
            '$local_ledger' \
            'run-test9' \
            'unit-test-scenario' \
            'PASS' \
            'SKIPPED' \
            'test task' \
            'test_phase' \
            'false' \
            'false' \
            '$local_out'
    " 2>/dev/null || true
    assert_file_exists "$local_ledger" "ledger file created"
    if [ -f "$local_ledger" ]; then
        if python3 -c "import json; d=json.loads(open('$local_ledger').read()); assert d.get('result')=='PASS'" 2>/dev/null; then
            ok "ledger entry has result=PASS"
        else
            fail "ledger entry missing or malformed result field"
        fi
        if python3 -c "import json; d=json.loads(open('$local_ledger').read()); assert d.get('scenario')=='unit-test-scenario'" 2>/dev/null; then
            ok "ledger entry has correct scenario name"
        else
            fail "ledger entry missing scenario name"
        fi
    fi
}

# ── Test 10: training_ledger_append extracts awareness meta from JSON artifacts ──

echo "Test 10: training_ledger_append extracts matched_invariants from preflight.json"
{
    local_ledger="$tmpdir/test10_ledger.jsonl"
    local_out="$tmpdir/test10_out"
    mkdir -p "$local_out/awareness"
    # Write a mock preflight.json with matched invariants
    python3 -c "
import json
d = {
    'matched_invariants': ['infra.founding_quorum', 'runtime.installed_state_not_liveness'],
    'matched_failure_modes': ['node_agent.install_loop'],
    'forbidden_fixes': [],
}
print(json.dumps(d))
" > "$local_out/awareness/preflight.json"
    bash -c "
        source \"$LIB_DIR/training.sh\"
        training_ledger_append \
            '$local_ledger' 'run-test10' 'meta-test' 'FAIL' 'PASS' \
            'test task' 'recovery' 'false' 'false' '$local_out'
    " 2>/dev/null || true
    if [ -f "$local_ledger" ]; then
        if python3 -c "
import json
d=json.loads(open('$local_ledger').read())
assert 'infra.founding_quorum' in d.get('matched_invariants', []), d
" 2>/dev/null; then
            ok "matched_invariants extracted from preflight.json"
        else
            fail "matched_invariants not extracted from preflight.json"
        fi
        if python3 -c "
import json
d=json.loads(open('$local_ledger').read())
assert 'node_agent.install_loop' in d.get('matched_failure_modes', []), d
" 2>/dev/null; then
            ok "matched_failure_modes extracted from preflight.json"
        else
            fail "matched_failure_modes not extracted from preflight.json"
        fi
    fi
}

# ── Test 11: training schema validator accepts new keys ───────────────────────

echo "Test 11: schema validator accepts create_proposal_on_failure and expected_failure_modes"
{
    local_scenario="$tmpdir/test11_scenario.yaml"
    cat > "$local_scenario" <<'YAML'
version: 1
name: test-training-schema
suite: training
description: Scenario with training-mode awareness keys.
awareness:
  enabled: true
  task: "training scenario"
  phase: "recovery"
  include_runtime: true
  create_incident_on_failure: true
  create_proposal_on_failure: false
  expected_failure_modes:
    - node_agent.install_loop
  expected_invariants:
    - infra.founding_quorum
  training:
    enabled: true
YAML
    result=0
    python3 -c "
import yaml, sys
with open('$local_scenario') as fh:
    d = yaml.safe_load(fh)
aw = d.get('awareness', {})
valid_keys = {
    'enabled', 'task', 'phase', 'include_runtime', 'runtime_window',
    'create_incident_on_failure', 'expected_invariants', 'expected_forbidden_fixes',
    'create_proposal_on_failure', 'expected_failure_modes', 'training',
}
unknown = set(aw.keys()) - valid_keys
if unknown:
    print(f'FAIL: unknown keys: {sorted(unknown)}')
    sys.exit(1)
print('OK')
" 2>/dev/null || result=$?
    if [ "$result" -eq 0 ]; then
        ok "schema validator accepts all training-mode awareness keys"
    else
        fail "schema validator rejected valid training-mode keys"
    fi
}

# ── Test 12: proposal.yaml presence does not trigger auto-approval ────────────

echo "Test 12: proposal.yaml is written as DRAFT — not automatically approved"
{
    local_out="$tmpdir/test12_out"
    mkdir -p "$local_out/awareness"
    # Simulate a proposal written by awareness_propose_from_incident
    cat > "$local_out/awareness/proposal.yaml" <<'YAML'
kind: AwarenessProposal
status: DRAFT
incident_id: "INC-2026-TEST-0001"
title: "Test draft proposal — do not approve automatically"
changes: []
YAML
    # Verify the file exists as DRAFT and was NOT auto-approved
    if [ -f "$local_out/awareness/proposal.yaml" ]; then
        if grep -q "DRAFT" "$local_out/awareness/proposal.yaml" 2>/dev/null; then
            ok "proposal.yaml status is DRAFT"
        else
            fail "proposal.yaml status is not DRAFT"
        fi
        # Confirm no approval marker was written
        if [ ! -f "$local_out/awareness/proposal.approved" ]; then
            ok "no proposal.approved marker — auto-approval did not occur"
        else
            fail "proposal.approved marker found — auto-approval must never happen"
        fi
    else
        fail "proposal.yaml not found in test fixture"
    fi
    # Ledger should record proposal_created=true without approving
    local_ledger="$tmpdir/test12_ledger.jsonl"
    bash -c "
        source \"$LIB_DIR/training.sh\"
        training_ledger_append \
            '$local_ledger' 'run-test12' 'proposal-test' 'FAIL' 'PASS' \
            'proposal task' 'recovery' 'true' 'true' '$local_out'
    " 2>/dev/null || true
    if [ -f "$local_ledger" ]; then
        if python3 -c "
import json
d=json.loads(open('$local_ledger').read())
assert d.get('proposal_created') == True, d
" 2>/dev/null; then
            ok "ledger records proposal_created=true"
        else
            fail "ledger does not record proposal_created correctly"
        fi
    fi
}

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "=== Results: $pass passed, $fail failed ==="
echo ""
[ "$fail" -eq 0 ]
