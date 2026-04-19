# globular-node — a full Globular node in a container
# Uses systemd as PID 1 so the node agent works identically to bare metal.
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV container=docker

# ── system deps ──────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        systemd systemd-sysv dbus \
        ca-certificates curl iproute2 iputils-ping \
        iptables keepalived \
        jq openssl \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Remove unnecessary systemd units that interfere with containers
RUN (cd /lib/systemd/system/sysinit.target.wants/ && \
        ls | grep -v systemd-tmpfiles-setup | xargs rm -f) ; \
    rm -f /lib/systemd/system/multi-user.target.wants/* ; \
    rm -f /etc/systemd/system/*.wants/* ; \
    rm -f /lib/systemd/system/local-fs.target.wants/* ; \
    rm -f /lib/systemd/system/sockets.target.wants/*udev* ; \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl* ; \
    rm -f /lib/systemd/system/basic.target.wants/* ; \
    rm -f /lib/systemd/system/anaconda.target.wants/*

# ── globular user ────────────────────────────────────────
# Pin UID/GID to 10001 to avoid collisions with host system users.
# Without this, `useradd -r` picks UID 999 which is `dnsmasq` on Ubuntu,
# making all container processes appear as dnsmasq in host `ps` output.
RUN groupadd -r -g 10001 globular && useradd -r -u 10001 -g globular -d /var/lib/globular -s /bin/false globular

# ── directory skeleton ───────────────────────────────────
RUN mkdir -p \
    /usr/lib/globular/bin \
    /var/lib/globular/pki/issued/services \
    /var/lib/globular/pki/ca \
    /var/lib/globular/config \
    /var/lib/globular/etcd \
    /var/lib/globular/minio/data \
    /var/lib/globular/prometheus/data \
    /var/lib/globular/keys \
    /var/lib/globular/services \
    /var/lib/globular/domains \
    /var/lib/globular/mcp \
    /run/globular/envoy \
    /etc/globular

# ── binaries ─────────────────────────────────────────────
# Copied from the build host (build-all-packages.sh output)
COPY binaries/ /usr/lib/globular/bin/
RUN chmod +x /usr/lib/globular/bin/*

# ── systemd unit files ───────────────────────────────────
# Template units — entrypoint renders {{.NodeIP}} etc. at boot
COPY units/ /etc/systemd/system/

# ── RBAC policy ──────────────────────────────────────────
COPY policy/ /opt/globular/policy/

# ── extra systemd units (quickstart-only) ────────────────
COPY units-extra/ /opt/globular/units-extra/

# ── bootstrap + entrypoint scripts ───────────────────────
COPY scripts/ /opt/globular/scripts/
RUN chmod +x /opt/globular/scripts/*.sh

# ── node metadata (overridden by compose environment) ────
ENV GLOBULAR_NODE_NAME=""
ENV GLOBULAR_NODE_IP=""
ENV GLOBULAR_CLUSTER_PEERS=""
ENV GLOBULAR_PROFILES=""
ENV GLOBULAR_CA_MODE="generate"

# systemd as PID 1
STOPSIGNAL SIGRTMIN+3
ENTRYPOINT ["/opt/globular/scripts/entrypoint.sh"]
