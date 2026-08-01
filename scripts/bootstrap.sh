#!/bin/bash
set -euo pipefail

# ── bootstrap.sh ─────────────────────────────────────────
# Runs under systemd, after the machine has booted. Plays the part of the
# human operator, and nothing else:
#
#   founding node   → unpack the release, run install.sh (Day-0), then
#                     `globular cluster bootstrap`, then publish a join token
#   joining node    → fetch the join script from the founder's gateway and
#                     run it with that token — the real Day-1 path
#
# Every Globular action below is a documented operator command. This script
# must never seed etcd, mint certificates, render unit files, or write
# desired state: those belong to install-day0.sh and the join script, and
# reproducing them here is exactly the drift that made the old simulation
# validate a cluster no operator ever builds.

STATE=/var/lib/globular
MARKER="$STATE/.quickstart-bootstrap-complete"
HANDOFF=/shared/cluster
RELEASE_DIR=/opt/globular/release

NODE_NAME="${GLOBULAR_NODE_NAME:?}"
NODE_IP="${GLOBULAR_NODE_IP:?}"
ROLE="${GLOBULAR_ROLE:?}"
PROFILES="${GLOBULAR_PROFILES:-core}"
CONTROLLER_IP="${GLOBULAR_CONTROLLER_IP:-}"
CLUSTER_DOMAIN="${GLOBULAR_CLUSTER_DOMAIN:-globular.internal}"
VERSION="${GLOBULAR_RELEASE_VERSION:?}"

RELEASE_NAME="globular-${VERSION}-linux-amd64"
TARBALL="$RELEASE_DIR/${RELEASE_NAME}.tar.gz"
BUNDLE="$RELEASE_DIR/${RELEASE_NAME}"

log()  { echo "[bootstrap] $*"; }
die()  { echo "[bootstrap] FATAL: $*" >&2; exit 1; }

if [ -f "$MARKER" ]; then
    log "already bootstrapped ($(cat "$MARKER")) — nothing to do"
    exit 0
fi

# ── unpack the release (both roles verify the checksum) ──
unpack_release() {
    [ -d "$BUNDLE" ] && { log "release already unpacked"; return; }
    [ -f "$TARBALL" ] || die "release tarball not found: $TARBALL"

    if [ -f "${TARBALL}.sha256" ]; then
        log "verifying ${RELEASE_NAME}.tar.gz ..."
        # The .sha256 may name a path from the build host; compare digests only.
        local expected actual
        expected=$(awk '{print $1}' "${TARBALL}.sha256")
        actual=$(sha256sum "$TARBALL" | awk '{print $1}')
        [ "$expected" = "$actual" ] \
            || die "release checksum mismatch (expected $expected, got $actual)"
        log "checksum ok"
    else
        log "WARN: no .sha256 alongside the tarball — skipping verification"
    fi

    log "unpacking release ${VERSION} ..."
    mkdir -p "$BUNDLE"
    # --no-same-owner: extract as root rather than preserving the build host's
    # UIDs. install-day0.sh infers the installing operator from the release
    # directory's owner (stat -c '%U'), and a UID with no passwd entry in this
    # container resolves to the literal string "UNKNOWN" — which then reaches
    # `chown UNKNOWN:UNKNOWN` and aborts Day-0 on client-cert generation.
    # A root-owned tree is what `sudo tar x` of a root-downloaded release
    # produces, and it makes the installer skip the extra per-user cert
    # (root's is generated unconditionally just above that branch).
    tar xzf "$TARBALL" -C "$BUNDLE" --strip-components=1 --no-same-owner
    chown -R root:root "$BUNDLE"
}

