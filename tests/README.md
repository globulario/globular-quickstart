# Globular Quickstart Test Harness

**Scenario-driven validation for a running Globular quickstart cluster.**

This directory contains the test harness used to validate the Docker-based Globular cluster started by `globular-quickstart`.

It is built around:

- read-only probes
- YAML scenario definitions
- suite execution by category
- evidence capture for every run
- Markdown summaries for human review

This is the place where Globular gets tested as a **real clustered system**, not just as isolated unit tests.

## What this harness is for

The harness is designed to answer questions like:

- Did the cluster cold-boot correctly?
- Are the control-plane and runtime layers aligned?
- Does mTLS actually work end to end?
- Can services recover from crashes?
- What happens when a worker disappears?
- Does etcd disruption surface clearly?
- Do recovery and audit flows leave evidence?

## Quick start

From the quickstart repository root:

```bash
make up
make test-wait
make test-smoke
cat tests/reports/latest/SUMMARY.md
```

You can also run a single scenario:

```bash
make test-scenario SCENARIO=tests/scenarios/smoke/cluster-cold-boot.yaml
```

Or keep artifacts around during debugging:

```bash
make test-scenario-keep SCENARIO=tests/scenarios/resilience/service-crash-recovery.yaml
```

## Requirements

- a running quickstart cluster
- Docker / Docker Compose
- Python 3
- `pyyaml` available to the scenario executor
- the harness entrypoint at `tests/harness/bin/globular-test`

## Core model

### The 4 truth layers

The harness follows the Globular 4-layer state model:

```text
Layer 1: Repository  — does the artifact/version exist?
Layer 2: Desired     — what should be present?
Layer 3: Installed   — what is actually installed?
Layer 4: Runtime     — what is running and healthy now?
```

The point is not only to see whether “something works.”  
It is to tell **which layer drifted** when something does not.

### Probes

Probes are read-only checks that return structured JSON.

Examples include cluster-, service-, authz-, PKI-, and runtime-oriented checks.  
They are implemented under:

- `tests/harness/lib/probes.sh`

### Scenarios

Scenarios are YAML files under `tests/scenarios/`.

A scenario typically declares:

- required cluster profile or context
- preconditions
- actions / waits / chaos injections
- assertions
- evidence to collect
- cleanup behavior

### Evidence

Every scenario run produces durable artifacts such as:

- `evidence.json`
- `RESULT.md`

Suite runs also produce:

- `SUMMARY.md`

Reports are written under:

- `tests/reports/<run-id>/`
- `tests/reports/latest` points to the most recent run

## Directory layout

```text
tests/
├── README.md
├── harness/
│   ├── bin/
│   │   └── globular-test
│   └── lib/
│       ├── cluster.sh
│       ├── probes.sh
│       └── parse_service_configs.py
├── scenarios/
│   ├── smoke/
│   ├── functional/
│   ├── security/
│   ├── resilience/
│   ├── recovery/
│   ├── soak/
│   └── catastrophic/
├── fixtures/
├── golden/
└── reports/
```

## Scenario families in this repository

Based on the current repository contents, this harness includes:

| Family | Purpose |
|--------|---------|
| `smoke` | fast confidence checks after startup |
| `functional` | core cluster and platform behavior |
| `security` | mTLS, PKI, signing keys, and RBAC policy checks |
| `resilience` | service crash and node disruption drills |
| `recovery` | audits, parity checks, rejoin/resync, release-failure evidence |
| `soak` | time-based stability checks |
| `catastrophic` | majority-loss and blackout style drills |

### Current scenario counts

The repository currently contains:

- **3 smoke** scenarios
- **6 functional** scenarios
- **8 security** scenarios
- **11 resilience** scenarios
- **6 recovery** scenarios
- **3 soak** scenarios
- **5 catastrophic** scenarios

This is broader than a basic smoke harness. It is a layered failure-lab.

## Main make targets

These are run from the quickstart repository root.

### Bring the cluster to ready state

```bash
make up
make test-wait
```

### Run suites

```bash
make test-smoke
make test-functional
make test-security
make test-resilience
make test-recovery
make test-soak
```

### Full V1 gate

```bash
make test-v1-certification
```

### Run one scenario

```bash
make test-scenario SCENARIO=tests/scenarios/security/mtls-connectivity.yaml
```

### Generate reports

```bash
make test-parity-report
make test-health-matrix
make test-authz-report
make test-recovery-report
```

### Debug

```bash
make test-debug-shell NODE=node-1
make check-test-schemas
make check-test-scenarios
```

## What makes this harness useful

This harness is valuable because it combines three things that usually live far apart:

1. **real cluster execution**
2. **declarative scenarios**
3. **post-run evidence**

That makes it suitable for:

- regression testing after infrastructure changes
- validating bug fixes against realistic failure modes
- capturing operator-readable proof for readiness gates
- building confidence before bare-metal rollout

## How to read results

A typical workflow after running a suite:

```bash
cat tests/reports/latest/SUMMARY.md
find tests/reports/latest -name RESULT.md | sort
find tests/reports/latest -name evidence.json | sort
```

If a scenario fails, the `evidence.json` file is the primary forensic artifact.  
The Markdown reports are there to make the results easier to scan quickly.

## Notes for contributors

- keep probes read-only whenever possible
- keep scenarios declarative and evidence-oriented
- prefer explicit assertions over vague “health looks good” checks
- when adding a new scenario, place it in the right family by intent, not by convenience
- update scenario docs when suite shape changes

## Relationship to other tests

This harness does **not** replace service-level unit tests or lower-level integration tests in `services/`.

Instead, it validates the **cluster as a whole** after packaging, supervision, PKI, discovery, routing, and infrastructure dependencies are all in play.
