#!/bin/bash
set -euo pipefail

# ── entrypoint.sh ────────────────────────────────────────
# Runs BEFORE systemd (PID != 1). Does the minimum a bare machine would
# already have, then hands off to systemd. It does NOT install Globular —
# install.sh / the join script do that, from a booted system, under the
# globular-quickstart-bootstrap.service oneshot unit.
#
# What used to live here (PKI generation, etcd.yaml, unit rendering, profile
# enablement, config.json seeding, RBAC deployment) was a reimplementation of
# install-day0.sh. It is gone on purpose. If you find yourself adding a step
# that the real installer also performs, you are rebuilding the divergence
# this file was rewritten to remove.

NODE_NAME="${GLOBULAR_NODE_NAME:?GLOBULAR_NODE_NAME required}"
NODE_IP="${GLOBULAR_NODE_IP:?GLOBULAR_NODE_IP required}"
ROLE="${GLOBULAR_ROLE:?GLOBULAR_ROLE required (founding|joining)}"
PROFILES="${GLOBULAR_PROFILES:-core}"
CONTROLLER_IP="${GLOBULAR_CONTROLLER_IP:-}"
CLUSTER_DOMAIN="${GLOBULAR_CLUSTER_DOMAIN:-globular.internal}"
CLUSTER_PEERS="${GLOBULAR_CLUSTER_PEERS:-}"
RELEASE_VERSION="${GLOBULAR_RELEASE_VERSION:?GLOBULAR_RELEASE_VERSION required}"

echo "=== Globular node: $NODE_NAME ($NODE_IP) ==="
echo "    role:     $ROLE"
echo "    profiles: $PROFILES"
echo "    release:  $RELEASE_VERSION"

if [ "$ROLE" = "joining" ] && [ -z "$CONTROLLER_IP" ]; then
    echo "FATAL: joining nodes require GLOBULAR_CONTROLLER_IP" >&2
    exit 1
fi

# ── make /etc/hosts an ordinary file ────────────────────
# Docker bind-mounts /etc/hosts, so it is a mountpoint. Appending works, but
# `sed -i` does write-temp-then-rename, and renaming onto a mountpoint fails
# with EBUSY:
#     sed: cannot rename /etc/sedXXXXXX: Device or resource busy
# The release's configure-resolver.sh does exactly that
# (`sed -i '/minio\.globular\.internal/d' /etc/hosts`) and Day-0 dies there.
# On bare metal /etc/hosts is a plain file, so unmounting restores parity
# rather than working around installer behaviour. Requires privileged: true.
if mountpoint -q /etc/hosts 2>/dev/null; then
    cp /etc/hosts /tmp/hosts.docker
    if umount /etc/hosts 2>/dev/null; then
        cat /tmp/hosts.docker > /etc/hosts
        echo "[hosts] unmounted Docker's bind mount — /etc/hosts is now a regular file"
    else
        echo "[hosts] WARN: could not unmount /etc/hosts; sed -i against it will fail"
    fi
    rm -f /tmp/hosts.docker
fi

# ── /etc/hosts pre-seed ─────────────────────────────────
# A container concession, not a Globular step. On real hardware the site's
# DNS resolves peers before Globular's own DNS service exists; Docker's
# embedded resolver would hand back the host's records for globular.internal
# instead of the 10.10.0.x compose addresses. Seeding /etc/hosts reproduces
# "peers are resolvable at boot" without simulating any Globular behaviour.
if [ -n "$CLUSTER_PEERS" ]; then
    {
        echo "# Globular cluster peers (container DNS substitute — not a Globular step)"
        IFS=',' read -ra _PEERS <<< "$CLUSTER_PEERS"
        for _peer in "${_PEERS[@]}"; do
            _name="${_peer%%=*}"
            _ip="${_peer##*=}"
            echo "$_ip  $_name ${_name}.${CLUSTER_DOMAIN}"
        done
    } >> /etc/hosts
    echo "[hosts] Seeded cluster peer names"
fi

