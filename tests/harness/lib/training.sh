#!/usr/bin/env bash
# training.sh — awareness training loop coordination for globular-quickstart
#
# Manages the lab training ledger and post-scenario training summaries.
# Does NOT promote proposals or execute remediation automatically.
#
# Functions:
#   training_ledger_append      — append one JSON line to the training ledger
#   training_extract_awareness_meta — parse preflight/debug-session JSON
#   training_print_summary      — print training summary after a scenario
#   training_reset              — reset containers, preserve reports by default

TRAINING_LEDGER_DEFAULT="tests/reports/awareness-training-ledger.jsonl"

# ── ledger ────────────────────────────────────────────────────────────────────

# training_ledger_append <ledger_file> <run_id> <scenario> <result>
#                        <awareness_status> <task> <phase>
#                        [incident_created] [proposal_created] [report_dir]
# Appends one JSON object to the JSONL ledger.
# All args after phase are optional.
training_ledger_append() {
    local ledger_file="$1"
    local run_id="$2"
    local scenario="$3"
    local result="$4"           # PASS|FAIL|PARTIAL|INFRA_ERROR
    local awareness_status="$5" # PASS|SKIPPED|ERROR
    local task="${6:-}"
    local phase="${7:-}"
    local incident_created="${8:-false}"
    local proposal_created="${9:-false}"
    local report_dir="${10:-}"

    # Extract matched invariants/failure modes from JSON artifacts if present.
    local matched_invariants="[]"
    local matched_failure_modes="[]"
    local forbidden_fixes="[]"

    if [ -n "$report_dir" ] && [ -d "$report_dir/awareness" ]; then
        local meta
        meta="$(training_extract_awareness_meta "$report_dir/awareness")"
        if [ -n "$meta" ]; then
            matched_invariants="$(printf '%s' "$meta" | python3 -c \
                "import json,sys; d=json.load(sys.stdin); print(json.dumps(d.get('matched_invariants',[])))" \
                2>/dev/null || echo '[]')"
            matched_failure_modes="$(printf '%s' "$meta" | python3 -c \
                "import json,sys; d=json.load(sys.stdin); print(json.dumps(d.get('matched_failure_modes',[])))" \
                2>/dev/null || echo '[]')"
            forbidden_fixes="$(printf '%s' "$meta" | python3 -c \
                "import json,sys; d=json.load(sys.stdin); print(json.dumps(d.get('forbidden_fixes',[])))" \
                2>/dev/null || echo '[]')"
        fi
    fi

    local ts
    ts="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

    local entry
    entry="$(python3 -c "
import json, sys
entry = {
    'run_id':              '$run_id',
    'scenario':            '$scenario',
    'timestamp':           '$ts',
    'result':              '$result',
    'awareness_status':    '$awareness_status',
    'task':                '$task',
    'phase':               '$phase',
    'matched_invariants':  $matched_invariants,
    'matched_failure_modes': $matched_failure_modes,
    'forbidden_fixes':     $forbidden_fixes,
    'incident_created':    json.loads('$incident_created'),
    'proposal_created':    json.loads('$proposal_created'),
    'report_dir':          '$report_dir',
}
print(json.dumps(entry))
" 2>/dev/null || true)"

    if [ -z "$entry" ]; then
        echo "  [training] WARNING: could not create ledger entry" >&2
        return 0
    fi

    # Ensure ledger file directory exists.
    mkdir -p "$(dirname "$ledger_file")"
    printf '%s\n' "$entry" >> "$ledger_file"
    echo "  [training] ledger: $ledger_file"
}

# ── metadata extraction ───────────────────────────────────────────────────────

# training_extract_awareness_meta <awareness_dir>
# Print a JSON object with matched_invariants, matched_failure_modes, forbidden_fixes.
# Reads preflight.json and debug-session.json if available.
training_extract_awareness_meta() {
    local adir="$1"

    python3 - "$adir" <<'PYEOF'
import json, sys, os

adir = sys.argv[1]
result = {
    "matched_invariants": [],
    "matched_failure_modes": [],
    "forbidden_fixes": [],
    "required_tests": [],
    "learning_recommendation": "",
}

def load_json(path):
    try:
        with open(path) as f:
            return json.load(f)
    except Exception:
        return {}

def extend_unique(lst, items):
    for item in (items or []):
        if isinstance(item, str) and item not in lst:
            lst.append(item)
        elif isinstance(item, dict):
            n = item.get("id") or item.get("name") or str(item)
            if n not in lst:
                lst.append(n)

# Parse preflight.json
pf = load_json(os.path.join(adir, "preflight.json"))
extend_unique(result["matched_invariants"],    pf.get("matched_invariants") or pf.get("invariants"))
extend_unique(result["matched_failure_modes"], pf.get("matched_failure_modes") or pf.get("failure_modes"))
extend_unique(result["forbidden_fixes"],       pf.get("forbidden_fixes"))
extend_unique(result["required_tests"],        pf.get("required_tests"))

# Parse debug-session.json
dbs = load_json(os.path.join(adir, "debug-session.json"))
extend_unique(result["matched_invariants"],    dbs.get("matched_invariants") or dbs.get("invariants"))
extend_unique(result["matched_failure_modes"], dbs.get("matched_failure_modes") or dbs.get("failure_modes"))
extend_unique(result["forbidden_fixes"],       dbs.get("forbidden_fixes"))
extend_unique(result["required_tests"],        dbs.get("required_tests"))

rec = dbs.get("learning_recommendation") or dbs.get("recommendation") or pf.get("recommendation") or ""
if rec:
    result["learning_recommendation"] = rec

print(json.dumps(result))
PYEOF
}

