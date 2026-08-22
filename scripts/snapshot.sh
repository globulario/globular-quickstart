#!/usr/bin/env bash
set -euo pipefail

# ── snapshot.sh ──────────────────────────────────────────
# Save / restore a converged cluster so scenario work does not pay the full
# Day-0 (~8 min) + serialized joins (~4 min) on every iteration.
#
#   ./scripts/snapshot.sh save      # freeze the current cluster
#   ./scripts/snapshot.sh restore   # return to the frozen cluster (~1 min)
#   ./scripts/snapshot.sh list
#
# WHY THIS COMMITS IMAGES AND NOT JUST VOLUMES
#
# Day-0 installs INTO THE CONTAINER FILESYSTEM, not the state volume:
#   /usr/lib/globular/bin/*        binaries
#   /etc/systemd/system/globular-* unit files
#   /etc/passwd, /etc/scylla/*     users, ScyllaDB config
# None of that lives under /var/lib/globular. A volume-only snapshot therefore
# restores etcd's data directory and the PKI but leaves a container with no
# etcd binary and no unit to start it — verified: globular-etcd came back
# `inactive` with an empty journal.
#
# (The pre-2026-07-31 simulation baked every binary into the image, so volumes
# held only state and a volume-only snapshot would have worked. Once the real
# installer owns installation, container state != volume state.)
#
# So a working snapshot = committed container images + volume archives. That is
# expensive: ~2-3 GB per node image diff plus ~3.6 GB of volumes, ~15 GB total.
# The guard below refuses to run without real headroom, because these land on
# the same disk as the live volumes and one of the scenarios
# (disk-pressure-detection) reads actual free space.
#
# WHAT IS AND IS NOT CAPTURED
#
# Captured — the state that cannot be recreated:
#   etcd/        cluster state, membership, desired versions
#   repository/  published artifacts + ledger
#   pki/ keys/   CA, service certs, Ed25519 signing keys (incl. peer publics)
#   policy/      generated RBAC roles
#   config/ …    everything else under the state root
#
# Excluded — byte-identical to content already in the image, re-hydrated on
# restore rather than stored five times over:
#   packages/    the 57 release .tgz files, copied verbatim from the bundle
#   releases/    the release tarball the gateway serves to joiners
#   staging/     transient per-service extraction dirs
#
# That is ~3 GB/node of redundancy dropped. The founding node otherwise stores
# the same release payload four ways (packages + releases + repository +
# staging), which matters here because snapshots land on the same disk as the
# live volumes.
#
# Restore does NOT re-run the installer: each volume carries
# .quickstart-bootstrap-complete, and bootstrap.sh exits early when it sees it.
# Use `make clean && make up` when you actually want to exercise the install
# path — that is the whole point of this repo and a snapshot must never become
# a way to avoid testing it.

cd "$(dirname "$0")/.."

SNAP_DIR="${SNAP_DIR:-snapshots}"
IMAGE="globulario/globular-node:latest"
NODES=(node-1 node-2 node-3 node-4 node-5)
PROJECT="$(basename "$PWD" | tr -d '.-')"   # compose default project name
VOL_PREFIX="globular-quickstart"

log()  { echo "[snapshot] $*"; }
die()  { echo "[snapshot] FATAL: $*" >&2; exit 1; }

# compose strips the dash: service "node-1" → volume "…_node1-state"
vol_of() { echo "${VOL_PREFIX}_${1//-/}-state"; }

MIN_FREE_GB="${MIN_FREE_GB:-25}"

check_headroom() {
    local free_gb
    free_gb=$(df -BG --output=avail . | tail -1 | tr -dc '0-9')
    if [ "${free_gb:-0}" -lt "$MIN_FREE_GB" ]; then
        die "only ${free_gb}G free; a snapshot needs ~15G and this disk also
       holds the live volumes. Free space first, or override with
       MIN_FREE_GB=<n> if you know what you are doing.
       Rebuilding from scratch (make clean && make up) costs ~12 min and 0 GB."
    fi
    log "disk headroom ok (${free_gb}G free, need ${MIN_FREE_GB}G)"
}

cmd_save() {
    check_headroom
    mkdir -p "$SNAP_DIR"

    # Stop cleanly so etcd checkpoints and Scylla flushes; a snapshot taken
    # from running volumes can capture a torn etcd WAL.
    log "stopping cluster for a consistent snapshot ..."
    docker compose stop >/dev/null 2>&1 || true

    # Commit each container so the INSTALLED filesystem survives (see header).
    for n in "${NODES[@]}"; do
        docker inspect "globular-${n}" >/dev/null 2>&1 || continue
        log "committing globular-${n} filesystem ..."
        docker commit "globular-${n}" "globular-snapshot/${n}:latest" >/dev/null
    done

    for n in "${NODES[@]}"; do
        local v; v=$(vol_of "$n")
        docker volume inspect "$v" >/dev/null 2>&1 || { log "SKIP $n (no volume)"; continue; }
        log "saving $n ..."
        docker run --rm \
            -v "$v":/from:ro \
            -v "$PWD/$SNAP_DIR":/to \
            alpine:3.20 \
            tar czf "/to/${n}.tar.gz" -C /from \
                --exclude=./packages \
                --exclude=./releases \
                --exclude=./staging \
                . 2>/dev/null
        log "  $(du -h "$SNAP_DIR/${n}.tar.gz" | cut -f1)"
    done

    # The join-token handoff volume is tiny but restoring without it leaves
    # joiners unable to find a token if anything re-runs.
    if docker volume inspect "${VOL_PREFIX}_cluster-handoff" >/dev/null 2>&1; then
        docker run --rm \
            -v "${VOL_PREFIX}_cluster-handoff":/from:ro \
            -v "$PWD/$SNAP_DIR":/to \
            alpine:3.20 tar czf /to/cluster-handoff.tar.gz -C /from . 2>/dev/null
    fi

    # Compose override pinning each service to its committed image. Restore
    # layers this on top of docker-compose.yml so the nodes come back with the
    # installed filesystem instead of the bare base image.
    {
        echo "# Generated by scripts/snapshot.sh — do not edit."
        echo "# Pins each node to its committed post-install filesystem."
        echo "services:"
        for n in "${NODES[@]}"; do
            echo "  ${n}:"
            echo "    image: globular-snapshot/${n}:latest"
            echo "    build: !reset null"
        done
    } > "$SNAP_DIR/docker-compose.snapshot.yml"

    date -Iseconds > "$SNAP_DIR/.taken-at"
    log "restarting cluster ..."
    docker compose start >/dev/null 2>&1 || true
    log "snapshot complete: $(du -sh "$SNAP_DIR" | cut -f1) volumes + committed images"
    log "images: $(docker images 'globular-snapshot/*' --format '{{.Size}}' | tr '\n' ' ')"
}