# ─────────────────────────────────────────────────────────
# FOUNDING NODE — Day-0
# ─────────────────────────────────────────────────────────
bootstrap_founding() {
    unpack_release

    log "━━━ running Day-0 install.sh (profiles: $PROFILES) ━━━"
    # FOUNDING_PROFILES is install.sh's own knob for founding-node placement.
    # GLOBULAR_CONFORMANCE=audit keeps the bundled conformance tests running
    # and reported without aborting the run — we want their findings in the
    # journal, since a conformance failure here is a real signal.
    (
        cd "$BUNDLE"
        FOUNDING_PROFILES="$PROFILES" \
        GLOBULAR_CONFORMANCE=audit \
        bash install.sh
    ) || die "Day-0 install.sh failed"
    log "━━━ Day-0 install complete ━━━"

    # Serve the release to joining nodes. The join script prefers the
    # gateway bundle (https://<gw>/join/bundle/<tarball>) over GitHub, and
    # the gateway reads it from /var/lib/globular/releases/<version>/ —
    # so staging it here is what keeps the simulation offline-capable.
    log "staging release for join bundle service ..."
    mkdir -p "$STATE/releases/$VERSION"
    cp "$TARBALL" "$STATE/releases/$VERSION/"
    if [ -f "${TARBALL}.sha256" ]; then
        # Normalise to "<digest>  <filename>" so the joiner's awk+sha256sum
        # comparison sees the name it actually downloaded.
        awk -v n="${RELEASE_NAME}.tar.gz" '{print $1"  "n}' "${TARBALL}.sha256" \
            > "$STATE/releases/$VERSION/${RELEASE_NAME}.tar.gz.sha256"
    else
        ( cd "$STATE/releases/$VERSION" \
            && sha256sum "${RELEASE_NAME}.tar.gz" > "${RELEASE_NAME}.tar.gz.sha256" )
    fi

    # Bootstrap the cluster — the command install.sh prints for the operator.
    # Port selection mirrors install.sh:119-127 exactly. node-agent listens on
    # BOTH 11000 (gRPC) and 11001 (HTTP metrics), and `ss` does not order them
    # deterministically — taking the first match aims the TLS gRPC bootstrap at
    # the metrics port and fails with
    #   "transport: authentication handshake failed: tls: first record does not
    #    look like a TLS handshake"
    # So: prefer 11000 explicitly, fall back to any node_agent port, then 11000.
    local agent_port
    agent_port=$(ss -ltnp 2>/dev/null \
        | awk '/node_agent_serv/ {split($4,a,":"); p=a[length(a)]; if(p ~ /^[0-9]+$/) print p}' \
        | grep -E '^11000$' | head -n1)
    if [ -z "$agent_port" ]; then
        agent_port=$(ss -ltnp 2>/dev/null \
            | awk '/node_agent_serv/ {split($4,a,":"); p=a[length(a)]; if(p ~ /^[0-9]+$/) print p}' \
            | head -n1)
    fi
    agent_port="${agent_port:-11000}"

    local profile_args=()
    IFS=',' read -ra _profs <<< "$PROFILES"
    for p in "${_profs[@]}"; do
        [ -n "$p" ] && profile_args+=(--profile "$p")
    done

    log "━━━ globular cluster bootstrap (node ${NODE_IP}:${agent_port}) ━━━"
    globular cluster bootstrap \
        --node "${NODE_IP}:${agent_port}" \
        --domain "$CLUSTER_DOMAIN" \
        "${profile_args[@]}" \
        || die "cluster bootstrap failed"
    log "━━━ cluster bootstrapped ━━━"

    # Publish the Day-0 join token so the other containers can join. On real
    # hardware the operator carries this token to each new machine; the
    # shared volume is that courier, not a Globular mechanism.
    local token
    token=$(jq -r '.join_token // empty' "$STATE/cluster-controller/config.json" 2>/dev/null || true)
    [ -n "$token" ] || die "no join_token in cluster-controller/config.json after Day-0"

    mkdir -p "$HANDOFF"
    printf '%s' "$token" > "$HANDOFF/join-token"
    printf '%s' "$NODE_IP" > "$HANDOFF/controller-ip"
    log "published join token for joining nodes"

    echo "day0 $(date -Is)" > "$MARKER"
}

# ─────────────────────────────────────────────────────────
# JOINING NODE — Day-1
# ─────────────────────────────────────────────────────────
bootstrap_joining() {
    log "waiting for the founding node to publish a join token ..."
    local token="" waited=0
    while [ $waited -lt 1800 ]; do
        if [ -s "$HANDOFF/join-token" ]; then
            token=$(cat "$HANDOFF/join-token")
            break
        fi
        sleep 5; waited=$((waited + 5))
    done
    [ -n "$token" ] || die "no join token after ${waited}s — did Day-0 succeed on the founder?"
    log "join token available after ${waited}s"

    log "waiting for the founder's gateway on ${CONTROLLER_IP}:8443 ..."
    waited=0
    while [ $waited -lt 900 ]; do
        if curl -sfL -k --max-time 5 "https://${CONTROLLER_IP}:8443/join" -o /dev/null 2>/dev/null; then
            break
        fi
        sleep 5; waited=$((waited + 5))
    done
    log "gateway reachable after ${waited}s"

    # The real Day-1 path, verbatim from the operator docs. The script is
    # generated by the founder's gateway and drives all 9 join phases
    # (preflight, identity, connectivity, download, etcd join, ScyllaDB,
    # services, node-agent). We deliberately do NOT call
    # `globular cluster join` directly — it skips TLS, user creation, unit
    # files and etcd add ordering that the script performs.
    log "━━━ running join script from https://${CONTROLLER_IP}:8443/join ━━━"
    curl -sfL -k "https://${CONTROLLER_IP}:8443/join" \
        | bash -s -- --token "$token" \
        || die "join failed"
    log "━━━ joined cluster ━━━"

    echo "join $(date -Is)" > "$MARKER"
}

case "$ROLE" in
    founding) bootstrap_founding ;;
    joining)  bootstrap_joining ;;
    *)        die "unknown GLOBULAR_ROLE: $ROLE (expected founding|joining)" ;;
esac

log "bootstrap complete for $NODE_NAME"
