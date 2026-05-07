#!/usr/bin/env bash
# awareness.sh — awareness evidence collection for the Globular test harness
#
# Functions:
#   awareness_available               — returns 0 if globular awareness works
#   awareness_write_skipped           — write SKIPPED.txt
#   awareness_preflight               — preflight report (agent + json)
#   awareness_debug_session           — debug-session report (agent + json)
#   awareness_runtime_snapshot        — runtime snapshot JSON
#   awareness_did_we_fix              — did-we-fix ledger lookup
#   awareness_node_context_for_files  — per-file graph context
#   awareness_semantic_paths          — best-effort semantic path evidence
#   awareness_incident_from_failure   — create incident bundle (on failure)
#   awareness_propose_from_incident   — generate draft proposal (training only)
#
# Environment variables:
#   AWARENESS_REQUIRED=1         fail scenario if awareness is unavailable
#   AWARENESS_REPO=<path>        path to services repo for --repo flag
#   AWARENESS_GLOBULAR_BIN=<bin> override globular binary path
#
# All functions degrade gracefully.  Awareness failures never fail a scenario
# unless AWARENESS_REQUIRED=1.  All errors are appended to awareness-errors.log.

AWARENESS_REQUIRED="${AWARENESS_REQUIRED:-0}"

# ── binary resolution ──────────────────────────────────────────────────────────

# _awareness_bin
# Print the globular binary path to use.
# Prefers AWARENESS_GLOBULAR_BIN if set and has awareness support.
_awareness_bin() {
    local custom="${AWARENESS_GLOBULAR_BIN:-}"
    if [ -n "$custom" ] && command -v "$custom" >/dev/null 2>&1; then
        if "$custom" awareness --help >/dev/null 2>&1; then
            printf '%s' "$custom"
            return 0
        fi
    fi
    if command -v globular >/dev/null 2>&1 && \
       globular awareness --help >/dev/null 2>&1; then
        printf 'globular'
        return 0
    fi
    return 1
}

# awareness_available
# Returns 0 if globular awareness is reachable.
awareness_available() {
    _awareness_bin >/dev/null 2>&1
}

# ── directory helpers ──────────────────────────────────────────────────────────

# _awareness_dir <out_dir>
# Print the awareness subdirectory path and create it.
_awareness_dir() {
    local d="$1/awareness"
    mkdir -p "$d"
    printf '%s' "$d"
}

# _awareness_log_error <adir> <label> <message>
# Append an error line to awareness-errors.log.
_awareness_log_error() {
    local adir="$1" label="$2" msg="$3"
    printf '[%s] %s: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$label" "$msg" \
        >> "$adir/awareness-errors.log"
}

# ── guard helpers ──────────────────────────────────────────────────────────────

# awareness_write_skipped <out_dir> [reason]
# Write SKIPPED.txt into the awareness directory.
awareness_write_skipped() {
    local out_dir="$1"
    local reason="${2:-awareness not available}"
    local adir
    adir="$(_awareness_dir "$out_dir")"
    printf 'Awareness skipped: %s\nTimestamp: %s\n' \
        "$reason" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
        > "$adir/SKIPPED.txt"
    echo "  [awareness] SKIPPED: $reason"
}

# _awareness_guard <out_dir>
# Returns 0 if available, 1 if unavailable+skipped, 2 if unavailable+required.
_awareness_guard() {
    local out_dir="$1"
    if awareness_available; then
        return 0
    fi
    if [ "${AWARENESS_REQUIRED:-0}" = "1" ]; then
        echo "  [awareness] ERROR: globular awareness unavailable and AWARENESS_REQUIRED=1" >&2
        return 2
    fi
    awareness_write_skipped "$out_dir" "globular awareness not available"
    return 1
}

# _awareness_repo_args
# Print --repo <path> if AWARENESS_REPO is set.
_awareness_repo_args() {
    [ -n "${AWARENESS_REPO:-}" ] && printf -- '--repo %s' "$AWARENESS_REPO"
}

