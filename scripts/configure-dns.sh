#!/bin/bash
set -euo pipefail

# configure-dns.sh — Docker-specific DNS wiring (test environment only)
#
# In production, /etc/resolv.conf is managed by the node agent or the
# operator to point at the Globular DNS service. In Docker, we need to
# do the same thing: make *.globular.internal resolve through Globular
# DNS (port 53 on this node), while keeping Docker's embedded DNS
# (127.0.0.11) for external resolution.
#
# This script waits for the Globular DNS service to be healthy on port
# 53, then rewrites /etc/resolv.conf to use this node's IP as the
# primary nameserver with Docker's DNS as fallback.

NODE_IP="${GLOBULAR_NODE_IP:?GLOBULAR_NODE_IP required}"
DOCKER_DNS="127.0.0.11"

echo "[dns-config] Waiting for Globular DNS on ${NODE_IP}:53 (UDP)..."
for i in $(seq 1 90); do
    # Check if DNS port is open via ss (we're on the same host)
    if ss -ulnp 2>/dev/null | grep -q ":53 "; then
        echo "[dns-config] Globular DNS is listening on port 53"
        break
    fi
    sleep 2
done

# Verify DNS port is actually open
if ! ss -ulnp 2>/dev/null | grep -q ":53 "; then
    echo "[dns-config] WARNING: Globular DNS not listening on port 53, keeping Docker DNS only"
    exit 0
fi

# Rewrite resolv.conf:
# - This node's Globular DNS first (handles *.globular.internal)
# - Docker embedded DNS as fallback (handles external names)
# - search domain so bare hostnames resolve in the cluster domain
cat > /etc/resolv.conf <<RESOLV
# Managed by globular-dns-resolver.service (test environment)
# Globular DNS for *.globular.internal
nameserver ${NODE_IP}
# Docker embedded DNS for external resolution
nameserver ${DOCKER_DNS}
search globular.internal
options ndots:1 timeout:2 attempts:2
RESOLV

echo "[dns-config] /etc/resolv.conf updated: primary=${NODE_IP}, fallback=${DOCKER_DNS}"
