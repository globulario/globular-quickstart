# Globular V1 Test Harness

This directory contains the Globular V1 test harness — a YAML-driven, evidence-collecting
test framework for validating a running Globular Docker cluster.

## Quick Start

```bash
# 1. Start the cluster (from the quickstart root)
make up

# 2. Wait for it to become healthy
make test-wait

# 3. Run the smoke suite
make test-smoke

# 4. View the report
cat tests/reports/latest/SUMMARY.md
```

## Requirements

- Docker + Docker Compose
- Python 3 + pyyaml (`pip3 install pyyaml`)
- A running Globular cluster (`make up` or `make quickstart-up`)

## Concepts

### The 4 truth layers

Every test in this harness respects the Globular 4-layer state model:

```
Layer 1: Repository  — "Does this version exist?"
Layer 2: Desired     — "What should be running?"
Layer 3: Installed   — "What is actually installed?"
Layer 4: Runtime     — "Is it running and healthy?"
```

Probes that check etcd registration verify Layer 2/3.
Probes that check systemd unit state verify Layer 4.

### Probes

Probes are read-only queries. They output a single line of JSON.
All probes are implemented in `tests/harness/lib/probes.sh`.

Probe names use dot notation: `cluster.health`, `service.status`, `authz.check`.
In bash, the function is `probe_cluster_health()`, `probe_service_status()`, etc.

### Scenarios

Each scenario is a YAML file that declares:
- Which cluster profile it needs
- Preconditions (probes that must pass before the scenario runs)
- A baseline capture (state before mutation)
- Steps (actions, waits, chaos injections)
- Assertions (probes with expected values)
- Evidence to collect
- Cleanup steps

### Expect operators

In `expect:` blocks:
- `field: value` — exact equality
- `field_gte: N` — numeric greater-than-or-equal
- `field_lte: N` — numeric less-than-or-equal
- `field_contains: str` — string contains

## Directory Structure

```
tests/
├── harness/
│   ├── bin/
│   │   ├── globular-test       # main entry point (bash)
│   │   └── globular-scenario   # YAML scenario executor (Python)
│   └── lib/
│       ├── cluster.sh          # cluster lifecycle helpers
│       ├── probes.sh           # all probe implementations
│       ├── assertions.sh       # assertion helpers
│       └── reports.sh          # report generation
├── scenarios/
│   ├── smoke/                  # Wave 3: quick validation (3 scenarios)
│   ├── functional/             # Wave 4: feature parity (3 scenarios)
│   ├── security/               # Wave 5: authz enforcement (3 scenarios)
│   ├── resilience/             # Wave 6: failure drills (3 scenarios)
│   ├── recovery/               # Wave 7: layer audit + release state (3 scenarios)
│   └── soak/                   # Wave 8: stability (3 scenarios)
├── fixtures/                   # test data (tokens, packages, etc.)
├── golden/                     # baseline snapshots for parity reports
└── reports/                    # output from test runs (gitignored except .gitkeep)
```

## Make Targets

### Cluster lifecycle
| Target | Description |
|--------|-------------|
| `make quickstart-up` | Start cluster |
| `make quickstart-down` | Stop cluster (keeps state) |
| `make quickstart-reset` | Full reset (removes all state) |
| `make quickstart-logs` | Follow all logs |
| `make test-wait` | Wait for healthy (up to 5 min) |

### Test suites
| Target | Description |
|--------|-------------|
| `make test-smoke` | Smoke suite (3 scenarios) |
| `make test-functional` | Functional suite |
| `make test-security` | Security/authz suite |
| `make test-resilience` | Resilience/chaos suite |
| `make test-recovery` | Recovery/repair suite |
| `make test-soak` | Soak/stability suite |
| `make test-v1-certification` | All suites (V1 gate) |

### Single scenario
```bash
make test-scenario SCENARIO=tests/scenarios/smoke/cluster-cold-boot.yaml
make test-scenario-keep SCENARIO=...  # keep artifacts on failure
```

### Reports
| Target | Description |
|--------|-------------|
| `make test-health-matrix` | Service registration matrix |
| `make test-parity-report` | Feature parity vs golden baseline |
| `make test-authz-report` | RBAC/authz summary |

### Debug
```bash
make test-debug-shell NODE=node-1   # shell into a cluster node
make check-test-schemas             # validate all scenario YAML files
```

## CI Integration

Stage 1 — every PR:
```bash
make check-test-schemas
```

Stage 2 — merge to master:
```bash
make ci-smoke   # builds cluster, waits, runs smoke suite
```

Stage 3+ — nightly / pre-release:
```bash
make test-functional test-security test-resilience test-recovery
```

Release gate:
```bash
make test-v1-certification
```

## Implementation Waves

| Wave | Status | Description |
|------|--------|-------------|
| 1 | ✓ Done | Harness skeleton |
| 2 | ✓ Done | Core probe layer |
| 3 | ✓ Done | Smoke scenarios (3) |
| 4 | ✓ Done | Functional scenarios (3) — parity, repository, workflow |
| 5 | ✓ Done | Security scenarios (3) — PKI, RBAC policy, mTLS connectivity |
| 6 | ✓ Done | Resilience scenarios (3) — service crash recovery, worker node failure, etcd quorum |
| 7 | ✓ Done | Recovery scenarios (3) — installed packages audit, release failure audit, layer parity |
| 8 | ✓ Done | Soak scenarios (3) — cluster health stability, service registry stability, node-agent uptime |

## Evidence

Every scenario run produces:
- `evidence.json` — full JSON trace of every probe and result
- `RESULT.md` — human-readable pass/fail summary

Suite runs also produce:
- `SUMMARY.md` — aggregate results for all scenarios in the suite

Reports are written to `tests/reports/<run-id>/` with a `tests/reports/latest` symlink.
