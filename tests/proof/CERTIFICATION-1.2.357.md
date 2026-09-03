# Certification — globular 1.2.355 → 1.2.357

Full 81-scenario run of the 1.2.355 distro on the quickstart simulation, the
defects it found, the fixes, and the re-run that validates them.

- Baseline under test: `dist/globular-1.2.355-linux-amd64` (cluster-controller 1.2.328, node-agent 1.2.331)
- Fixed build: `1.2.357` (cluster-controller **1.2.329**, everything else unchanged)
- Simulation: `globular-quickstart`, 5 nodes, Docker, one **cold boot per destructive suite** —
  `make clean && make up`, i.e. the real installer unpacking the real release tarball.
  No snapshots were used; nothing was carried between suites.
- Every row below names an evidence bundle under `tests/reports/`. Open it to re-check
  the claim without re-running anything. `tests/PROOF.md` is the machine-checkable form.

## 1. Baseline: 1.2.355, all 81 scenarios

| Suite | Result | Evidence run |
|---|---|---|
| smoke | 3 / 3 | `20260902T152322-smoke` |
| functional | 10 / 10 | `20260902T152526-functional` |
| security | 9 / 9 | `20260902T153308-security` |
| patterns | 5 / 6 — the 6th is the declared negative control | `20260902T153500-patterns` |
| soak | 5 / 5 | `20260902T154632-soak` |
| training | 5 / 5 | `20260902T162*-training` |
| recovery | 7 / 7 | `20260902T164450-recovery` |
| resilience | 13 / 13 | `20260902T173716-resilience` |
| **upgrade** | **11 / 12** | `20260902T185046-upgrade` |
| **authority** | **4 / 6** (4 PASS, 1 POSTCONDITION, 1 PARTIAL) | `20260902T203219-authority` |
| catastrophic | 5 / 5 | `20260902T220752-catastrophic` |

`residue-negative-control` is *supposed* to fail — it is the negative control for the
restoration law, and `globular-proof` classifies it `EXPECTED_FAIL`. It is not counted
as a defect anywhere in this document.

That leaves **three real defects in this run** — one in `upgrade`, two in `authority`.
Two more were found while validating the fixes (a Day-0 race exposed by the 1.2.356 build,
and a harness audit that disagreed with the gate it audits), and one of the `authority`
failures turned out to be two problems: a fixable one and an architectural gap that stays
open. Six items in total are documented below; each is stated with the measurement that
establishes it, the fix, and the proof the fix holds — or, for the one left open, why.

---

## Defect 1 — a DEFERRED release is never re-enqueued, so its own retry never runs

**Found by** `upgrade/platform-upgrade-release-boundary` → PARTIAL.
`release.audit` reported 24 releases: 19 succeeded, 0 failed, **5 pending**, and the
scenario's settle step polled for 600s without the count moving.

**Measurement.** From the evidence bundle's controller journal, the five —
`cluster-doctor`, `mcp`, `node-agent`, `resource`, `search` — entered `DEFERRED`
between 19:12 and 19:14 UTC and were still `DEFERRED` at 19:44 with no intervening
reconcile logged for any of them.

**Root cause.** `reconcileRelease` has a branch for `DEFERRED` (and for `WAITING`) that
waits `releaseWaitingBackoff` and then re-enters `PENDING` via `resumeDeferredRelease`.
That branch only runs when something enqueues the release, and the release work queue is
fed by etcd **watch events**. A release parked in `DEFERRED` writes nothing, so it emits
no event, so it is never reconsidered: the rescue code was unreachable in exactly the
state it exists to rescue. `requeueFailedReleases` — the periodic scan that exists
because "the watcher-driven work queue only fires on etcd changes" — handled
`FAILED`/`ROLLED_BACK` and transient-blocked `RESOLVED`, and `default: continue`d past
`DEFERRED` and `WAITING`.