cmd_restore() {
    [ -f "$SNAP_DIR/node-1.tar.gz" ] || die "no snapshot in $SNAP_DIR (run: $0 save)"
    log "restoring snapshot taken $(cat "$SNAP_DIR/.taken-at" 2>/dev/null || echo unknown)"

    log "removing current cluster and volumes ..."
    docker compose down -v >/dev/null 2>&1 || true

    for n in "${NODES[@]}"; do
        [ -f "$SNAP_DIR/${n}.tar.gz" ] || { log "SKIP $n (not in snapshot)"; continue; }
        local v; v=$(vol_of "$n")
        docker volume create "$v" >/dev/null
        log "restoring $n ..."
        docker run --rm \
            -v "$v":/to \
            -v "$PWD/$SNAP_DIR":/from:ro \
            alpine:3.20 \
            sh -c "cd /to && tar xzf /from/${n}.tar.gz" 2>/dev/null

        # Re-hydrate the excluded, image-identical content. Done from the image
        # itself so the restored tree matches what Day-0 produced, rather than
        # whatever happens to be on the build host.
        # --entrypoint sh is required: the image's ENTRYPOINT is entrypoint.sh,
        # so without it the shell command arrives as ARGUMENTS to entrypoint.sh,
        # which demands GLOBULAR_NODE_NAME et al and exits before doing anything.
        docker run --rm --entrypoint sh -v "$v":/state "$IMAGE" -c '
            set -e
            ver="${GLOBULAR_RELEASE_VERSION}"
            tgz="/opt/globular/release/globular-${ver}-linux-amd64.tar.gz"
            [ -f "$tgz" ] || { echo "  WARN: no release tarball in image"; exit 0; }
            tmp=$(mktemp -d)
            tar xzf "$tgz" -C "$tmp" --strip-components=1 --no-same-owner
            mkdir -p /state/packages /state/staging
            cp "$tmp"/packages/*.tgz /state/packages/ 2>/dev/null || true
            # releases/ is only served by the founder gateway, but restoring it
            # everywhere is harmless and keeps a re-joined node self-sufficient.
            mkdir -p "/state/releases/${ver}"
            cp "$tgz" "/state/releases/${ver}/" 2>/dev/null || true
            [ -f "${tgz}.sha256" ] && cp "${tgz}.sha256" "/state/releases/${ver}/" || true
            chown -R 10001:10001 /state/packages /state/releases /state/staging 2>/dev/null || true
            rm -rf "$tmp"
        ' >/dev/null 2>&1 || log "  WARN: re-hydration failed for $n"
    done

    if [ -f "$SNAP_DIR/cluster-handoff.tar.gz" ]; then
        docker volume create "${VOL_PREFIX}_cluster-handoff" >/dev/null
        docker run --rm \
            -v "${VOL_PREFIX}_cluster-handoff":/to \
            -v "$PWD/$SNAP_DIR":/from:ro \
            alpine:3.20 sh -c 'cd /to && tar xzf /from/cluster-handoff.tar.gz' 2>/dev/null
    fi

    log "starting cluster from committed images ..."
    [ -f "$SNAP_DIR/docker-compose.snapshot.yml" ] \
        || die "snapshot has no compose override — it predates the image-commit
       fix and cannot restore a working cluster (volumes alone leave nodes with
       no binaries and no units). Re-take it with: $0 save"
    docker compose -f docker-compose.yml -f "$SNAP_DIR/docker-compose.snapshot.yml" \
        up -d >/dev/null 2>&1
    log "restored. Services are starting; give etcd ~30-60s to form."
    log "verify with: ./tests/harness/bin/globular-test cluster wait 300"
    log "NOTE: the cluster is now running committed images, not a fresh build."
    log "      Use 'make clean && make up' to return to the real install path."
}

cmd_list() {
    [ -d "$SNAP_DIR" ] || { echo "no snapshots"; return; }
    echo "snapshot taken: $(cat "$SNAP_DIR/.taken-at" 2>/dev/null || echo unknown)"
    du -sh "$SNAP_DIR"/*.tar.gz 2>/dev/null || echo "(empty)"
    echo "total: $(du -sh "$SNAP_DIR" 2>/dev/null | cut -f1)"
}

case "${1:-}" in
    save)    cmd_save ;;
    restore) cmd_restore ;;
    list)    cmd_list ;;
    *)       echo "usage: $0 {save|restore|list}" >&2; exit 2 ;;
esac
