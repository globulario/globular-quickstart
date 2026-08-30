# Validation — globular 1.2.354 (node-agent 1.2.331)

1.2.353 diagnosed five real failures reducing to two root causes. This run tests
whether the fixes for them work, on live infrastructure, in the binaries.

Three suites, each on its own fresh five-node cluster gated on 5/5 `workload_ready`:
the two suites that failed, plus `upgrade` as a regression control because it was
clean at 12/12 and must stay there.

## Result

| Suite | 1.2.353 | 1.2.354 | |
|---|---|---|---|
| resilience | 10 PASS / 3 FAIL | **13 PASS / 0 FAIL** | fixed |
| upgrade | 12 PASS / 0 FAIL | **12 PASS / 0 FAIL** | no regression |
| authority | 4 PASS / 2 FAIL / 1 PARTIAL | 3 PASS / 3 FAIL / 2 PARTIAL | see below |

## Fix 2 — node-presence key reconciliation: VALIDATED

The direct measurement, taken on both fresh clusters before any scenario ran:

    /globular/nodes/*/node_agent_metrics_port  →  5 of 5   (1.2.353: 4 of 5)

`compute-node-stop-restart` went FAIL → PASS, with `all_nodes_present` passing where
it had failed at preconditions. `controller-service-crash` and
`node-agent-crash-recovery`, which had inherited that count, also pass. The whole
suite is now 13/13 — and on a genuinely five-node cluster, so it is a stronger
result than 1.2.353's 10 passes, which ran degraded.

## Fix 1 — repair settle verification: WORKS AS DESIGNED, does not fix authority

The false success is gone. From node-5's journal in `rejoin-after-missed-generations`:

    1.2.353   install-package etcd: repair via Enable+Start succeeded      (etcd dead 5s later)
    1.2.354   install-package etcd: repair via Start did not hold,
              proceeding with full reinstall                                × 14
    1.2.354   install-package scylla-manager-agent: repair via Enable+Start
              succeeded (still active after 15s)                            ← genuine repair still passes

So it refuses the false claim without refusing legitimate repairs — the negative
control holds in production, not just in the unit test.

It does not make the scenario pass, and was never going to: the fix stops the node
lying about the repair, but the underlying condition — a node removed from the etcd
ring while down has no path back — is a controller-side MemberAdd concern that
remains open. `rejoin-after-missed-generations` and `node-clone-identity-collision`
still fail for that reason, with the same symptoms as before.

## Fix 3 — Scylla token fail-closed: NOT EXERCISED

No node hit the unreadable-domain/CA path in these runs, so the change is
unvalidated in the field. It stands on its unit test and on reasoning.

## Resolved: crash-during-mutation-is-atomic is NOT a regression

Newly failing on 1.2.354 having passed on 1.2.353, so it was treated as a
suspected regression from the settle change and chased until settled.

**It is not.** Two independent lines of evidence:

*The settle code never ran.* In an isolated repeat on a fresh 1.2.354 cluster
(which reproduced the failure, so it is not carryover), all 8 repair attempts in
the window were `minio` and all 8 took the early-return "topology hold — leaving
held, not repairing" branch. None reached `supervisor.Start`, so `holdsActive`
was never called. That journal covers 18:20–18:39, spanning the 18:35–18:40
scenario — unlike an earlier count of mine, which was taken over a window ending
before the failure and proved nothing.

*The mechanism predates the fixes.* The controller blocks release phase
transitions its own callers attempt, and the same blocks appear throughout the
1.2.353 bundles (00:10, 03:18, 09:39), all before the node-agent commits:

    AVAILABLE → RESOLVED   109        FAILED → RESOLVED    14
    FAILED    → AVAILABLE   23        RESOLVED → PENDING    5

`MarkReleaseResolved` patches straight to RESOLVED from whatever phase a release
is in, but `validPhaseTransitions` only allows `FAILED → PENDING` ("re-apply").
So a FAILED release given a fresh workflow can never record progress and stays
FAILED — which is the assertion that fails: `no_release_left_failed` "expected 0,
got 15", with all fifteen already FAILED at the instant the scenario began.

The scenario passed on 1.2.353 by timing, not because the defect was absent. A
single green run had been read as evidence the path was sound; it was not.

Recorded as `failure.release_phase_machine_rejects_transitions_its_own_callers_ro`.
Not fixed: choosing between "dispatch routes FAILED→PENDING first" and "the
machine admits what its callers need" is a release-lifecycle decision with real
blast radius, and it should be made on those counts rather than as a fourth
unvalidated change.

## Net

Two root causes diagnosed on 1.2.353; one fully fixed and validated (+3 scenarios),
one correctly reported but still open at its true owner. One new failure, honestly
unattributed pending a repeat.