# ── ScyllaDB sizing for a shared host ───────────────────
# Scylla sizes itself from visible host RAM, so several instances on one
# Docker host would each try to claim the whole machine. This is ordinary
# small-node sizing an operator supplies via /etc/scylla.d, the same knob a
# real deployment uses. It does not change the install path.
mkdir -p /etc/scylla.d
# NOTE: --overprovisioned is a BARE flag on the scylla binary. The
# `--overprovisioned=1` spelling only works through the scylladb Docker
# image's entrypoint wrapper; passed straight to /usr/bin/scylla it fails
# with "option '--overprovisioned' does not take any arguments" and the
# unit dies status=2/INVALIDARGUMENT.
# This file sorts last in /etc/scylla.d (after memory.conf), so its
# SCYLLA_ARGS wins.
#
# Deliberately does NOT set --developer-mode. That flag belongs to Scylla's
# own dev-mode.conf, which the scylladb package's post-install owns: it runs
# scylla_io_setup and, ONLY when calibration is unavailable or fails, writes
# DEV_MODE=--developer-mode=1 there. The unit expands both
# (ExecStart=/usr/bin/scylla $SCYLLA_ARGS ... $DEV_MODE ...), so setting it
# here too made startup depend on whether I/O calibration happened to succeed:
#
#   calibrated   (io_properties.yaml + SEASTAR_IO) -> DEV_MODE empty  -> starts
#   uncalibrated (post-install fallback)           -> DEV_MODE set    -> the
#     flag appears twice and scylla exits 2/INVALIDARGUMENT with
#     "option '--developer-mode' cannot be specified more than once"
#
# Observed 2026-08-10: node-1/node-2 calibrated and ran; node-3 did not, so
# scylla-server crash-looped and the node never left bootstrap. Leaving the
# flag to its owner is correct in both branches — a calibrated node does not
# need developer mode, and an uncalibrated one gets it exactly once.
cat > /etc/scylla.d/quickstart-sizing.conf <<'SCYLLASIZE'
# Quickstart sizing: several nodes share one Docker host.
SCYLLA_ARGS="--overprovisioned --smp=1 --memory=1500M"
SCYLLASIZE
echo "[scylla] Wrote /etc/scylla.d/quickstart-sizing.conf (1 shard, 1500M)"

# ── hand the bootstrap its parameters ───────────────────
mkdir -p /etc/globular
cat > /etc/globular/quickstart.env <<ENVFILE
GLOBULAR_NODE_NAME=$NODE_NAME
GLOBULAR_NODE_IP=$NODE_IP
GLOBULAR_ROLE=$ROLE
GLOBULAR_PROFILES=$PROFILES
GLOBULAR_CONTROLLER_IP=$CONTROLLER_IP
GLOBULAR_CLUSTER_DOMAIN=$CLUSTER_DOMAIN
GLOBULAR_RELEASE_VERSION=$RELEASE_VERSION
ENVFILE

# ── install the bootstrap unit ──────────────────────────
# Day-0 and join both need a *running* systemd (they call systemctl start),
# so they cannot run here. A oneshot unit runs them after boot, which is also
# what actually happens on real hardware: the machine boots, then the
# operator runs the installer.
cat > /etc/systemd/system/globular-quickstart-bootstrap.service <<'UNIT'
[Unit]
Description=Globular quickstart bootstrap (Day-0 install or cluster join)
After=network-online.target systemd-tmpfiles-setup.service
Wants=network-online.target
# No ConditionPathExists guard: bootstrap.sh is idempotent and re-checks the
# completion marker itself, so a container restart resumes rather than reruns.

[Service]
Type=oneshot
RemainAfterExit=yes
TimeoutStartSec=0
# Reproduce the environment `sudo bash install.sh` gives the installer.
# systemd starts services with no HOME, and install-day0.sh runs under
# `set -euo pipefail` while consulting $HOME for an optional logo path —
# so an unset HOME aborts the whole Day-0 run at line 288 on something
# purely cosmetic. Supplying HOME here keeps the simulation faithful to the
# operator's shell rather than papering over installer behaviour.
Environment=HOME=/root
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
EnvironmentFile=/etc/globular/quickstart.env
ExecStart=/opt/globular/scripts/bootstrap.sh
StandardOutput=journal+console
StandardError=journal+console

[Install]
WantedBy=multi-user.target
UNIT

mkdir -p /etc/systemd/system/multi-user.target.wants
ln -sf /etc/systemd/system/globular-quickstart-bootstrap.service \
       /etc/systemd/system/multi-user.target.wants/globular-quickstart-bootstrap.service

echo "[boot] Handing off to systemd..."
exec /sbin/init
