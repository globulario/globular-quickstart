#!/usr/bin/env bash
# certify-release.sh — run every scenario suite against ONE release and leave a
# re-checkable record of what happened.
#
# WHY THIS EXISTS AS A SCRIPT
#
# `make test-v1-certification` runs seven suites back-to-back on whatever cluster
# happens to be up. That is not a certification: the suites that stop nodes, wipe
# etcd and clone identities leave the cluster damaged, so every suite after one of
# them runs against a cluster the previous suite broke, and a failure cannot be
# attributed. The campaign practice has been to cold-boot before each destructive
# suite; this script is that practice written down instead of remembered.
#
# WHAT IT GUARANTEES
#
#   * every suite runs, even after one fails — a red suite must not hide the
#     state of the ones behind it
#   * the destructive suites each start from a cold boot through the real
#     installer (make clean && make up), never from a snapshot
#   * every suite's stdout lands in .runlogs/<version>-<suite>.log
#   * the proof table is regenerated at the end from the evidence bundles, so the
#     claim and the evidence cannot drift apart
#
# WHAT DECIDES THE VERDICT
#
# Not the suite exit codes. `patterns` exits non-zero on every healthy run,
# because residue-negative-control is SUPPOSED to fail — it is the negative
# control for the restoration law, and a green result there would mean the law is
# not enforced. Only globular-proof knows which non-PASS results are declared
# expected (EXPECTED_NOT_PASS) and which are a control that has itself broken, so
# the campaign verdict is its exit code. The per-suite exit codes below are a
# screening signal, printed so nothing is hidden, never the judgement.
#
# Usage:
#   bash scripts/certify-release.sh 1.2.360
#   SUITES="authority catastrophic" bash scripts/certify-release.sh 1.2.360
#
# Exit code is the number of suites that did not pass (0 = clean run).

set -uo pipefail

VERSION="${1:-${RELEASE_VERSION:-}}"
if [[ -z "$VERSION" ]]; then
    echo "usage: $0 <release-version>   (e.g. $0 1.2.360)" >&2
    exit 2
fi

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO"
LOGS="$REPO/.runlogs"
mkdir -p "$LOGS"

# Suites that only read, or whose mutations the runner reverses, share one
# cluster. Suites that deliberately break the cluster get their own cold boot.
NON_DESTRUCTIVE_DEFAULT="smoke functional security patterns training soak"
DESTRUCTIVE_DEFAULT="recovery resilience upgrade authority catastrophic"

read -ra NON_DESTRUCTIVE <<< "${NON_DESTRUCTIVE_SUITES:-$NON_DESTRUCTIVE_DEFAULT}"
read -ra DESTRUCTIVE <<< "${DESTRUCTIVE_SUITES:-$DESTRUCTIVE_DEFAULT}"
if [[ -n "${SUITES:-}" ]]; then
    # Explicit list: every named suite gets its own cold boot, because the caller
    # has not told us which of them are safe to share one.
    read -ra DESTRUCTIVE <<< "$SUITES"
    NON_DESTRUCTIVE=()
fi

TEST_BIN="$REPO/tests/harness/bin/globular-test"
FAILED=()

# CAMPAIGN_START stamps when this run began, in the same format the report
# directories use (20260903T170000-<suite>). It is what lets the check at the end
# prove that every row in the proof table came from THIS release: globular-proof
# takes the latest result per scenario across every report directory ever made,
# so a scenario that silently did not run would keep showing its result from an
# older release and the table would quietly mix two subjects.
CAMPAIGN_START="$(date -u +%Y%m%dT%H%M%S)"

log() { printf '%s  %s\n' "$(date -u +%H:%M:%S)" "$*"; }

# build_image — stage the release tarball and build the node image ONCE.
#
# `make up` would do this on every cold boot, but `make build` ends in
# prune-cache, which drops the BuildKit cache the next build would have reused —
# so every boot would re-unpack a 766 MB tarball and re-run the image build for
# an image that has not changed. The image is a function of the release, and the
# release is fixed for the whole campaign.
build_image() {
    local img_log="$LOGS/image-${VERSION}.log"
    log "building the node image for ${VERSION} → ${img_log}"
    # `make up` normally runs this; the cold boots below call docker compose
    # directly, so the host budget is checked once here instead. A short
    # fs.aio-max-nr does not fail visibly — ScyllaDB crash-loops and every
    # service waiting on :9042 strands, hours into a campaign.
    # release/ is COPYied wholesale into the image, so a tarball left there by an
    # earlier campaign is 766 MB of another release shipped inside this one's
    # image — and two candidate bundles where the proof needs exactly one.
    find release -maxdepth 1 -name 'globular-*-linux-amd64.tar.gz*' \
        ! -name "globular-${VERSION}-linux-amd64.tar.gz*" -delete 2>/dev/null || true
    make check-host-aio >"$img_log" 2>&1 || return 1
    make build RELEASE_VERSION="$VERSION" >>"$img_log" 2>&1
}

