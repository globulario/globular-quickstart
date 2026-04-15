#!/bin/bash
set -euo pipefail

# ── entrypoint.sh ────────────────────────────────────────
# Runs BEFORE systemd starts (PID != 1).
# Renders templates, generates PKI, writes etcd config,
# then execs into systemd which starts everything via units.

NODE_NAME="${GLOBULAR_NODE_NAME:?GLOBULAR_NODE_NAME required}"
NODE_IP="${GLOBULAR_NODE_IP:?GLOBULAR_NODE_IP required}"
CLUSTER_PEERS="${GLOBULAR_CLUSTER_PEERS:?GLOBULAR_CLUSTER_PEERS required}"
PROFILES="${GLOBULAR_PROFILES:-compute}"
CA_MODE="${GLOBULAR_CA_MODE:-copy}"   # "generate" on node-1, "copy" on others

STATE=/var/lib/globular
PKI=$STATE/pki

# Detect the container's actual MAC address (stable when docker-compose
# sets mac_address, random otherwise). Globular uses MAC as node identity
# for signing keys and JWT tokens.
NODE_MAC=$(ip link show eth0 2>/dev/null | awk '/ether/{print $2}' || echo "00:00:00:00:00:00")

echo "=== Globular node: $NODE_NAME ($NODE_IP) ==="
echo "    profiles: $PROFILES"
echo "    peers:    $CLUSTER_PEERS"
echo "    mac:      $NODE_MAC"

# ── 1. PKI bootstrap ────────────────────────────────────
if [ "$CA_MODE" = "generate" ]; then
    if [ ! -f "$PKI/ca.key" ]; then
        echo "[pki] Generating cluster CA..."
        # Use genpkey for PKCS#8 format (required by xDS/Go crypto)
        openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:prime256v1 \
            -out "$PKI/ca.key" 2>/dev/null
        openssl req -new -x509 -key "$PKI/ca.key" \
            -out "$PKI/ca.crt" -days 3650 \
            -subj "/CN=Globular Cluster CA" 2>/dev/null
        # Also create ca.pem (some components use this name)
        cp "$PKI/ca.crt" "$PKI/ca.pem"
        echo "[pki] CA generated."
    fi
    # Copy CA to shared volume so other nodes pick it up
    cp "$PKI/ca.key" /shared-pki/ca.key
    cp "$PKI/ca.crt" /shared-pki/ca.crt
    cp "$PKI/ca.crt" /shared-pki/ca.pem
else
    echo "[pki] Waiting for CA from shared volume..."
    for i in $(seq 1 120); do
        [ -f /shared-pki/ca.crt ] && break
        sleep 1
    done
    [ ! -f /shared-pki/ca.crt ] && echo "FATAL: CA not available after 120s" && exit 1
    cp /shared-pki/ca.key "$PKI/ca.key"
    cp /shared-pki/ca.crt "$PKI/ca.crt"
    cp /shared-pki/ca.crt "$PKI/ca.pem"
    echo "[pki] CA copied from shared volume."
fi

# Generate node service certificate
if [ ! -f "$PKI/issued/services/service.crt" ]; then
    echo "[pki] Generating service certificate for $NODE_NAME..."

    # Build SAN list: node IP + hostname + FQDN + localhost (for health checks)
    CLUSTER_DOMAIN="${GLOBULAR_CLUSTER_DOMAIN:-globular.internal}"
    SAN="IP:$NODE_IP,IP:127.0.0.1,DNS:$NODE_NAME,DNS:${NODE_NAME}.${CLUSTER_DOMAIN},DNS:localhost"
    # Add VIP if this is a gateway node
    if echo "$PROFILES" | grep -q "gateway"; then
        SAN="$SAN,IP:10.10.0.100"
    fi

    openssl ecparam -genkey -name prime256v1 \
        -out "$PKI/issued/services/service.key" 2>/dev/null
    openssl req -new -key "$PKI/issued/services/service.key" \
        -out /tmp/service.csr \
        -subj "/CN=$NODE_NAME" \
        -addext "subjectAltName=$SAN" 2>/dev/null
    openssl x509 -req -in /tmp/service.csr \
        -CA "$PKI/ca.crt" -CAkey "$PKI/ca.key" -CAcreateserial \
        -out "$PKI/issued/services/service.crt" -days 365 \
        -copy_extensions copyall 2>/dev/null
    rm -f /tmp/service.csr
    echo "[pki] Service cert issued."