# _awareness_run_cmd <label> <adir> <out_file> <cmd...>
# Run cmd, redirect stdout to out_file.
# On failure: warn to stderr and append error to awareness-errors.log.
_awareness_run_cmd() {
    local label="$1" adir="$2" out_file="$3"
    shift 3
    local stderr_tmp
    stderr_tmp="$(mktemp)"
    if "$@" > "$out_file" 2>"$stderr_tmp"; then
        rm -f "$stderr_tmp"
    else
        local rc=$?
        local err_msg
        err_msg="$(cat "$stderr_tmp" 2>/dev/null | tail -3 | tr '\n' ' ')"
        rm -f "$stderr_tmp"
        echo "  [awareness] WARNING: $label exited $rc (continuing)" >&2
        _awareness_log_error "$adir" "$label" "exit $rc: $err_msg"
    fi
}

# ── core functions ─────────────────────────────────────────────────────────────

# awareness_preflight <task> <phase> <out_dir> [include_runtime] [runtime_window]
# Write:  awareness/preflight.agent.txt
#         awareness/preflight.json
awareness_preflight() {
    local task="$1" phase="${2:-}" out_dir="$3"
    local include_runtime="${4:-${AWARENESS_INCLUDE_RUNTIME:-0}}"
    local runtime_window="${5:-${AWARENESS_RUNTIME_WINDOW:-30m}}"

    local adir rc
    adir="$(_awareness_dir "$out_dir")"
    _awareness_guard "$out_dir"; rc=$?
    [ "$rc" -eq 1 ] && return 0
    [ "$rc" -eq 2 ] && return 1

    local bin; bin="$(_awareness_bin)"
    echo "  [awareness] preflight: ${task} (phase: ${phase:-default})"

    local extra_args=()
    [ -n "$phase" ] && extra_args+=(--phase "$phase")
    [ "$include_runtime" = "1" ] && extra_args+=(--include-runtime --runtime-window "$runtime_window")
    # shellcheck disable=SC2046
    [ -n "${AWARENESS_REPO:-}" ] && extra_args+=($(printf -- '--repo %s' "$AWARENESS_REPO"))

    _awareness_run_cmd "preflight(agent)" "$adir" "$adir/preflight.agent.txt" \
        "$bin" awareness preflight --task "$task" --format agent "${extra_args[@]}"

    _awareness_run_cmd "preflight(json)" "$adir" "$adir/preflight.json" \
        "$bin" awareness preflight --task "$task" --format json "${extra_args[@]}"
}

# awareness_debug_session <task> <phase> <out_dir> [include_runtime] [runtime_window]
# Write:  awareness/debug-session.agent.txt
#         awareness/debug-session.json
awareness_debug_session() {
    local task="$1" phase="${2:-}" out_dir="$3"
    local include_runtime="${4:-${AWARENESS_INCLUDE_RUNTIME:-0}}"
    local runtime_window="${5:-${AWARENESS_RUNTIME_WINDOW:-30m}}"

    local adir rc
    adir="$(_awareness_dir "$out_dir")"
    _awareness_guard "$out_dir"; rc=$?
    [ "$rc" -eq 1 ] && return 0
    [ "$rc" -eq 2 ] && return 1

    local bin; bin="$(_awareness_bin)"
    echo "  [awareness] debug-session: $task"

    local extra_args=()
    [ -n "$phase" ] && extra_args+=(--phase "$phase")
    [ "$include_runtime" = "1" ] && extra_args+=(--include-runtime --runtime-window "$runtime_window")
    [ -n "${AWARENESS_REPO:-}" ] && extra_args+=(--repo "${AWARENESS_REPO}")

    _awareness_run_cmd "debug-session(agent)" "$adir" "$adir/debug-session.agent.txt" \
        "$bin" awareness debug-session --task "$task" --format agent "${extra_args[@]}"

    _awareness_run_cmd "debug-session(json)" "$adir" "$adir/debug-session.json" \
        "$bin" awareness debug-session --task "$task" --format json "${extra_args[@]}"
}

