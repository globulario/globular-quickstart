# Globular Quickstart — Containerized Cluster Simulation

A Docker-based 5-node Globular cluster that runs **unmodified production binaries** inside systemd-in-Docker containers. This is not a demo or a reduced-fidelity mock — it is a full cluster simulation used to validate transport, identity, storage, discovery, control-plane communication, and workflow execution.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Docker Network (10.10.0.0/24)                │
│                                                                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                     │
│  │  node-1  │  │  node-2  │  │  node-3  │                     │
│  │ .11      │  │ .12      │  │ .13      │                     │
│  │ ctrl+gw  │  │ ctrl+sto │  │ ctrl+ai  │                     │
│  │ 15 svcs  │  │ 20 svcs  │  │ 19 svcs  │                     │
│  └──────────┘  └──────────┘  └──────────┘                     │
│                                                                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                     │
│  │  node-4  │  │  node-5  │  │ scylladb │                     │
│  │ .14      │  │ .15      │  │ .20      │                     │
│  │ compute  │  │ compute  │  │ ScyllaDB │                     │
│  │ 1 svc    │  │ 1 svc    │  │ 6.2      │                     │
│  └──────────┘  └──────────┘  └──────────┘                     │
└─────────────────────────────────────────────────────────────────┘
```

| Node | IP | Profiles | Key Services |
|------|-----|----------|-------------|
| node-1 | 10.10.0.11 | control-plane, core, gateway | etcd, controller, xds, envoy, gateway, dns, auth, rbac, workflow |
| node-2 | 10.10.0.12 | control-plane, core, storage | etcd, MinIO (HTTPS), repository, prometheus, monitoring, backup |
| node-3 | 10.10.0.13 | control-plane, core, ai | etcd, ai-memory, ai-executor, ai-watcher, ai-router, mcp |
| node-4 | 10.10.0.14 | compute | node-agent only |
| node-5 | 10.10.0.15 | compute | node-agent only |
| scylladb | 10.10.0.20 | — | ScyllaDB 6.2 (shared database) |

## Quick Start

```bash
# Prerequisites: Docker Engine 29+, 16+ cores, 8GB+ RAM
make up        # builds image + starts 5-node cluster
make status    # check cluster health
make logs      # follow all container logs
make shell N=1 # exec into node-1
make down      # stop cluster (preserve state)
make clean     # stop + wipe all volumes
```

The cluster takes ~3 minutes to fully converge (etcd → ScyllaDB → services → profiles → DNS → workflow).

## What This Proves

This simulation validates the full Globular stack running from cold boot with zero prior state:

### Transport (all TLS)
- etcd: 3-node cluster with mTLS peer and client connections
- gRPC: all inter-service calls use mTLS with the cluster CA
- MinIO: HTTPS with cluster-CA-signed certificate
- ScyllaDB: connected from 3 control-plane nodes

### Identity
- Cluster CA generated at boot, per-node service certs issued with correct SANs
- Ed25519 signing keys generated per node for JWT token signing
- Controller generates SA tokens (300s TTL) with correct cluster_id
- Interceptor chain validates subject + cluster_id on every mutating RPC

### Storage
- etcd: sole source of truth for service config, cluster state, Tier-0 host lists
- ScyllaDB: 8 keyspaces (workflow, dns, rbac_permissions, ai_memory, ai_conversations, globular_events, ...)
- MinIO: HTTPS, cluster-config bucket, workflow definitions stored and retrieved

### Discovery
- All services register in etcd with deterministic UUID keys
- DNS reconciler auto-derives A records from node profiles (11 A + 3 SRV)
- ClusterResolver resolves `*.globular.internal` via Globular DNS daemon
- Profile auto-derivation from installed packages (no manual assignment needed)
- MinIO pool auto-discovered from storage-profile nodes

### Control-Plane
- Single leader via etcd lease election, verified across 3 controllers
- 5 nodes reporting heartbeats every 30s with installed service inventory
- Workflow client connects via lazy retry (handles cold-boot ordering)
- Event client connects via lazy retry

### Workflow Execution (end-to-end)
- Controller dispatches `cluster.reconcile` to workflow service
- Auth: direct gRPC with mTLS + JWT token (not through Envoy)
- Workflow definition loaded from MinIO over HTTPS
- Engine executes 7 steps: advance_infra_joins → scan_drift → classify_drift → short_circuit_clean → aggregate → finalize → emit_completed
- Run state persisted in ScyllaDB with status=SUCCEEDED
- Runs continuously every 30s

## Bugs Found and Fixed

This simulation exposed 4 production bugs that were latent on bare-metal clusters:

### 1. Hardcoded 127.0.0.1 ScyllaDB defaults
- **Services**: ai_memory, dns, workflow
- **Cause**: Default constructors used `127.0.0.1` for ScyllaHosts. On first boot, this got saved to etcd as the service config — poisoning the registry with loopback addresses
- **Fix**: Removed all `127.0.0.1` defaults. ScyllaDB hosts must come from etcd cluster key or the service errors out
- **Rule enforced**: if etcd can't provide infrastructure addresses, fail explicitly

### 2. Cold-boot service resolution race
- **Services**: controller → workflow client, event client
- **Cause**: Peer service addresses resolved once at startup. On cold boot, the registry is empty — services permanently lost connectivity
- **Fix**: Lazy retry goroutines (60 attempts × 5s) for workflow and event clients
- **Confirmed on production**: `workflow_client_nil` observed in readiness gate on bare-metal after restart

### 3. Mesh routing stripping auth context
- **Service**: controller → workflow client
- **Cause**: Fallback resolution used `ResolveServiceAddr` which applies mesh routing (port 443). Envoy strips the controller's mTLS cert and token metadata
- **Fix**: Resolve direct service port from etcd for the workflow client, bypassing mesh

### 4. MinIO pool FQDN in DNS A records
- **Service**: DNS reconciler
- **Cause**: `MinioPoolNodes` stores FQDNs but A records require IPs. `net.ParseIP("node-2.globular.internal")` returned nil → malformed DNS packets
- **Fix**: Resolve FQDNs to IPs from controller node state before emitting pool records

## File Structure

```
globular-quickstart/
├── Dockerfile              # Ubuntu 22.04 + systemd + all Globular binaries
├── docker-compose.yml      # 5 Globular nodes + ScyllaDB
├── Makefile                # build/up/down/clean/status/shell targets
├── scripts/
│   ├── entrypoint.sh       # PKI, etcd config, unit rendering, profile setup
│   ├── seed-etcd.sh        # Tier-0 keys: ScyllaDB/MinIO/DNS hosts
│   ├── assign-profiles.sh  # Profile assignment (superseded by auto-derivation)
│   └── configure-dns.sh    # Wire resolv.conf to Globular DNS
├── units-extra/
│   ├── globular-seed-etcd.service
│   ├── globular-assign-profiles.service
│   └── globular-dns-resolver.service
└── binaries/               # (gitignored) compiled service binaries
```

## Design Decisions

- **systemd as PID 1**: containers run `--privileged` with systemd so the node agent's supervisor works identically to bare metal. No process supervisor shims
- **ScyllaDB as sidecar**: separate container on the Docker network, matching production where ScyllaDB runs as an independent infrastructure component
- **Shared PKI volume**: CA key shared between nodes at boot, per-node certs generated in entrypoint — same trust chain as production
- **No env vars for config**: all service configuration comes from etcd or local seed files. The `GLOBULAR_*` env vars in the compose file are only used by the entrypoint script, never by Globular binaries
- **Docker as dumb transport**: Docker provides networking and container lifecycle only. DNS, service discovery, TLS, and routing all go through Globular's own stack
