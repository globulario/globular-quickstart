# `authority` — gray failure and the laws of who decides

Run with `make test-authority`.

## What this suite is for

The other suites ask **does the cluster survive failure?** They stop nodes, kill
services, fill disks, sever networks. The cluster is either up or down, and
recovery is the thing being measured.

This suite asks a harder question:

> **When the world becomes ambiguous, can Globular still prove who is allowed to
> decide what is true?**

Every scenario here injects a fault where nothing is cleanly dead. The machine is
alive, the processes are alive, packets move, old state still exists — and two
actors each hold enough internally consistent evidence to believe they are
authoritative. That is *gray failure*, and it is invisible to availability
testing because nothing is unavailable.

## Why the existing suites cannot reach these

| Existing scenario | What it proves | What it leaves open |
|---|---|---|
| `controller-service-crash` | the controller recovers | a killed process loses its memory and re-elects safely — the easy path |
| `network-partition-fencing` | an isolated node gets fenced | the **spatial** side only; a resumed process is not isolated |
| `full-cluster-blackout` | the cluster comes back | staggered restart lets one node win before others boot |
| `etcd-member-resync` | a member catches up on missed writes | a node that merely *lags*, not one holding an alternate history |
| `node-join-convergence` | a node returns and converges | it asserts the node was registered before — so, re-join |
| `disk-pressure-detection` | the cluster notices a full disk | detection, not **atomicity** of a write caught in that window |

## The scenarios

| Scenario | Fault | Must prove |
|---|---|---|
| `controller-zombie-after-lease-loss` | `SIGSTOP` the lease holder, let another take over and mutate, then `SIGCONT` | losing authority is **irreversible** for the instance that lost it |
| `rejoin-after-missed-generations` | stop a node, advance several generations, restart it | local state is **evidence**, never authority — it converges forward |
| `node-clone-identity-collision` | copy one node's whole state onto another and start it | two machines never share one identity |
| `etcd-enospc-during-state-commit` | fill etcd's filesystem, then attempt a real mutation | the mutation is atomic — committed or rejected, never half-published |
| `full-blackout-thundering-herd` | stop all five nodes, start all five **simultaneously** | exactly one authority emerges from identical starting conditions |
| `crash-during-mutation-is-atomic` | `SIGKILL` the controller mid-write | it never happened, or it converged **exactly once** |

## The one that matters most

`controller-zombie-after-lease-loss`, because `SIGKILL` cannot reach it.

A killed process loses its memory and comes back as a new instance that must
re-elect from scratch. A **stopped** process keeps every byte and wakes up still
believing it holds a lease that expired minutes ago, mid-way through whatever it
was doing — and it is not isolated when it wakes. It can reach etcd, it can reach
every service, and it has no local evidence that anything happened.

```
controller A owns lease generation 41
      ↓ SIGSTOP
lease expires
      ↓
controller B obtains generation 42, changes desired state
      ↓ SIGCONT
A wakes with perfectly coherent generation-41 memory
```

The question is not whether leader election works. It is whether **losing
authority is irreversible for the instance that lost it.**

## Primitives this suite added

Each verifies its own effect rather than trusting the call — a fault that did not
land makes a scenario vacuous, not lenient.

- `chaos.pause_service` / `chaos.resume_service` — `SIGSTOP`/`SIGCONT`, confirmed
  by reading `/proc/<pid>/status` for `State: T`
- `chaos.clone_node_state` — copy a node's persisted identity onto another volume
- `chaos.fill_etcd_volume` / `chaos.clear_etcd_volume_fill` — exhaust the
  filesystem etcd writes to, rather than the node's root disk
- `chaos.stop_all_nodes` / `chaos.start_all_nodes` — one invocation, so a
  bring-up is genuinely simultaneous
- `ops.set_desired` with `expect: accepted | refused | any` — a required refusal
  that silently succeeds **fails** the scenario
- `ops.remove_node` — the cluster-side half of removing a node
- probe `controller.leadership` — exposes the lease election, so a scenario can
  name the **authority instance** (`node:pid:instance-uuid`), not just the node
- probe `cluster.node_identity_collisions` — counts identities with more than one
  claimant, by id and by hostname

## Outcome taxonomy

This suite is why the harness gained `UNSUPPORTED`. A scenario that cannot
perform its own setup has **not** passed:

```
PASS          every assertion held and every step actually ran
FAIL          the cluster violated a property
PARTIAL       a step failed, so assertions were never reached
UNSUPPORTED   a required primitive does not exist — property NOT tested
INFRA_ERROR   the harness or environment broke; behaviour unknown
RESIDUE       the scenario leaked state it should have restored
POSTCONDITION the cluster was left worse than it was found
```

Only `PASS` certifies. On its first run, `controller-zombie-after-lease-loss`
returned `UNSUPPORTED` because `ops.*` actions were never routed to the
dispatcher — every assertion after the skipped mutation passed, so under the old
behaviour it would have reported a green zombie test **that never created a
zombie.** Two other scenarios were vacuous for the same reason.

## Not yet covered

The full killpoint matrix. `crash-during-mutation-is-atomic` kills at one
boundary; the matrix wants one run per durable transition —

```
publish → desired generation → dispatch → download →
install → service start → installed receipt → converged
```

— with only *never happened* or *converged exactly once* permitted at each. That
needs deterministic failpoints inside the services: from outside, the window
between "package installed" and "receipt written" is too small to hit reliably,
and a timing-based approximation would test whichever boundary it happened to
land on rather than the one it named.

Also open, from the same gray-failure family: asymmetric partitions (send but not
receive), `tc netem` packet loss and jitter, CPU starvation to distinguish *slow*
from *dead*, clock skew, RBAC revocation against a warm cache, CA and signing-key
rotation with a node offline, and repository blob corruption behind a valid
manifest.