# cold_boot — destroy the cluster and rebuild it through the real install path.
# The image is already built; what is exercised here is the installer inside it,
# which is the part that must not be short-circuited.
# Returns non-zero if Day-0 does not finish on all five nodes in time.
cold_boot() {
    local tag="$1"
    local boot_log="$LOGS/coldboot-${VERSION}-${tag}.log"
    log "cold boot for ${tag} → ${boot_log}"
    {
        docker compose down -v
        docker compose up -d
    } >"$boot_log" 2>&1

    # Day-0 is what we are waiting for, not the containers: a container is up
    # seconds after `up`, while the install it runs takes ~10 minutes.
    local deadline=$((SECONDS + 1800))
    while (( SECONDS < deadline )); do
        local done_count=0
        for n in 1 2 3 4 5; do
            if docker exec "globular-node-$n" test -f /var/lib/globular/.quickstart-bootstrap-complete 2>/dev/null; then
                done_count=$((done_count + 1))
            fi
        done
        printf '%s bootstrap-complete=%d/5\n' "$(date -u +%H:%M:%S)" "$done_count" >>"$boot_log"
        if (( done_count == 5 )); then
            log "cold boot complete for ${tag}"
            # Day-0 finishing is not the same as the cluster being ready to be
            # asserted against; let the harness's own readiness gate say so.
            "$TEST_BIN" cluster wait 600 >>"$boot_log" 2>&1
            return $?
        fi
        sleep 20
    done
    log "COLD BOOT TIMED OUT for ${tag} — see ${boot_log}"
    return 1
}

run_suite() {
    local suite="$1"
    local out="$LOGS/${VERSION}-${suite}.log"
    log "suite ${suite} → ${out}"
    "$TEST_BIN" suite "$suite" >"$out" 2>&1
    local rc=$?
    echo "EXIT=$rc" >>"$out"
    if (( rc != 0 )); then
        log "suite ${suite} FAILED (exit ${rc})"
        FAILED+=("$suite")
    else
        log "suite ${suite} passed"
    fi
    return 0   # never abort the campaign on one red suite
}

log "=== certification run for ${VERSION} ==="

if ! build_image; then
    log "FATAL: the node image for ${VERSION} could not be built — see $LOGS/image-${VERSION}.log"
    exit 99
fi

if ((${#NON_DESTRUCTIVE[@]})); then
    if cold_boot "shared"; then
        for suite in "${NON_DESTRUCTIVE[@]}"; do run_suite "$suite"; done
    else
        log "shared cold boot failed — recording every shared suite as failed"
        for suite in "${NON_DESTRUCTIVE[@]}"; do FAILED+=("$suite (cold boot failed)"); done
    fi
fi

for suite in "${DESTRUCTIVE[@]}"; do
    if cold_boot "$suite"; then
        run_suite "$suite"
    else
        log "cold boot failed before ${suite}"
        FAILED+=("$suite (cold boot failed)")
    fi
done

log "=== regenerating the proof table from the evidence bundles ==="
"$REPO/tests/harness/bin/globular-proof" >"$LOGS/${VERSION}-proof.log" 2>&1
PROOF_RC=$?

echo
log "=== ${VERSION}: ${#FAILED[@]} suite(s) exited non-zero (screening) ==="
for f in "${FAILED[@]:-}"; do [[ -n "$f" ]] && echo "  non-zero  $f"; done
# Every row must come from this campaign. A row older than CAMPAIGN_START means
# that scenario did not run now, and its result belongs to a different release.
STALE=$(python3 - "$REPO/tests/PROOF.json" "$CAMPAIGN_START" <<'PY'
import json, sys
rows = json.load(open(sys.argv[1])).get("rows", [])
start = sys.argv[2]
stale = [r for r in rows if (r.get("run") or "") [:15] < start]
for r in stale:
    print(f"  STALE  {r.get('suite')}/{r.get('scenario')} — result from {r.get('run') or 'NO EVIDENCE'}")
sys.exit(1 if stale else 0)
PY
)
STALE_RC=$?
if (( STALE_RC != 0 )); then
    log "PROOF TABLE IS NOT SCOPED TO THIS RUN — these rows predate ${CAMPAIGN_START}:"
    echo "$STALE"
    log "Those scenarios did not run in this campaign; their rows describe another release."
fi

echo
if (( PROOF_RC == 0 && STALE_RC == 0 )); then
    log "PROOF CLEAN: every scenario is PASS or a declared expected-fail — tests/PROOF.md"
elif (( PROOF_RC == 0 )); then
    log "every scenario PASSed or is a declared expected-fail, but the table is not scoped to this run (see STALE above)"
else
    log "PROOF NOT CLEAN (globular-proof exit ${PROOF_RC}) — the rows that need work:"
    # globular-proof reports only a summary line on stderr; the rows are the
    # table it just wrote. ❌ marks NEEDS_WORK and 🚨 a control that itself broke.
    grep -E '❌|🚨' "$REPO/tests/PROOF.md" | head -20
fi
(( PROOF_RC != 0 )) && exit "$PROOF_RC"
exit "$STALE_RC"
