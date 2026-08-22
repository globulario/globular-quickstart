#!/usr/bin/env bash
# ── host-guard.sh ───────────────────────────────────────────────────────────
# Watch the HOST while a scenario suite runs, and stop the cluster before the
# machine becomes unusable.
#
# Why this exists: on 2026-08-17 three consecutive suite runs froze the
# developer's workstation outright — no OOM kill, no panic, just a machine that
# stopped responding and had to be power-cycled mid-session. The journal for
# each dead boot ends the same way: "Under memory pressure, flushing caches"
# repeating for minutes, then input-handling errors ("your system is too slow"),
# then nothing. That is reclaim thrash, not an OOM: with tmpfs holding the
# memory there is nothing reclaimable to kill, so the kernel spins instead of
# choosing a victim, and the desktop dies with it.
#
# A frozen host loses the whole run AND the evidence. Stopping the containers
# costs one run and keeps both the machine and everything written so far.
#
# The guard only ever *stops* containers — never `down`, never `-v`. State
# volumes survive, so a tripped run stays diagnosable.
#
# Usage:
#   scripts/host-guard.sh &            # alongside a suite
#   MEM_FLOOR_MB=8192 scripts/host-guard.sh &
#
# Env:
#   MEM_FLOOR_MB    trip when MemAvailable falls below this   (default 6144)
#   DISK_FLOOR_MB   trip when / free falls below this         (default 15360)
#   INTERVAL        seconds between samples                   (default 10)
#   GUARD_LOG       sample log path      (default tests/reports/host-guard.log)
#   TRIP_FILE       flag written on trip  (default tests/reports/host-guard.TRIPPED)
# ────────────────────────────────────────────────────────────────────────────
set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1

MEM_FLOOR_MB="${MEM_FLOOR_MB:-6144}"
DISK_FLOOR_MB="${DISK_FLOOR_MB:-15360}"
INTERVAL="${INTERVAL:-10}"
GUARD_LOG="${GUARD_LOG:-tests/reports/host-guard.log}"
TRIP_FILE="${TRIP_FILE:-tests/reports/host-guard.TRIPPED}"

mkdir -p "$(dirname "$GUARD_LOG")"
rm -f "$TRIP_FILE"

# tmpfs is the resource that actually killed the host, and it is invisible in
# the "used" column — it shows up as Shmem. Track it explicitly.
sample() {
    local avail_mb shmem_mb swap_used_mb disk_mb
    avail_mb=$(awk '/^MemAvailable:/{print int($2/1024)}' /proc/meminfo)
    shmem_mb=$(awk '/^Shmem:/{print int($2/1024)}' /proc/meminfo)
    swap_used_mb=$(awk '/^SwapTotal:/{t=$2} /^SwapFree:/{f=$2} END{print int((t-f)/1024)}' /proc/meminfo)
    disk_mb=$(df -Pm / | awk 'NR==2{print $4}')
    echo "$avail_mb $shmem_mb $swap_used_mb $disk_mb"
}

dump_diagnostics() {
    local reason="$1"
    {
        echo "=============================================================="
        echo "HOST GUARD TRIPPED: $reason"
        echo "at: $(date -Is)"
        echo "=============================================================="
        echo "--- /proc/meminfo (selected) ---"
        grep -E "^(MemTotal|MemFree|MemAvailable|Shmem|SwapTotal|SwapFree|Dirty|Writeback):" /proc/meminfo
        echo "--- df -h / ---"
        df -h /
        echo "--- docker stats ---"
        timeout 30 docker stats --no-stream \
            --format "{{.Name}}\t{{.MemUsage}}\t{{.CPUPerc}}\t{{.PIDs}}" 2>&1
        echo "--- per-node tmpfs + /tmp ---"
        for n in 1 2 3 4 5; do
            echo "  node-$n:"
            timeout 15 docker exec "globular-node-$n" sh -c \
                'df -m /tmp /run 2>/dev/null | tail -n +2; du -sm /tmp 2>/dev/null' 2>&1 \
                | sed 's/^/    /'
        done
        echo "--- top host processes by RSS ---"
        ps -eo pid,rss,comm --sort=-rss 2>/dev/null | head -15
    } >> "$GUARD_LOG" 2>&1
}

trip() {
    local reason="$1"
    dump_diagnostics "$reason"
    echo "$reason" > "$TRIP_FILE"
    echo "[host-guard] TRIPPED: $reason — stopping cluster" >&2
    # stop, not down: keep the volumes so the run stays diagnosable.
    timeout 180 docker compose stop >> "$GUARD_LOG" 2>&1
    echo "[host-guard] cluster stopped; see $GUARD_LOG" >&2
}

echo "[host-guard] armed: mem_floor=${MEM_FLOOR_MB}MB disk_floor=${DISK_FLOOR_MB}MB interval=${INTERVAL}s" >&2
echo "# ts avail_mb shmem_mb swap_used_mb disk_free_mb" >> "$GUARD_LOG"

while true; do
    read -r avail shmem swap disk < <(sample)
    echo "$(date +%H:%M:%S) $avail $shmem $swap $disk" >> "$GUARD_LOG"

    if [ "$avail" -lt "$MEM_FLOOR_MB" ]; then
        trip "MemAvailable ${avail}MB < floor ${MEM_FLOOR_MB}MB (Shmem/tmpfs ${shmem}MB)"
        exit 1
    fi
    if [ "$disk" -lt "$DISK_FLOOR_MB" ]; then
        trip "/ free ${disk}MB < floor ${DISK_FLOOR_MB}MB"
        exit 1
    fi
    sleep "$INTERVAL"
done
