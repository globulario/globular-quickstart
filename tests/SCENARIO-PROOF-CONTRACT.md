# Scenario Proof Contract v1

Status: **Phase 1 / implementation contract**

This document defines when a Globular quickstart scenario is allowed to count as proof for repair, feature evolution, certification, or behavioral learning.

The central rule is:

> **A scenario may contribute proof only when every required probe and action it declares is actually executable by the harness. Unsupported or silently skipped behavior is not PASS.**

This is the simulation-side companion to the autonomous repair/evolution strategy in `globulario/services/docs/design/autonomous-repair-evolution-strategy.md`.

## Why this contract exists

The quickstart harness already captures real clustered behavior with declarative YAML scenarios, read-only probes, chaos actions, evidence bundles, and awareness training. That makes it an unusually good foundation for autonomous engineering.

But autonomous agents need a stronger semantic boundary than "the command exited zero." A green result is useful only if the harness can prove that it executed the behavior the scenario claims to exercise.

Phase 1 therefore distinguishes:

- `PASS` — the declared proof surface executed and all required assertions passed.
- `FAIL` — the proof surface executed and an assertion failed.
- `PARTIAL` — the scenario began but a required execution step failed.
- `INFRA_ERROR` — the lab could not establish the required starting environment.
- `UNSUPPORTED` — a required probe/action is not implemented or the proof contract cannot be validated.

`UNSUPPORTED`, `PARTIAL`, and `INFRA_ERROR` are never certification success.

## Proof boundary

The trusted entry point is:

```bash
tests/harness/bin/globular-test scenario <scenario.yaml>
```

Suite execution through `globular-test suite <suite>` uses the same boundary.

`globular-test` delegates scenario execution to `globular-scenario-proof`, which:

1. validates the scenario proof contract and harness capabilities;
2. refuses to run when a required action/probe is unsupported;
3. runs the existing scenario executor only after the proof surface is known;
4. preserves the executor's PASS/FAIL/PARTIAL/INFRA_ERROR result;
5. emits `scenario-proof.json` and `learning.json`.

The lower-level `globular-scenario` remains the execution engine. It is not the certification boundary by itself.

## Backward compatibility

Existing YAML `version: 1` scenarios remain valid.

A scenario with no `contract:` block is treated as a **legacy scenario**. Its runtime behavior is still capability-checked before execution, but its architectural claim is not as richly described as a new scenario.

New scenarios created for autonomous repair/evolution SHOULD declare `contract:`.

## Scenario contract block

Example:

```yaml
version: 1
name: controller-zombie-after-lease-loss
suite: resilience

contract:
  version: 1
  kind: exploration
  proves: >
    A controller that resumes after losing its leadership lease cannot perform
    externally visible mutations under stale authority.

  origin:
    type: simulation
    ref: frontier/zombie-controller

  governing_contracts:
    - controller.leased_leadership_single_writer

  invariants:
    - controller.only_current_authority_may_mutate
    - generation.stale_writer_cannot_commit

  known_failure_modes:
    - stale_authority
    - split_brain

  forbidden_outcomes:
    - stale controller writes desired state
    - two controller generations mutate concurrently

  determinism:
    replayable: true
    seed: zombie-controller-v1

  learning:
    enabled: true
    candidate_types:
      - failure_mode
      - invariant
      - scenario
```

### `contract.version`

Currently `1`.

### `contract.kind`

One of:

- `repair`
- `regression`
- `feature`
- `exploration`
- `certification`
- `training`
- `architecture_evolution`

Repair and feature work are two entrances into the same governed evolution lifecycle. The kind records why the scenario exists, not a different safety model.

### `contract.proves`

Human-readable claim the scenario is intended to establish.

This should describe a behavioral property, not an implementation detail.

### `contract.origin`

`type` is one of:

- `incident`
- `simulation`
- `feature`
- `manual`
- `regression`
- `architecture`
- `production`

`ref` is an optional durable identifier such as an incident id, change-envelope id, issue, design node, or discovered counterexample.

### `governing_contracts`

Contract identifiers that define correctness.

### `invariants`

Invariants the scenario is exercising or protecting.

### `known_failure_modes`

Previously known failure classes relevant to the scenario.

### `forbidden_outcomes`

States that must never be accepted as success even if local health probes look green.

This field is descriptive in Phase 1. Later state-space exploration can compile these declarations into semantic search targets.

### `determinism`

For generated/adversarial scenarios:

```yaml
determinism:
  replayable: true
  seed: 482991
```

If `replayable: true`, `seed` is mandatory.

The seed does not mean the distributed system itself is deterministic. It means the injected event schedule can be reconstructed.

