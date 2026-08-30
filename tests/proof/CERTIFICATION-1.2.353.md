# Certification — globular 1.2.353

Every suite ran on its own freshly built five-node cluster (`make clean && make up`),
gated on 5/5 `workload_ready` before any scenario executed. Suites therefore cannot
inherit damage from one another. Within a suite, scenarios still share a cluster —
which matters for reading the resilience result below.

Driver: `certify353.sh`. Raw logs: `c353-<suite>.log`, results: `certify353-results.txt`.
Run window: 2026-08-30 04:53–13:31 UTC.

## Result

| Suite | Scenarios | PASS | FAIL |
|---|---:|---:|---:|
| smoke | 3 | 3 | 0 |
| functional | 10 | 10 | 0 |
| security | 9 | 9 | 0 |
| patterns | 6 | 5 | 1 † |
| training | 5 | 5 | 0 |
| soak | 5 | 5 | 0 |
| upgrade | 12 | 12 | 0 |
| authority | 6 | 4 | 2 |
| resilience | 13 | 10 | 3 |
| recovery | 7 | 7 | 0 |
| catastrophic | 5 | 5 | 0 |
| **Total** | **81** | **75** | **6** |

† `residue-negative-control` is the tree's one deliberate negative control: it asserts
that a scenario which passes every assertion but leaks state is still failed by the
runner. Its FAIL is the correct outcome, and its passing would mean the harness had
stopped detecting residue. A perfect run is therefore **80 PASS + 1 intentional FAIL**,
not 81 PASS.

So: **5 real failures out of 80**, and they reduce to **two root causes**, both diagnosed
from evidence and both now fixed in source (neither fix is in the 1.2.353 binaries — they
await the next build).

## Root cause 1 — repair reports success for a unit that dies seconds later

Fails `node-clone-identity-collision` and `rejoin-after-missed-generations`.

From node-5's node-agent journal:

    10:52:20  install-package etcd: repair via Enable+Start succeeded
    10:52:20  service.started  globular-etcd.service (inactive/dead → active/running)
    10:52:25  service.stopped  globular-etcd.service (active/running → inactive/dead)

`supervisor.WaitActive` returns on the first active reading, so it proves the unit
*became* active, not that it *stayed* active. etcd reports "I am no longer a member of
this ring" by exiting 0 after ~650ms, which systemd records as "Deactivated
successfully" — so `Restart=on-failure` never fires and the condition needing attention
is the one that looks most like success. A success convergence result was written for a
package that was not running, and the same false success repeated three times on one node
in a single run without ever converging.

Fixed: repair now requires the unit to hold active through a settle window
(`holdsActive`, `grpc_workflow.go`), else it falls through to the full reinstall it
already had. Deliberately not fixed here: re-adding a removed member to the etcd ring is
the controller's decision, not the node's.

## Root cause 2 — node-presence key written once, never reconciled

Fails `compute-node-stop-restart`, `controller-service-crash`, `node-agent-crash-recovery`.

All three fail identically — `count: expected >= 5, got 4` — and the first fails at its
PRECONDITIONS, before executing a step; the other two inherit the count. All five
containers were running. Node `c8a09d9e` held its complete package key set and was missing
exactly one key: `/node_agent_metrics_port`.

That key decides whether a node exists: `probe_cluster_nodes` counts members by grepping
`/node_agent_metrics_port$`. It is published once, fire-and-forget with a 3s etcd timeout,
at identity adoption — during a join. One lost Put is permanent. This is the second time
the class has shipped; `server.go:1610` already records it as 1.2.340's
"expected >= 5, got 4" failing three scenarios.

Fixed: the key is reconciled on the heartbeat as an observation the node makes about
itself, read-then-write so a correct key is untouched (`ensureMetricsPortPublished`).

## Caveat on the resilience result

Because `compute-node-stop-restart` fails at preconditions, that suite ran its remaining
scenarios against a cluster the harness considered four-node. The 10 passes there are
therefore weaker evidence than the same count elsewhere, and resilience should be re-run
once root cause 2 is in a build. The other ten suites started from a verified 5/5 cluster.

## What this run is evidence for, and what it is not

It is evidence that on 1.2.353 the upgrade path is clean end to end — 12/12 including
`first-join-from-clean-node`, `package-upgrade`, `platform-upgrade`,
`rejoin-with-stale-membership` and `liveness-survives-state-writes`, the set that was
8 PASS / 4 FAIL / 2 PARTIAL on the previous attempt — and that security, recovery and
catastrophic are clean.

It is not evidence that the two fixes above work. They were written after this run and
are unvalidated on live infrastructure. That is the next run's job.
