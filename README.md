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
├── Dockerfile                  # bare Ubuntu + systemd; NO Globular bits
├── docker-compose.yml          # multi-node cluster topology
├── Makefile                    # build, cluster lifecycle, and test targets
├── scripts/
│   ├── entrypoint.sh           # pre-systemd machine prep, then exec init
│   ├── bootstrap.sh            # plays the operator: Day-0 install, or join
│   └── check-systemd-working-directory.sh
├── tests/                      # YAML scenario test harness + reports
└── release/                    # staged release tarball (gitignored)
```

The image contains **no Globular binaries, unit files, users, or state
directories**. It is a bare machine plus the release tarball; everything else
is produced by running the real installer at first boot.

## How the cluster is built

The simulation installs Globular exactly the way an operator does — this is the
point of the repo, not an implementation detail:

| Node | Path |
|------|------|
| node-1 | unpacks the release, runs `install.sh` (Day-0), then `globular cluster bootstrap` |
| node-2..5 | `curl -sfL https://10.10.0.11:8443/join -k \| bash -s -- --token <token>` |

Consequently bring-up takes **~10–15 minutes**, not two. That is the real cost
of forming a real cluster, and paying it is what makes the test results mean
something.

> **Do not add Globular content to the Dockerfile or the entrypoint.** If a
> thing is missing at runtime, it is missing from the *release* — fix it there.
> This repo previously assembled the image from `/usr/lib/globular/bin` and
> `/etc/systemd/system` on the build host and reimplemented Day-0 in 579 lines
> of shell. The resulting cluster had no workflow definitions, no desired
> state, no RBAC bindings and no repository artifacts, so 18 of 38 scenarios
> failed against artifacts of that divergence rather than real defects.

## Cluster topology

A **5-node Globular cluster** on a dedicated Docker network. Profiles are only
those the release actually defines — `core`, `compute`, `control-plane`,
`storage`.

| Node | IP | Role | Profiles |
|------|----|------|----------|
| node-1 | 10.10.0.11 | founding (Day-0) | core, control-plane, storage |
| node-2 | 10.10.0.12 | joining | core, control-plane, storage |
| node-3 | 10.10.0.13 | joining | core, control-plane |
| node-4 | 10.10.0.14 | joining | core, compute |
| node-5 | 10.10.0.15 | joining | core, compute |

ScyllaDB is **not** a sidecar container: the installer puts it on the node, on
the founder during Day-0 and on joiners only where placement assigns `storage`.
That is two instances, each capped to 1 shard / 1500M via `/etc/scylla.d` so
several nodes can share one Docker host.

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
- enough CPU and memory for a 5-node simulation (~15 GB RAM in practice)
- a **release tarball** at `../services/dist/globular-<version>-linux-amd64.tar.gz`

  Build one with `cd ../services && ./scripts/build-local-release.sh`. Nothing
  is taken from the build host's installed Globular — the tarball is the only
  source of Globular bits in the image.

### Build and start the cluster

```bash
make up                              # uses RELEASE_VERSION from the Makefile
make up RELEASE_VERSION=1.2.290      # or pin a specific release
```

This performs:

1. `make collect` — stages the release tarball (+ `.sha256`) into the build context
2. `docker build` — builds a bare systemd image carrying that tarball
3. `docker compose up -d` — boots the nodes; node-1 runs Day-0, the rest join

Watch it form:

```bash
docker exec globular-node-1 journalctl -u globular-quickstart-bootstrap -f
```

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
| `make up` | Stage the release, build image, and start cluster |
| `make down` | Stop cluster, keep state |
| `make clean` | Stop cluster, remove volumes, remove the staged release |
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
# 1. Build a release in the services repo (NOT a host install)
cd ../services && ./scripts/build-local-release.sh && cd -

# 2. Start quickstart against it (~10-15 min: real Day-0 + real joins)
make up RELEASE_VERSION=<the version you just built>

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
