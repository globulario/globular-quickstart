# globular-node — a full Globular node in a container
#
# The image is a BARE MACHINE plus the release tarball. It deliberately
# contains no Globular binaries, unit files, users, or state directories:
# those are produced by running the real installer at first boot, exactly
# the way an operator installs on bare metal.
#
#   node-1  → /opt/globular/release/<ver>/install.sh   (Day-0 founding node)
#   node-N  → curl https://<gateway>:8443/join | bash  (real join path)
#
# Anything copied in here that the release would otherwise install is a
# divergence, and divergence is what makes the simulation test the wrong
# thing. Add packages to the release, not to this file.
# Base MUST satisfy the glibc floor of every binary in the release.
#
# Release 1.2.288 is inconsistent: 54 of 55 binaries need at most GLIBC_2.34,
# but file_server needs GLIBC_2.38 (it references a libm symbol the others
# don't). Ubuntu 22.04 ships glibc 2.35, so file_server dies at exec with
#   file_server: /lib/x86_64-linux-gnu/libm.so.6: version `GLIBC_2.38' not found
# and Day-0 aborts at "Workload Services".
#
# That is a REAL release defect — docs/operators/building-from-source.md:30
# advertises "Ubuntu 22.04+" support, and the release is built on a glibc-2.39
# workstation rather than in a container pinned to the minimum baseline. Most
# binaries survive by luck. Fix belongs in the release build, not here.
#
# 24.04 (glibc 2.39) is inside the documented range and matches the machine the
# release is actually built on, so the simulation runs what ships today.
FROM ubuntu:24.04

ARG RELEASE_VERSION
ENV GLOBULAR_RELEASE_VERSION=${RELEASE_VERSION}

ENV DEBIAN_FRONTEND=noninteractive
ENV container=docker

# ── system deps ──────────────────────────────────────────
# Only what a stock server image would already provide, plus what
# install-day0.sh shells out to: python3, jq, openssl, tar, curl, dig,
# setfacl, uuidgen, ss/ip. Globular's own dependencies (etcd, minio,
# scylladb, envoy, keepalived, …) ship as packages in the tarball and
# MUST NOT be apt-installed here.
RUN apt-get update && apt-get install -y --no-install-recommends \
        systemd systemd-sysv dbus \
        systemd-resolved \
        ca-certificates curl iproute2 iputils-ping \
        iptables \
        jq openssl tar python3 \
        acl uuid-runtime dnsutils procps \
        sudo less \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# systemd-resolved is NOT optional, despite being absent from a minimal image:
#   1. The release ships a libnss-resolve .deb whose dependency is exact —
#      `depends on systemd-resolved (= 255.4-1ubuntu8.16)`. Without it, dpkg
#      leaves the package unconfigured, apt "corrects dependencies" by removing
#      it, and the JOIN script fails its install-local-debs step:
#        error=install local debs: packages not installed after dpkg: libnss-resolve
#   2. configure-resolver.sh otherwise reports "No supported resolver system
#      found (systemd-resolved, NetworkManager)" and skips DNS configuration,
#      degrading *.globular.internal resolution to the /etc/hosts seed.
# A real Ubuntu server has it; omitting it was a container-only divergence.

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

# ── release tarball ──────────────────────────────────────
# Staged by `make collect` from $(SERVICES_DIR)/dist/. This is the single
# source of every Globular bit in the image. It is left as a tarball (not
# pre-extracted) so the founding node exercises the same unpack + checksum
# path a real operator does, and so the gateway can serve the untouched
# artifact to joining nodes from /var/lib/globular/releases/<ver>/.
COPY release/ /opt/globular/release/

# ── quickstart orchestration scripts ─────────────────────
# These do NOT install Globular. They only do what a human operator or the
# surrounding datacenter would do: resolve peers, run install.sh on the
# founder, carry the join token to the joiners, and cap ScyllaDB's memory
# the way you would on a small node.
COPY scripts/ /opt/globular/scripts/
RUN chmod +x /opt/globular/scripts/*.sh

# ── node metadata (supplied by docker-compose) ───────────
ENV GLOBULAR_NODE_NAME=""
ENV GLOBULAR_NODE_IP=""
ENV GLOBULAR_ROLE=""
ENV GLOBULAR_PROFILES=""
ENV GLOBULAR_CONTROLLER_IP=""
ENV GLOBULAR_CLUSTER_DOMAIN="globular.internal"

# systemd as PID 1
STOPSIGNAL SIGRTMIN+3
ENTRYPOINT ["/opt/globular/scripts/entrypoint.sh"]
