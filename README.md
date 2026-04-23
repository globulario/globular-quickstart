# Globular Quickstart

**High-fidelity Docker simulation of a Globular cluster using unmodified production binaries under systemd.**

`globular-quickstart` is the fastest way to stand up a realistic multi-node Globular environment for development, debugging, validation, and failure testing.

This repository is **not** a toy demo and **not** a mocked control plane. It runs the real Globular binaries inside Ubuntu/systemd containers and exercises the real platform stack:

- etcd with mTLS
- controller / node-agent / workflow engine
- Envoy + xDS + gateway
- DNS, RBAC, authentication, repository, monitoring
- MinIO over HTTPS
- AI services
- ScyllaDB as a separate infrastructure container
- YAML-driven scenario tests with evidence capture

It exists to answer questions like:

- “Will Globular cold-boot cleanly from zero state?”
- “Does discovery, PKI, routing, and workflow execution behave correctly?”
- “What happens if a worker dies, etcd loses quorum, or ScyllaDB restarts?”
- “Can we validate fixes in a repeatable cluster before touching bare metal?”

## Repository role in the Globular project

Globular is split across a few focused repositories:

- **[`Globular`](https://github.com/globulario/Globular)** — top-level project entry point and platform overview
- **[`services`](https://github.com/globulario/services)** — backend services, control plane, docs, and installable releases
- **[`globular-admin`](https://github.com/globulario/globular-admin)** — admin UI, media app, SDK, and component library
- **[`globular-installer`](https://github.com/globulario/globular-installer)** — installer/bootstrap implementation used by packaged installs
- **[`globular-quickstart`](https://github.com/globulario/globular-quickstart)** — cluster simulation, test harness, and failure drills

If you want to **install Globular for real**, use the packaged releases from `services`.  
If you want to **simulate, validate, and break a cluster safely**, this repository is the right place.

## What this repository contains

```text
globular-quickstart/
├── Dockerfile                  # Ubuntu + systemd + Globular runtime image
├── docker-compose.yml          # multi-node cluster topology
├── Makefile                    # build, cluster lifecycle, and test targets
├── scripts/                    # bootstrapping and node configuration scripts
├── units/                      # systemd service units copied into the image
├── units-extra/                # quickstart-specific helper units
├── tests/                      # YAML scenario test harness + reports
├── policy/                     # cluster policy fixtures
└── binaries/                   # compiled binaries copied into the image build context
```

## Cluster topology

The quickstart environment models a **5-node Globular cluster plus ScyllaDB** on a dedicated Docker network.

| Node | IP | Profiles | Main role |
|------|----|----------|-----------|
| node-1 | 10.10.0.11 | control-plane, core, gateway | ingress, xDS, gateway, auth, RBAC, workflow |
| node-2 | 10.10.0.12 | control-plane, core, storage | repository, MinIO, monitoring, backup |
| node-3 | 10.10.0.13 | control-plane, core, ai | AI services, MCP, controller replica |
| node-4 | 10.10.0.14 | compute | worker / node-agent |
| node-5 | 10.10.0.15 | compute | worker / node-agent |
| scylladb | 10.10.0.20 | infrastructure | shared ScyllaDB service |

That gives you a realistic control-plane / storage / AI / worker split without needing physical machines.

## Why this repo matters

This repository gives Globular something many infrastructure projects badly need but rarely have: a **repeatable, destructive, testable cluster lab**.

It is useful for:

- cold-boot validation
- control-plane regression testing
- PKI and mTLS debugging
- workflow and reconciliation debugging
- repository and package behavior checks
- resilience drills
- recovery drills
- catastrophic failure simulation before touching real hardware

## Quick start

### Prerequisites

- Docker Engine / Docker Compose
- enough CPU and memory for a 5-node simulation
- compiled Globular binaries available on the host at `/usr/lib/globular/bin`
- systemd unit files available on the host at `/etc/systemd/system`

### Build and start the cluster

```bash
make up
```

This performs:

1. `make collect` — copies binaries and unit files into the build context
2. `docker build` — builds the node image
3. `docker compose up -d` — starts the cluster

### Check status

```bash
make status
make logs
make shell N=1
```

### Stop or reset

```bash
make down          # stop, preserve state
make clean         # stop, remove volumes, wipe build context
make quickstart-reset
```

## Key make targets

### Cluster lifecycle

| Target | Description |
|--------|-------------|
| `make up` | Collect binaries, build image, and start cluster |
| `make down` | Stop cluster, keep state |
| `make clean` | Stop cluster, remove volumes, remove collected binaries/units |
| `make logs` | Follow all container logs |
| `make log-1` | Follow logs for a specific node |
| `make status` | Container state + etcd health |
| `make shell N=1` | Open shell on a specific node |

### Quickstart aliases

| Target | Description |
|--------|-------------|
| `make quickstart-up` | Start cluster without rebuild |
| `make quickstart-down` | Stop cluster, keep state |
| `make quickstart-reset` | Full reset and restart |
| `make quickstart-logs` | Follow logs |

### Test harness

| Target | Description |
|--------|-------------|
| `make test-wait` | Wait for cluster health |
| `make test-smoke` | Run smoke scenarios |
| `make test-functional` | Run functional scenarios |
| `make test-security` | Run security scenarios |
| `make test-resilience` | Run resilience scenarios |
| `make test-recovery` | Run recovery scenarios |
| `make test-soak` | Run soak scenarios |
| `make test-v1-certification` | Full V1 certification run |
| `make test-scenario SCENARIO=...` | Run one scenario |
| `make test-debug-shell NODE=node-1` | Debug shell helper |

## Test harness

The `tests/` directory contains a scenario-driven validation framework for the running cluster.

See [`tests/README.md`](tests/README.md) for full details.

At a glance, the harness includes:

- read-only probes
- YAML-defined scenarios
- per-scenario evidence capture
- human-readable result summaries
- report generation
- suite execution by wave

Current scenario families in this repo:

- **smoke**
- **functional**
- **security**
- **resilience**
- **recovery**
- **soak**
- **catastrophic**

## What the simulation validates

This environment is designed to validate real Globular behavior across several layers.

### Transport and security

- etcd peer and client TLS
- service-to-service mTLS
- cluster CA and per-node/service certificates
- signing key distribution
- token validation paths

### Discovery and configuration

- service registration
- DNS reconciliation
- profile assignment / derivation
- endpoint resolution
- etcd as source of truth

### Control-plane behavior

- leader election
- node heartbeats
- workflow dispatch and execution
- repository and package behavior
- event and workflow client recovery during cold boot

### Infrastructure dependencies

- ScyllaDB connectivity
- MinIO over HTTPS
- monitoring path
- storage-related cluster behavior

### Failure and recovery

- service crash recovery
- worker node loss
- node-agent restart
- etcd member disruption
- control-plane member loss
- release/recovery audit flows
- catastrophic drills

## Design principles

This repository deliberately favors realism over convenience.

- **systemd as PID 1** so supervisor behavior matches real deployment
- **real production binaries** rather than test doubles
- **Docker only as transport and container runtime**
- **ScyllaDB as a separate container**, mirroring real infra separation
- **seeded infrastructure addresses** rather than ad-hoc environment-variable configuration
- **evidence-first tests** so every scenario leaves artifacts behind

## Relationship to real installs

Quickstart is for **simulation and validation**, not the primary end-user install path.

To install Globular on Linux, use the packaged releases from the `services` repository:

- **Releases:** <https://github.com/globulario/services/releases>

Typical install flow:

```bash
VERSION="1.0.56"

curl -LO "https://github.com/globulario/services/releases/download/v${VERSION}/globular-${VERSION}-linux-amd64.tar.gz"
curl -LO "https://github.com/globulario/services/releases/download/v${VERSION}/globular-${VERSION}-linux-amd64.tar.gz.sha256"
/usr/bin/sha256sum -c "globular-${VERSION}-linux-amd64.tar.gz.sha256"

tar xzf "globular-${VERSION}-linux-amd64.tar.gz"
cd "globular-${VERSION}-linux-amd64"
sudo bash install.sh
```

## Typical workflow for contributors

```bash
# 1. Rebuild / install latest host binaries first
# 2. Start quickstart
make up

# 3. Wait for healthy cluster
make test-wait

# 4. Run a focused suite or scenario
make test-smoke
make test-scenario SCENARIO=tests/scenarios/resilience/service-crash-recovery.yaml

# 5. Inspect results
cat tests/reports/latest/SUMMARY.md
```

## Documentation inside this repo

- [`tests/README.md`](tests/README.md) — test harness, scenarios, reports, and suite execution

## License

See [LICENSE](LICENSE) if present in the repository, and the wider Globular project licensing where applicable.