fi

# ── 2. Ed25519 signing key ──────────────────────────────
if [ ! -f "$STATE/keys/${NODE_NAME}_private" ]; then
    echo "[pki] Generating Ed25519 signing key..."
    openssl genpkey -algorithm Ed25519 \
        -out "$STATE/keys/${NODE_NAME}_private" 2>/dev/null
    openssl pkey -in "$STATE/keys/${NODE_NAME}_private" \
        -pubout -out "$STATE/keys/${NODE_NAME}_public" 2>/dev/null
fi

# ── 2a. Cross-node public key exchange ───────────────────
# Each node signs JWTs with its own Ed25519 key. For cross-node auth,
# every node must have every other node's PUBLIC key so it can verify
# tokens from remote services. We use /shared-pki as the exchange.
#
# The MAC-based key (generated lazily by Go code at first token creation)
# is the one actually used for signing. We generate it here so it's
# available before any service starts.
NODE_MAC_NORM=$(echo "$NODE_MAC" | tr ':' '_')
if [ ! -f "$STATE/keys/${NODE_MAC_NORM}_private" ]; then
    echo "[pki] Generating Ed25519 signing key for MAC $NODE_MAC..."
    openssl genpkey -algorithm Ed25519 \
        -out "$STATE/keys/${NODE_MAC_NORM}_private" 2>/dev/null
    openssl pkey -in "$STATE/keys/${NODE_MAC_NORM}_private" \
        -pubout -out "$STATE/keys/${NODE_MAC_NORM}_public" 2>/dev/null
fi

# Publish this node's public key to the shared volume.
mkdir -p /shared-pki/keys
cp "$STATE/keys/${NODE_MAC_NORM}_public" "/shared-pki/keys/${NODE_MAC_NORM}_public"
echo "[pki] Published public key for $NODE_MAC to shared volume"