# awareness_runtime_snapshot <out_dir> [window]
# Write:  awareness/runtime-snapshot.json   (or .error.txt on failure)
awareness_runtime_snapshot() {
    local out_dir="$1"
    local window="${2:-${AWARENESS_RUNTIME_WINDOW:-30m}}"

    local adir rc
    adir="$(_awareness_dir "$out_dir")"
    _awareness_guard "$out_dir"; rc=$?
    [ "$rc" -eq 1 ] && return 0
    [ "$rc" -eq 2 ] && return 1

    local bin; bin="$(_awareness_bin)"
    echo "  [awareness] runtime-snapshot (window: $window)"

    local snap_file="$adir/runtime-snapshot.json"
    local stderr_tmp; stderr_tmp="$(mktemp)"

    local extra_args=()
    [ -n "${AWARENESS_REPO:-}" ] && extra_args+=(--repo "${AWARENESS_REPO}")

    if "$bin" awareness runtime-snapshot --format json --window "$window" \
            "${extra_args[@]}" > "$snap_file" 2>"$stderr_tmp"; then
        rm -f "$stderr_tmp"
    else
        local rc=$?
        local err_msg; err_msg="$(cat "$stderr_tmp" 2>/dev/null | tail -3 | tr '\n' ' ')"
        rm -f "$stderr_tmp"
        local err_file="$adir/runtime-snapshot.error.txt"
        mv "$snap_file" "$err_file" 2>/dev/null || true
        printf 'runtime-snapshot exited %s: %s\n' "$rc" "$err_msg" >> "$err_file"
        _awareness_log_error "$adir" "runtime-snapshot" "exit $rc"
        echo "  [awareness] WARNING: runtime-snapshot unavailable (see runtime-snapshot.error.txt)"
    fi
}

# awareness_did_we_fix <task> <out_dir>
# Write:  awareness/did-we-fix.txt
awareness_did_we_fix() {
    local task="$1" out_dir="$2"

    local adir rc
    adir="$(_awareness_dir "$out_dir")"
    _awareness_guard "$out_dir"; rc=$?
    [ "$rc" -eq 1 ] && return 0
    [ "$rc" -eq 2 ] && return 1

    local bin; bin="$(_awareness_bin)"
    echo "  [awareness] did-we-fix: $task"

    local extra_args=()
    [ -n "${AWARENESS_REPO:-}" ] && extra_args+=(--repo "${AWARENESS_REPO}")

    _awareness_run_cmd "did-we-fix" "$adir" "$adir/did-we-fix.txt" \
        "$bin" awareness did-we-fix --task "$task" "${extra_args[@]}"
}