The retry had appeared to work only while `selectReleaseTargets` kept re-deferring and
writing a status change on every pass. Once `markOutOfScope` stopped permanently
ineligible nodes from counting as deferrals, that watch-event ping-pong stopped standing
in for a scheduler, and one legitimate deferral became permanent.

**Fix.** `requeueFailedReleases` now also re-enqueues `DEFERRED` and `WAITING` releases
past `releaseWaitingBackoff`, for ServiceRelease and InfrastructureRelease alike. The
phase branch re-checks the backoff itself, so enqueueing early is harmless; the change
only guarantees the branch gets to run.
→ `golang/cluster_controller/cluster_controller_server/release_reconciler.go`

**Tests.** `release_deferred_requeue_test.go` — six cases, including a negative control
(inside-backoff must NOT requeue) and a terminal-phase control (AVAILABLE must not be
requeued). Verified to fail without the fix: 3 of 6 fail, `enqueued=[]`.

**Field proof.** On 1.2.357 the same scenario is **PASS 9/9**, with
`release.audit` = 24 succeeded / 0 failed / **0 pending** (1.2.355: 19 / 0 / 5).
→ `20260903T002024-upgrade/platform-upgrade-release-boundary`

*Stated precisely:* the 1.2.357 journal shows no ServiceRelease parked in `DEFERRED` at
all, so that run demonstrates the condition is gone rather than demonstrating the new
branch rescuing a release. The branch itself is proven by the unit tests and their
negative control.

**Forbidden fix recorded:** counting `DEFERRED` as settled in `release.audit`, or
relaxing the scenario to allow `pending > 0`. Either makes the scenario green without
restoring the retry, and would equally hide a genuinely undispatchable release.

---

## Defect 2 — the stale-member prune evicts a live etcd voter (severity: high)

**Found by** `authority/node-clone-identity-collision` → POSTCONDITION.
Every assertion passed — no duplicate identity was admitted — but the cluster did not
return to baseline: `etcd_member_count` 5 → 4 and `etcd_healthy_endpoints` 5 → **3**.

**Measurement.** Re-run in isolation on a freshly cold-booted cluster with the etcd
member list sampled every 15s (`.runlogs/members-clone-isolation.log`):

```
22:37:22  5 members: node-1..node-5
22:42:18  removeStaleNodesLocked: removing duplicate/stale node 35ac3821 (same host as 6400b443)
22:42:24  etcd member-remove: removed stale member node-4 (id=2263181996067307296,
                                                           peer=[https://10.10.0.14:2380])
22:44:54  etcd member-remove: removed stale member node-5
22:45:58  a NEW unstarted member 113b1bd9e0619ed6 appears for 10.10.0.14
22:47:21  node-4 etcd: "rejected Raft message to mismatch member"
          (local-member-id 1f687008d9a6bf20, mismatch-member-id 113b1bd9e0619ed6)
          → globular-etcd.service: Deactivated successfully
```

**node-4 was healthy, voting, and untouched by the scenario.** The scenario stops and
clones *node-5*. One container started with a copy of another node's identity cost the
cluster a control-plane member, and node-4 could not come back: the later re-add minted
a new member id while its data dir still held the old one.

**Root cause.** `removeStaleMembers` infers "ghost" from the controller's node records —
a member whose peer URL and hostname appear in no desired node record is removed. Those
records can be wrong. The impostor took over node-4's node record, the record's IP became
the impostor's, and node-4's live peer URL then matched nothing. A quorum-reducing action
was taken on an inference rather than on evidence. Same class as
`etcd.auto_rejoin_leader_guard_fails_open`, which was repaired into failing closed.

**Fix.** The per-member decision is now a pure function, `classifyStaleMemberAction`,
whose strongest verdict is `staleMemberCandidate` — it cannot conclude "remove". Removal
additionally requires evidence *from the member*: `memberIsResponding` dials the member's
own client URL and asks for its status. A member that answers is not a ghost, whatever the
node view says, and the prune refuses it loudly. Fail-closed: no client URLs, unreachable,
or any error ⇒ "not responding", so genuine ghosts stay prunable.
→ `golang/cluster_controller/cluster_controller_server/etcd_members.go`