### `learning`

```yaml
learning:
  enabled: true
  candidate_types:
    - failure_mode
    - invariant
    - condition
```

Supported candidate types:

- `failure_mode`
- `invariant`
- `condition`
- `principle`
- `scenario`
- `forbidden_fix`
- `required_evidence`

This declaration authorizes **candidate generation**, not promotion.

## Required action semantics

Every action in `steps:` and `cleanup:` is required by default.

```yaml
steps:
  - id: partition_node
    action: chaos.block_network
```

is equivalent to:

```yaml
steps:
  - id: partition_node
    action: chaos.block_network
    required: true
```

If the harness does not implement that action, the scenario result is `UNSUPPORTED`.

An action may explicitly be future/diagnostic-only:

```yaml
steps:
  - id: experimental_latency_profile
    action: chaos.netem
    required: false
```

An unsupported optional action is recorded in `scenario-proof.json` and excluded from proof. This should be rare. Cleanup actions should almost always remain required because restoration is part of harness safety.

There is no implicit "unknown means skip."

## Probe capability

Every referenced probe is checked against functions actually exported by `tests/harness/lib/probes.sh`, including probes nested inside `wait.until`.

A missing probe invalidates the proof before cluster mutation begins.

This closes an important hole where an unimplemented baseline probe could otherwise be treated as merely captured output.

## Artifacts

Every proof-boundary run produces or preserves:

### `evidence.json`

Existing runtime evidence generated by the scenario executor.

Its result remains the execution truth: `PASS`, `FAIL`, `PARTIAL`, `INFRA_ERROR`, or `UNSUPPORTED`.

### `scenario-proof.json`

Static + execution proof envelope:

- source revision
- scenario identity
- normalized contract
- supported capability set
- unsupported required/optional actions
- missing probes
- execution result
- whether this run is proof-eligible

### `learning.json`

Normalized simulation learning envelope.

It contains the proof claim, origin, governing contracts, invariants, failure modes, forbidden outcomes, deterministic replay metadata, failed observations, requested candidate types, and references to proof/evidence artifacts.

Crucially it records:

```json
{
  "authority": {
    "production_authoritative": false,
    "promotion_required": true
  }
}
```

This is the safety boundary between simulation learning and production behavior.

## Learning law

Simulation may autonomously produce:

```text
signal
  ↓
observation
  ↓
evidence
  ↓
contradiction
  ↓
candidate failure mode / invariant / condition / principle / scenario
```

But not:

```text
simulation
  ↓
production policy
```

The valid path is:

```text
simulation learning
       ↓
candidate knowledge
       ↓
evidence + contradiction testing
       ↓
Sensei / Behavioral Memory governance
       ↓
promotion decision
       ↓
production may rely on promoted knowledge
```

This allows behavioral memory to evolve continuously in the background without allowing the lab to become an accidental production authority.

## Audit command

The contract checker can audit a scenario or whole catalog without starting the cluster:

```bash
python3 tests/harness/lib/scenario_contract.py audit tests/scenarios
```

The audit exits non-zero if any scenario requires an unsupported action or refers to a missing probe.

This is intended to become a CI gate.

## Phase 1 acceptance criteria

Phase 1 is complete when:

1. normal scenario/suite execution passes through the proof wrapper;
2. unknown required actions cannot report PASS;
3. executor-declared but unimplemented required actions cannot report PASS;
4. missing probes are detected before mutation;
5. `wait.until` probes are included in capability checking;
6. legacy scenarios remain runnable;
7. contract-aware scenarios can declare deterministic replay and learning intent;
8. every run emits a non-authoritative learning envelope;
9. contract checker unit tests are green;
10. the whole catalog can be audited and unsupported scenarios are explicit.

## Next phases

Phase 1 deliberately does not implement semantic chaos itself.

### Phase 2 — richer chaos primitives

Examples: SIGSTOP/SIGCONT process pause, scoped asymmetric partitions, latency/loss/duplication/jitter via `tc netem`, CPU starvation, memory pressure/OOM, targeted etcd ENOSPC, artifact corruption, and deterministic application killpoints.

### Phase 3 — Change Envelope

Bind a repair/feature request to intent, contracts, authority scope, risk, required scenarios, implementation revision, simulation evidence, Sensei admission, release evidence, production verification, and learning outcome.

### Phase 4 — semantic adversarial exploration

Let the simulator choose event sequences while Sensei guides exploration toward architecturally dangerous states.

### Phase 5 — production-seeded digital twin

Fork a sanitized production state into the lab and explore plausible future failures without making production itself the experiment.