# ── summary ───────────────────────────────────────────────────────────────────

# training_print_summary <out_dir> <scenario> <result> <awareness_status>
# Print a human-readable training summary after a scenario run.
training_print_summary() {
    local out_dir="$1"
    local scenario="${2:-unknown}"
    local result="${3:-UNKNOWN}"
    local awareness_status="${4:-UNKNOWN}"

    local adir="$out_dir/awareness"

    echo ""
    echo "┌─────────────────────────────────────────────────────────────────┐"
    printf  "│  Training Summary: %-45s │\n" "$scenario"
    echo "├─────────────────────────────────────────────────────────────────┤"
    printf  "│  Scenario result  : %-45s │\n" "$result"
    printf  "│  Awareness status : %-45s │\n" "$awareness_status"
    echo "├─────────────────────────────────────────────────────────────────┤"

    # Awareness artifacts
    if [ -f "$adir/SKIPPED.txt" ]; then
        printf  "│  Awareness        : SKIPPED                                     │\n"
    elif [ -d "$adir" ]; then
        local items=()
        [ -f "$adir/preflight.agent.txt"    ] && items+=("preflight")
        [ -f "$adir/debug-session.agent.txt"] && items+=("debug-session")
        [ -f "$adir/runtime-snapshot.json"  ] && items+=("runtime-snapshot")
        [ -f "$adir/did-we-fix.txt"         ] && items+=("did-we-fix")
        [ -f "$adir/incident.yaml"          ] && items+=("incident")
        [ -f "$adir/proposal.yaml"          ] && items+=("proposal[DRAFT]")
        local artifact_list
        artifact_list="$(IFS=', '; echo "${items[*]}")"
        printf  "│  Artifacts        : %-45s │\n" "${artifact_list:-none}"
    fi

    # Matched invariants / failure modes from JSON
    local meta
    meta="$(training_extract_awareness_meta "$adir" 2>/dev/null || echo '{}')"
    if [ -n "$meta" ]; then
        local inv
        inv="$(printf '%s' "$meta" | python3 -c \
            "import json,sys; d=json.load(sys.stdin); \
             items=d.get('matched_invariants',[]); \
             print(', '.join(items[:3]) + ('...' if len(items)>3 else ''))" \
            2>/dev/null || true)"
        [ -n "$inv" ] && printf "│  Invariants       : %-45s │\n" "$inv"

        local fm
        fm="$(printf '%s' "$meta" | python3 -c \
            "import json,sys; d=json.load(sys.stdin); \
             items=d.get('matched_failure_modes',[]); \
             print(', '.join(items[:3]) + ('...' if len(items)>3 else ''))" \
            2>/dev/null || true)"
        [ -n "$fm" ] && printf "│  Failure modes    : %-45s │\n" "$fm"

        local rec
        rec="$(printf '%s' "$meta" | python3 -c \
            "import json,sys; d=json.load(sys.stdin); \
             print(d.get('learning_recommendation','')[:45])" \
            2>/dev/null || true)"
        [ -n "$rec" ] && printf "│  Recommendation   : %-45s │\n" "$rec"
    fi

    # Next action reminder if there's a proposal
    if [ -f "$adir/proposal.yaml" ]; then
        echo "├─────────────────────────────────────────────────────────────────┤"
        echo "│  DRAFT PROPOSAL — manual review required before approval        │"
        printf  "│  File: %-57s │\n" "$(basename "$out_dir")/awareness/proposal.yaml"
        echo "│  Run: globular awareness validate-proposal --file <path>        │"
    elif [ -f "$adir/incident.yaml" ]; then
        echo "├─────────────────────────────────────────────────────────────────┤"
        echo "│  INCIDENT CREATED — review and optionally run propose-from-     │"
        echo "│  incident manually. See container_training_loop.md for steps.   │"
    fi

    echo "└─────────────────────────────────────────────────────────────────┘"
    echo ""
}

# ── reset ─────────────────────────────────────────────────────────────────────

# training_reset [clean_reports]
# Stop and restart the quickstart cluster.
# If clean_reports=1, also delete report directories (preserves ledger).
training_reset() {
    local clean_reports="${1:-${CLEAN_REPORTS:-0}}"
    local root_dir="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"

    echo "[training] Resetting quickstart cluster..."
    cd "$root_dir"
    docker compose down -v 2>&1 | sed 's/^/  /'
    docker compose up -d 2>&1 | sed 's/^/  /'

    if [ "$clean_reports" = "1" ]; then
        echo "[training] Cleaning report directories (preserving ledger)..."
        local ledger="tests/reports/awareness-training-ledger.jsonl"
        local ledger_backup=""
        if [ -f "$ledger" ]; then
            ledger_backup="$(mktemp)"
            cp "$ledger" "$ledger_backup"
        fi
        find tests/reports -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} + 2>/dev/null || true
        if [ -n "$ledger_backup" ]; then
            mkdir -p tests/reports
            cp "$ledger_backup" "$ledger"
            rm -f "$ledger_backup"
        fi
        echo "[training] Reports cleaned (ledger preserved)."
    fi

    echo "[training] Reset complete."
}