**Tests.** `etcd_stale_member_guard_test.go` — the exact 1.2.355 shape classifies as a
candidate and not a removal; six protected cases (unstarted, join-in-flight, desired peer
URL, hostname fallback, peer-URL update, already-correct); and a fail-closed check on the
liveness probe.

**Field proof.** On 1.2.357, in the same scenario, the controller reaches the *same wrong
premise* and refuses to act on it:

```
02:47:14  etcd member-remove: REFUSING to prune member node-4 (peer=[https://10.10.0.14:2380])
          — it is a live, responding member and no node record claims it. …
02:47:47  etcd member-remove: removed stale member node-5 (peer=[https://10.10.0.15:2380])
```

node-5 — actually stopped and cloned — is still pruned, so ghost cleanup is intact. The
ring goes 5 → 4 instead of 5 → 3, and **node-4 survives as a voter**:

| | 1.2.355 | 1.2.357 |
|---|---|---|
| `etcd_healthy_endpoints` after | 3 | **4** |
| node-4 (untouched, legitimate) | evicted, etcd dead | **alive, voting** |

---

## Defect 2b — OPEN: a node removed from the ring while down has no path back

`node-clone-identity-collision` still ends POSTCONDITION on 1.2.357, now for a single
narrower reason: node-5 — the node the scenario legitimately stopped — is out of the ring
and nothing re-admits it. The controller's join driver is deliberately observe-only for
`EtcdJoinNone`/`EtcdJoinFailed` ("the join script on the node handles MemberAdd directly …
this avoids dangerous controller-initiated MemberAdd calls"), and the auto-rejoin path
that does call `MemberAdd` mints a new member id while the returning node's data dir still
carries the old one — which is what killed node-4 on 1.2.355.

This is **not fixed here, and not silently skipped**. It is the same gap 1.2.353 and
1.2.354 both recorded and left open ("re-adding a removed member to the etcd ring is the
controller's decision, not the node's"). Closing it means a returning node reinitialising
its etcd data directory under a new member id — a destructive operation on cluster state,
governed by `objectstore.destructive_changes_require_approval` in spirit, and a
release-lifecycle decision that should be made on its own merits rather than as a fourth
change in a validation run. **Recommendation:** decide between (a) the node-agent
reinitialising its data dir when the controller re-admits it under a new member id, and
(b) the controller refusing to `MemberAdd` a node whose local member id it cannot reconcile,
and surfacing `rejoin_required` instead of half-repairing.

Related gap observed and worth recording: a node that was `EtcdJoinVerified` and then
disappears from the member list is never re-evaluated — neither re-joined nor classified
`rejoin_required`. The only symptom is `renderEtcdConfig: … is not an etcd member yet —
skipping etcd.yaml render until MemberAdd puts it in the ring`, repeating indefinitely.

---

## Defect 3 — a best-effort probe aborts a completed Day-0

**Found by** the 1.2.356 validation build: all five nodes stalled at
`bootstrap-complete=0/5` for 35 minutes.

**Measurement.** `install-day0.sh` printed `✓ INSTALLATION COMPLETE` and its Next-steps
block; `install.sh` then exited 1 **without printing its own** "Corrected bootstrap
command" block, and the quickstart wrapper reported `[bootstrap] FATAL: Day-0 install.sh
failed`. `globular-node-agent`'s `ActiveEnterTimestamp` on node-1 was **23:24:47** — the
same second install.sh died.

**Root cause.** `install.sh` runs under `set -euo pipefail` and probes for the node-agent's
listening port to print a friendlier bootstrap command:
`PORT=$(ss -ltnp | awk … | grep -E '^11000$' | head -n1)`. Each probe has an explicit
`if [[ -z ]]` fallback below it — the author asserting that an empty result is normal — but
under `pipefail` a `grep` that matches nothing exits 1, the assignment inherits that status,
and the script dies before reaching the fallback. Day-0 itself tells the operator to start
the node agent as a *next* step, so "not listening yet" is the expected state there. The
installer had been winning a race, not handling a state: the same six cold boots on 1.2.355
all won it.

**Fix.** `|| true` on the four best-effort substitutions, making the fallbacks reachable as
written. → `scripts/install.sh`

**Reproduction and proof.**
`bash -c 'set -euo pipefail; P="$(echo | grep -E "^11000$" | head -n1)"'` → exit 1;
with `|| true` → exit 0 and the fallback runs. 1.2.357 cold-booted 5/5 on every attempt.

**Sibling found by the principle, not by a failure.** Searching for the same shape across
`scripts/` turned up `scripts/deploy-service.sh:197`: `ls -t <glob> | head -1` under the
same flags (ls exits 2 on no match), with an underscore-named fallback two lines below that
was unreachable whenever the dash-named glob missed. Fixed the same way.

**Forbidden fix recorded:** leaving a best-effort probe unguarded because it usually
matches; and "fixing" an instance by widening the probe, sleeping before it, or dropping
`pipefail` for the whole script.

---

## Defect 4 (harness) — a handover deadline scored as a control-plane refusal

**Found by** `authority/controller-zombie-after-lease-loss` → PARTIAL on 1.2.357, having
passed on 1.2.355. Chased as a suspected regression from the controller changes.

**It is not one.** The failing item is a *step*, not an assertion — every assertion passed
in every run — and the error is
`UpsertDesiredService: rpc error: code = DeadlineExceeded` at **attempt 1 of 6**. The
scenario freezes the leader, waits a fixed 180s, then writes desired state; a controller
elected moments earlier is not yet serving mutations. The same cluster answered the
identical call in **0.22s** once settled, and an isolated repeat of the scenario passed.

`ops.set_desired` already carries a six-attempt retry budget for exactly this — but it is
gated on `_is_transient_control_plane_refusal`, whose marker list did not include this
surface message, so the retry never fired. The function's own docstring records the
previous instance of the same gap ("the retry budget existed but only 'resolvable kind'
could reach it, so a self-healing leadership transition was recorded as a control-plane
refusal").

**Fix.** One marker added, scoped to that single RPC
(`upsertdesiredservice: rpc error: code = deadlineexceeded`) so a timeout anywhere else
cannot be laundered through the list. The attempt count stays in the evidence, so a
deadline that stops clearing is still visible as 6/6.
→ `tests/harness/bin/globular-scenario`

**Proof.** 4 of 4 isolated runs PASS after the change (1 of 3 before).

No assertion was weakened. The same signature accounts for one of the two remaining
failures in `rejoin-after-missed-generations` on 1.2.357 (`advance_generation_2`,
attempt 2 of 6).

---

## Defect 5 (harness) — the schema audit disagreed with the gate it audits

`globular-test check schemas` reported `controller-zombie-after-lease-loss` as
**UNSUPPORTED** (`chaos.pause_service`) while the runner executed it fine. The audit used
the base capability set (`scenario_contract.py`); the proof boundary uses
`scenario_contract_semantic.py`, which additively registers the semantic-chaos actions.
An audit that disagrees with the gate it audits is worse than no audit.

**Fix.** The audit now asks the same contract the runner enforces.
→ `tests/harness/bin/globular-test`. Result: **81 supported, 0 unsupported, 0 invalid**
(was 80/1/0). All four harness unit-test files still pass.

---

## 2. Result on 1.2.357 — full 81-scenario re-run

Every suite re-run on 1.2.357, one cold boot per destructive suite, same discipline as
the baseline. `upgrade` is the earlier 1.2.357 run (same build, same method).

| Suite | 1.2.355 | 1.2.357 | Evidence run |
|---|---|---|---|
| smoke | 3 / 3 | 3 / 3 | `20260903T043716-smoke` |
| functional | 10 / 10 | 10 / 10 | `20260903T043810-functional` |
| security | 9 / 9 | 9 / 9 | `20260903T044829-security` |
| patterns | 5 + control | 5 + control | `20260903T045031-patterns` |
| soak | 5 / 5 | 5 / 5 | `20260903T045131-soak` |
| training | 5 / 5 | 5 / 5 | `20260903T053054-training` |
| recovery | 7 / 7 | 7 / 7 | `20260903T054902-recovery` |
| resilience | 13 / 13 | 13 / 13 | `20260903T063640-resilience` |
| **upgrade** | 11 / 12 | **12 / 12** | `20260903T002024-upgrade` |
| **authority** | 4 / 6 | 4 / 6 | `20260903T074709-authority` |
| catastrophic | 5 / 5 | 5 / 5 | `20260903T092522-catastrophic` |
| **total** | **77 / 81** | **78 / 81** | `tests/PROOF.md` — 1171 checks |

`tests/PROOF.json` records the same result machine-checkably:
`{"PASS": 78, "POSTCONDITION": 1, "PARTIAL": 1, "RESIDUE": 1}`, `release_under_test: 1.2.357`.

### The two remaining non-PASS results are one defect

Both are `authority`, and both reduce to **Defect 2b** — the open gap above.

- `node-clone-identity-collision` — POSTCONDITION 19/20. The only failing check is the
  fingerprint: node-5, which the scenario legitimately stopped, is out of the ring and
  nothing re-admits it. Every assertion passes, and node-4 now survives (Defect 2).
- `rejoin-after-missed-generations` — PARTIAL 16/20 **inside the suite**, where it runs
  directly after the scenario above. Its three `ops.set_desired` steps are refused
  6 attempts out of 6 with *"repository instance … reported no published version with a
  resolvable kind"*, and `no_doctor_errors` reports 5 ERRORs — both consistent with
  node-5's repository instance being unreachable because node-5 is out of the ring.

  **Run in isolation on a freshly cold-booted cluster it PASSES**
  (`20260903T095501-rejoin-after-missed-generations`). So it is carry-over, not an
  independent defect. The proof record above deliberately keeps the *suite* result rather
  than the isolated one, because scenario results are order-dependent and a proof record
  should compare under matched order; this paragraph is the attribution, not a substitute
  for it.

Closing Defect 2b is therefore expected to take both remaining scenarios green. Nothing
else in the 81 is failing.

### Regression check

No scenario that passed on 1.2.355 fails on 1.2.357. `controller-zombie-after-lease-loss`
went PASS → PARTIAL when first re-run and was chased as a suspected regression from the
controller changes; it is Defect 4 (harness), now PASS in 5 of 5 subsequent runs
(3 isolated + 1 isolated earlier + 1 in-suite), and the controller answers the RPC in
0.22s in steady state.


## 3. What was recorded for next time

Written to the awareness graph (`docs/awareness/`, staged for review), each linking an
invariant, naming its required test, and carrying the measurement:

| Kind | Entry |
|---|---|
| failure_mode | `failure.a_deferred_release_is_never_re_enqueued_so_its_own_backoff_r` |
| forbidden_fix | `forbidden_fix.count_deferred_as_a_settled_release_so_the_boundary_assertio` |
| failure_mode | `failure.the_stale_member_prune_evicts_a_live_etcd_voter_when_an_impo` |
| failure_mode | `failure.a_best_effort_probe_in_install_sh_aborts_a_completed_day_0_w` |
| forbidden_fix | `forbidden_fix.leave_a_best_effort_probe_unguarded_under_set_euo_pipefail_b` |

`mcp__globular__*` could not be reached during this session, so nothing was written to
ai-memory or behavioural-memory; the scenario harness still wrote its own `learning.json`
per scenario and appended to `tests/reports/awareness-training-ledger.jsonl`.

## 4. Known-unclean, unrelated to this work

`make check-services` fails with four pre-existing artifact/source-authority violations
(missing `globular-installer` mirrors, a `packages/metadata/sql/specs` spec path, and an
`embeddata` allowlist entry). They are independent of every change here and were failing
before it; they are reported rather than absorbed.