# awareness_node_context_for_files <files_csv> <out_dir>
# For each file in comma-separated list, run node-context and write output.
# Writes under awareness/node-context/<basename>.agent.txt
awareness_node_context_for_files() {
    local files_csv="$1" out_dir="$2"

    local adir rc
    adir="$(_awareness_dir "$out_dir")"
    _awareness_guard "$out_dir"; rc=$?
    [ "$rc" -eq 1 ] && return 0
    [ "$rc" -eq 2 ] && return 1

    local nc_dir="$adir/node-context"
    mkdir -p "$nc_dir"

    if [ -z "$files_csv" ]; then
        echo "  [awareness] node-context: no files specified"
        return 0
    fi

    local bin; bin="$(_awareness_bin)"
    local extra_args=()
    [ -n "${AWARENESS_REPO:-}" ] && extra_args+=(--repo "${AWARENESS_REPO}")

    local IFS=','
    for file in $files_csv; do
        file="${file#"${file%%[![:space:]]*}"}"   # trim leading space
        file="${file%"${file##*[![:space:]]}"}"    # trim trailing space
        [ -z "$file" ] && continue

        local outname
        outname="$(basename "$file" | tr '/' '_').agent.txt"
        echo "  [awareness] node-context: $file"
        _awareness_run_cmd "node-context($file)" "$adir" "$nc_dir/$outname" \
            "$bin" awareness node-context --file "$file" --zoom all --format agent \
            "${extra_args[@]}"
    done
}

# awareness_semantic_paths <task> <out_dir>
# Best-effort: find semantic paths from debug-session evidence.
# Writes under awareness/semantic-paths/
awareness_semantic_paths() {
    local task="$1" out_dir="$2"

    local adir rc
    adir="$(_awareness_dir "$out_dir")"
    _awareness_guard "$out_dir"; rc=$?
    [ "$rc" -eq 1 ] && return 0
    [ "$rc" -eq 2 ] && return 1

    local sp_dir="$adir/semantic-paths"
    mkdir -p "$sp_dir"

    local bin; bin="$(_awareness_bin)"
    local extra_args=()
    [ -n "${AWARENESS_REPO:-}" ] && extra_args+=(--repo "${AWARENESS_REPO}")

    # Try to run semantic-neighborhood for the task description as a node reference.
    # This is best-effort: if the task isn't a graph node ID it will degrade gracefully.
    echo "  [awareness] semantic-paths: $task"
    _awareness_run_cmd "semantic-paths(neighborhood)" "$adir" \
        "$sp_dir/neighborhood.agent.txt" \
        "$bin" awareness semantic-neighborhood --from "$task" --format agent \
        "${extra_args[@]}" 2>/dev/null || true

    # If debug-session.json has root-cause service nodes, run path between them.
    local dbs_json="$adir/debug-session.json"
    if [ -f "$dbs_json" ]; then
        local nodes
        nodes=$(python3 -c "
import json, sys
try:
    d = json.load(open('$dbs_json'))
    nodes = []
    for item in (d.get('root_cause_paths') or d.get('ranked_paths') or []):
        if isinstance(item, dict):
            n = item.get('from') or item.get('node')
            if n: nodes.append(n)
    print('\n'.join(nodes[:3]))
except Exception:
    pass
" 2>/dev/null || true)
        if [ -n "$nodes" ]; then
            local prev=""
            while IFS= read -r node; do
                [ -z "$node" ] && continue
                if [ -n "$prev" ]; then
                    local slug
                    slug="$(printf '%s_to_%s' "$prev" "$node" | tr '/:. ' '____' | cut -c1-40)"
                    _awareness_run_cmd "semantic-path($prev→$node)" "$adir" \
                        "$sp_dir/path_${slug}.agent.txt" \
                        "$bin" awareness path --from "$prev" --to "$node" --format agent \
                        "${extra_args[@]}" 2>/dev/null || true
                fi
                prev="$node"
            done <<< "$nodes"
        fi
    fi
}

# awareness_incident_from_failure <task> <out_dir>
# Call only on failure.
# Writes: awareness/incident.yaml  (or incident.error.txt)
#         awareness/incident.log
awareness_incident_from_failure() {
    local task="$1" out_dir="$2"

    local adir rc
    adir="$(_awareness_dir "$out_dir")"
    _awareness_guard "$out_dir"; rc=$?
    [ "$rc" -eq 1 ] && return 0
    [ "$rc" -eq 2 ] && return 1

    local bin; bin="$(_awareness_bin)"
    echo "  [awareness] creating incident from failure"

    local extra_args=()
    [ -n "${AWARENESS_REPO:-}" ] && extra_args+=(--repo "${AWARENESS_REPO}")

    local log_file="$adir/incident.log"
    if ! "$bin" awareness incident-from-runtime --task "$task" \
            "${extra_args[@]}" > "$log_file" 2>&1; then
        mv "$log_file" "$adir/incident.error.txt" 2>/dev/null || true
        _awareness_log_error "$adir" "incident-from-runtime" "command failed"
        echo "  [awareness] WARNING: incident-from-runtime failed (see incident.error.txt)"
        return 0
    fi

    local bundle_path
    bundle_path=$(grep -o 'incident bundle written:.*' "$log_file" \
        | sed 's/incident bundle written:[[:space:]]*//' \
        | tr -d '[:space:]' || true)

    if [ -n "$bundle_path" ] && [ -f "$bundle_path" ]; then
        cp "$bundle_path" "$adir/incident.yaml"
        echo "  [awareness] incident bundle: $bundle_path"
    else
        _awareness_log_error "$adir" "incident-from-runtime" \
            "could not locate bundle file (see incident.log)"
        echo "  [awareness] WARNING: could not locate incident bundle (see incident.log)"
    fi
}

# awareness_propose_from_incident <out_dir>
# Training mode only — generate a draft proposal from the incident bundle.
# NEVER approves or promotes.  Draft only.
# Writes: awareness/proposal.yaml  (or proposal.error.txt)
awareness_propose_from_incident() {
    local out_dir="$1"

    local adir rc
    adir="$(_awareness_dir "$out_dir")"
    _awareness_guard "$out_dir"; rc=$?
    [ "$rc" -eq 1 ] && return 0
    [ "$rc" -eq 2 ] && return 1

    local incident_file="$adir/incident.yaml"
    if [ ! -f "$incident_file" ]; then
        echo "  [awareness] propose: no incident.yaml — skipping proposal"
        return 0
    fi

    # Extract incident_id from the bundle YAML.
    local incident_id
    incident_id=$(grep -E '^incident_id:' "$incident_file" \
        | sed 's/^incident_id:[[:space:]]*//' \
        | tr -d '"'"'" | tr -d '[:space:]' || true)

    if [ -z "$incident_id" ]; then
        _awareness_log_error "$adir" "propose-from-incident" \
            "could not extract incident_id from incident.yaml"
        echo "  [awareness] WARNING: no incident_id in incident.yaml — skipping proposal"
        return 0
    fi

    local bin; bin="$(_awareness_bin)"
    echo "  [awareness] propose-from-incident: $incident_id"

    local extra_args=()
    [ -n "${AWARENESS_REPO:-}" ] && extra_args+=(--repo "${AWARENESS_REPO}")

    local log_file="$adir/proposal.log"
    if ! "$bin" awareness propose-from-incident --incident "$incident_id" \
            "${extra_args[@]}" > "$log_file" 2>&1; then
        mv "$log_file" "$adir/proposal.error.txt" 2>/dev/null || true
        _awareness_log_error "$adir" "propose-from-incident" "command failed"
        echo "  [awareness] WARNING: propose-from-incident failed (see proposal.error.txt)"
        return 0
    fi

    # Locate the written proposal file (newest yaml in proposals dir).
    local proposal_path
    proposal_path=$(grep -oE '[^ ]+\.yaml' "$log_file" | head -1 || true)
    if [ -z "$proposal_path" ]; then
        # Scan proposals dir for the newest file.
        local proposals_dir
        proposals_dir="$(${AWARENESS_REPO:+$AWARENESS_REPO/}docs/awareness/proposals 2>/dev/null || \
            git rev-parse --show-toplevel 2>/dev/null)/docs/awareness/proposals"
        proposal_path=$(ls -t "$proposals_dir"/*.yaml 2>/dev/null | head -1 || true)
    fi

    if [ -n "$proposal_path" ] && [ -f "$proposal_path" ]; then
        cp "$proposal_path" "$adir/proposal.yaml"
        echo "  [awareness] proposal (DRAFT): $proposal_path"
        echo "  [awareness] NOTE: proposal is DRAFT only — do not promote from lab runner"
    else
        _awareness_log_error "$adir" "propose-from-incident" \
            "could not locate proposal file (see proposal.log)"
        echo "  [awareness] WARNING: proposal file not found (see proposal.log)"
    fi
}
