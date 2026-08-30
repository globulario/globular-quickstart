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

## Open: crash-during-mutation-is-atomic

Newly failing on 1.2.354 (`let_interrupted_release_reach_terminal_state` timed out,
3 releases pending), having passed on 1.2.353. **Attribution is unresolved.**

Against it being the settle change: `upgrade` is 12/12 including the release-heavy
scenarios (`package-upgrade`, `platform-upgrade`, `rollback-guard`,
`deploy-publish-then-converge`), so release convergence is not broadly slowed.

Not yet ruled out: this scenario kills the controller mid-mutation, a path the
upgrade suite does not exercise, and it is inherently timing-sensitive.

An early count of "0 settle events in this scenario" is NOT evidence — that
scenario's journal capture ends at 14:26, before the failure window, so the count
was taken over the wrong interval. An isolated repeat is running to get a second
data point; one observation of a timing-sensitive scenario is not enough to call it
either way.

## Net

Two root causes diagnosed on 1.2.353; one fully fixed and validated (+3 scenarios),
one correctly reported but still open at its true owner. One new failure, honestly
unattributed pending a repeat.