# Import all peer public keys from the shared volume.
# Runs in a background loop because other nodes may not have published yet.
(
    for i in $(seq 1 60); do
        if ls /shared-pki/keys/*_public 2>/dev/null | grep -q .; then
            for pubkey in /shared-pki/keys/*_public; do
                base=$(basename "$pubkey")
                if [ ! -f "$STATE/keys/$base" ]; then
                    cp "$pubkey" "$STATE/keys/$base"
                    echo "[pki] Imported peer public key: $base"
                fi
            done
        fi
        sleep 2
    done
) &

# ── 2b. MinIO TLS certs (storage nodes) ─────────────────
# MinIO auto-detects TLS when certs exist in ~/.minio/certs/
# Generate a cert signed by the cluster CA so MinIO serves HTTPS.
if echo "$PROFILES" | grep -q "storage"; then
    MINIO_CERT_DIR="$STATE/.minio/certs"
    if [ ! -f "$MINIO_CERT_DIR/private.key" ]; then
        echo "[pki] Generating MinIO TLS certificate..."
        mkdir -p "$MINIO_CERT_DIR/CAs"
        cp "$PKI/ca.crt" "$MINIO_CERT_DIR/CAs/ca.crt"
        openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:prime256v1 \
            -out "$MINIO_CERT_DIR/private.key" 2>/dev/null
        openssl req -new -key "$MINIO_CERT_DIR/private.key" \
            -out /tmp/minio.csr \
            -subj "/CN=minio.globular.internal" \
            -addext "subjectAltName=DNS:minio.globular.internal,DNS:$NODE_NAME,IP:$NODE_IP" 2>/dev/null
        openssl x509 -req -in /tmp/minio.csr \
            -CA "$PKI/ca.crt" -CAkey "$PKI/ca.key" -CAcreateserial \
            -out "$MINIO_CERT_DIR/public.crt" -days 365 \
            -copy_extensions copyall 2>/dev/null
        rm -f /tmp/minio.csr
        echo "[pki] MinIO TLS cert issued."
    fi
fi

# ── 3. etcd config ──────────────────────────────────────
if echo "$PROFILES" | grep -q "control-plane"; then
    echo "[etcd] Writing etcd.yaml for $NODE_NAME..."
    # Build initial-cluster string from CLUSTER_PEERS
    # Format: "node-1=https://10.10.0.11:2380,node-2=https://10.10.0.12:2380,..."
    INITIAL_CLUSTER=""
    IFS=',' read -ra PEERS <<< "$CLUSTER_PEERS"
    for peer in "${PEERS[@]}"; do
        PEER_NAME="${peer%%=*}"
        PEER_IP="${peer##*=}"
        [ -n "$INITIAL_CLUSTER" ] && INITIAL_CLUSTER="$INITIAL_CLUSTER,"
        INITIAL_CLUSTER="${INITIAL_CLUSTER}${PEER_NAME}=https://${PEER_IP}:2380"
    done

    cat > "$STATE/config/etcd.yaml" <<ETCD
name: "$NODE_NAME"
data-dir: "$STATE/etcd"

listen-client-urls: "https://${NODE_IP}:2379"
advertise-client-urls: "https://${NODE_IP}:2379"

listen-peer-urls: "https://${NODE_IP}:2380"
initial-advertise-peer-urls: "https://${NODE_IP}:2380"

initial-cluster: "${INITIAL_CLUSTER}"
initial-cluster-state: "new"
initial-cluster-token: "globular-quickstart"

client-transport-security:
  cert-file: "$PKI/issued/services/service.crt"
  key-file: "$PKI/issued/services/service.key"
  client-cert-auth: false
  auto-tls: false

peer-transport-security:
  cert-file: "$PKI/issued/services/service.crt"
  key-file: "$PKI/issued/services/service.key"
  client-cert-auth: false
  trusted-ca-file: "$PKI/ca.pem"
  auto-tls: false

logger: "zap"
ETCD
    chown globular:globular "$STATE/config/etcd.yaml"
fi

# ── Helper: enable a systemd unit (create WantedBy symlink) ──
WANTS_DIR=/etc/systemd/system/multi-user.target.wants
mkdir -p "$WANTS_DIR"

enable_unit() {
    local unit="$1"
    ln -sf "/etc/systemd/system/${unit}" "$WANTS_DIR/${unit}"
}

# ── 4. Render systemd unit templates ────────────────────
echo "[units] Rendering unit file templates..."
for unit in /etc/systemd/system/globular-*.service; do
    [ -f "$unit" ] || continue
    sed -i \
        -e "s|{{.NodeIP}}|$NODE_IP|g" \
        -e "s|{{.NodeName}}|$NODE_NAME|g" \
        -e "s|{{.StateDir}}|$STATE|g" \
        -e "s|{{.BinDir}}|/usr/lib/globular/bin|g" \
        -e "s|{{.MinioDataDir}}|$STATE/minio/data|g" \
        "$unit"
    # Remove scylla-server.service from After/Wants (it's a separate container now)
    sed -i -e 's/ scylla-server\.service//g' "$unit"
    # Rewrite ScyllaDB wait probes to check the remote ScyllaDB container
    if [ -n "${GLOBULAR_SCYLLA_ADDR:-}" ]; then
        # Replace the entire ExecStartPre line that checks port 9042
        # The original: for i in ...; do ss -lnt | grep ":9042"; done
        # New: use bash /dev/tcp to check remote ScyllaDB
        sed -i "/9042/c\\ExecStartPre=/bin/bash -c 'for i in \$(seq 1 90); do echo > /dev/tcp/${GLOBULAR_SCYLLA_ADDR}/9042 2>/dev/null && exit 0; sleep 1; done; echo scylla not ready; exit 1'" "$unit"
    else
        sed -i '/9042/d' "$unit"
    fi
done

# On compute nodes, configure DNS to resolve through a control-plane node
if ! echo "$PROFILES" | grep -q "control-plane"; then
    cp /opt/globular/units-extra/globular-dns-resolver.service /etc/systemd/system/
    # Compute nodes point at node-1's DNS (first peer)
    FIRST_PEER_IP=$(echo "$CLUSTER_PEERS" | cut -d',' -f1 | cut -d'=' -f2)
    mkdir -p /etc/globular
    cat > /etc/globular/quickstart.env <<ENVFILE
GLOBULAR_NODE_IP=$FIRST_PEER_IP
ENVFILE
    enable_unit globular-dns-resolver.service
fi

# On compute-only nodes, strip controller/event dependencies from node-agent
# to prevent pulling in services that shouldn't run on compute nodes
if ! echo "$PROFILES" | grep -q "control-plane"; then
    echo "[units] Compute-only node: stripping controller dependencies from node-agent"
    sed -i \
        -e 's/ globular-cluster-controller\.service//g' \
        -e 's/ globular-event\.service//g' \
        /etc/systemd/system/globular-node-agent.service
fi

# ── 5. Enable units based on profiles ───────────────────
# systemctl enable requires a running systemd (D-Bus), but we're
# before PID 1. Create the WantedBy symlinks manually.
echo "[units] Enabling services for profiles: $PROFILES"

# Always enabled on every node
enable_unit globular-node-agent.service

if echo "$PROFILES" | grep -q "control-plane"; then
    for u in \
        globular-etcd.service \
        globular-cluster-controller.service \
        globular-workflow.service \
        globular-cluster-doctor.service \
        globular-dns.service \
        globular-authentication.service \
        globular-rbac.service \
        globular-resource.service \
        globular-discovery.service \
        globular-event.service \
        globular-log.service \
        globular-xds.service \
        globular-envoy.service \
    ; do enable_unit "$u"; done
fi

if echo "$PROFILES" | grep -q "gateway"; then
    enable_unit globular-gateway.service
fi

if echo "$PROFILES" | grep -q "storage"; then
    for u in \
        globular-minio.service \
        globular-repository.service \
        globular-monitoring.service \
        globular-prometheus.service \
        globular-alertmanager.service \
        globular-backup-manager.service \
    ; do enable_unit "$u"; done
fi

if echo "$PROFILES" | grep -q "ai"; then
    for u in \
        globular-ai-memory.service \
        globular-ai-executor.service \
        globular-ai-watcher.service \
        globular-ai-router.service \
        globular-mcp.service \
    ; do enable_unit "$u"; done
fi

# Install quickstart-specific services on control-plane nodes
if echo "$PROFILES" | grep -q "control-plane"; then
    cp /opt/globular/units-extra/globular-seed-etcd.service /etc/systemd/system/
    cp /opt/globular/units-extra/globular-dns-resolver.service /etc/systemd/system/
    cp /opt/globular/units-extra/globular-assign-profiles.service /etc/systemd/system/
    enable_unit globular-seed-etcd.service
    enable_unit globular-dns-resolver.service
    enable_unit globular-assign-profiles.service
    # Write env file for the seed/dns scripts
    mkdir -p /etc/globular
    cat > /etc/globular/quickstart.env <<ENVFILE
GLOBULAR_SCYLLA_ADDR=${GLOBULAR_SCYLLA_ADDR:-}
GLOBULAR_NODE_IP=$NODE_IP
GLOBULAR_CLUSTER_DOMAIN=${GLOBULAR_CLUSTER_DOMAIN:-quickstart.local}
ENVFILE
fi

# ── 6. Seed configuration ───────────────────────────────
# The controller and other services need a local config.json with
# at least Domain and the etcd endpoints.
CLUSTER_DOMAIN="${GLOBULAR_CLUSTER_DOMAIN:-globular.internal}"

# Clear stale tokens from previous runs. Tokens are signed with the node's
# signing key; after a restart with a new MAC or regenerated keys, old
# tokens have invalid signatures and cause auth failures.
if [ -d "$STATE/tokens" ]; then
    echo "[config] Clearing stale tokens..."
    rm -f "$STATE/tokens/"*_token
fi

# Build etcd endpoints list from peers
ETCD_ENDPOINTS=""
IFS=',' read -ra PEERS_CFG <<< "$CLUSTER_PEERS"
for peer in "${PEERS_CFG[@]}"; do
    PEER_IP="${peer##*=}"
    [ -n "$ETCD_ENDPOINTS" ] && ETCD_ENDPOINTS="$ETCD_ENDPOINTS,"
    ETCD_ENDPOINTS="${ETCD_ENDPOINTS}https://${PEER_IP}:2379"
done

cat > "$STATE/config.json" <<SEEDCFG
{
  "Domain": "$CLUSTER_DOMAIN",
  "Name": "$NODE_NAME",
  "Mac": "$NODE_MAC",
  "EtcdEndpoints": "$ETCD_ENDPOINTS",
  "CaCertificate": "$PKI/ca.crt",
  "Certificate": "$PKI/issued/services/service.crt",
  "Key": "$PKI/issued/services/service.key"
}
SEEDCFG
echo "[config] Wrote seed config.json (domain=$CLUSTER_DOMAIN)"

# Write etcd endpoints file — this is the FIRST source the config library checks.
# Without it, services construct "node-1.quickstart.local:2379" which Docker DNS can't resolve.
mkdir -p "$STATE/config"
IFS=',' read -ra PEERS_EP <<< "$CLUSTER_PEERS"
> "$STATE/config/etcd_endpoints"
for peer in "${PEERS_EP[@]}"; do
    PEER_IP="${peer##*=}"
    echo "https://${PEER_IP}:2379" >> "$STATE/config/etcd_endpoints"
done
echo "[config] Wrote etcd_endpoints file"

# Write the controller-specific config
mkdir -p "$STATE/cluster-controller"
cat > "$STATE/cluster-controller/config.json" <<CTRLCFG
{
  "port": 12000,
  "cluster_domain": "$CLUSTER_DOMAIN",
  "bootstrapped": false,
  "default_profiles": ["core"]
}
CTRLCFG

# Deploy RBAC cluster-roles.json (controller needs this at startup)
mkdir -p "$STATE/policy/rbac"
if [ -f /opt/globular/policy/rbac/cluster-roles.json ]; then
    cp /opt/globular/policy/rbac/cluster-roles.json "$STATE/policy/rbac/"
    echo "[rbac] Deployed cluster-roles.json"
fi

# Seed Prometheus config if storage node
if echo "$PROFILES" | grep -q "storage"; then
    mkdir -p "$STATE/prometheus"
    if [ ! -f "$STATE/prometheus/prometheus.yml" ]; then
        cat > "$STATE/prometheus/prometheus.yml" <<PROMCFG
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'globular-nodes'
    scheme: http
    static_configs:
      - targets:
          - '10.10.0.11:11001'
          - '10.10.0.12:11001'
          - '10.10.0.13:11001'
          - '10.10.0.14:11001'
          - '10.10.0.15:11001'
PROMCFG
        echo "[config] Wrote prometheus.yml"
    fi

    # Seed alertmanager config
    mkdir -p "$STATE/alertmanager"
    if [ ! -f "$STATE/alertmanager/alertmanager.yml" ]; then
        cat > "$STATE/alertmanager/alertmanager.yml" <<AMCFG
route:
  receiver: 'default'
  group_wait: 10s
  group_interval: 30s
  repeat_interval: 1h

receivers:
  - name: 'default'
AMCFG
        echo "[config] Wrote alertmanager.yml"
    fi

    # Pre-create backup dirs
    mkdir -p "$STATE/backups/jobs"
fi

# ── 7. Pre-create working directories for all units ─────
# systemd checks WorkingDirectory BEFORE ExecStartPre runs
echo "[dirs] Creating service working directories..."
for unit in /etc/systemd/system/globular-*.service; do
    [ -f "$unit" ] || continue
    dir=$(grep -oP '^WorkingDirectory=-?\K.*' "$unit" 2>/dev/null || true)
    [ -n "$dir" ] && mkdir -p "$dir"
done
# Also create runtime dirs
mkdir -p /run/globular/envoy

# ── 8. Fix ownership ────────────────────────────────────
chown -R globular:globular "$STATE"
# Top-level dir owned by root but group-writable for globular
# (node_agent runs as root, gateway runs as globular and needs
# to rename config.json in the state root)
chown root:globular "$STATE"
chmod 0775 "$STATE"

echo "[boot] Handing off to systemd..."
exec /sbin/init
