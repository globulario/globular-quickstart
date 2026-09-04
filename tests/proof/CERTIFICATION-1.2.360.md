# Certification — globular 1.2.359 → 1.2.360

Full 81-scenario run of the 1.2.360 distro on the quickstart simulation: what
the 1.2.359 run found, what was fixed, and — stated separately — which of those
fixes this campaign actually proves.

- Under test: `dist/globular-1.2.360-linux-amd64`, built by `scripts/build-release.sh 1.2.360`
- Tree certified: `980030ca` + the working-tree patch snapshotted at campaign start
  (`certified-1.2.360-worktree.patch`, md5 f74fde6c87fdbf673730feb31e4938dc)
- Simulation: `globular-quickstart`, 5 nodes, Docker, **one cold boot per
  destructive suite** — `make clean && make up`, the real installer unpacking the
  real release tarball. No snapshots; nothing carried between destructive suites.
- Driver: `scripts/certify-release.sh 1.2.360` — builds the image once, never
  aborts on a red suite, and refuses to publish a proof table containing any row
  older than the campaign start.
- Every row names an evidence bundle under `tests/reports/`. `tests/PROOF.md` is
  the machine-checkable form.

## 1. Results

| Suite | Result | Evidence run |
|---|---|---|
| smoke | 3 / 3 | `20260903T165748-smoke` |
| functional | 10 / 10 | `20260903T170048-functional` |
| security | 9 / 9 | `20260903T170937-security` |
| patterns | 5 / 5 + declared negative control | `20260903T171136-patterns` |
| training | 5 / 5 | `20260903T171237-training` |
| **soak** | **3 / 5** | `20260903T171346-soak` |
| recovery | 7 / 7 | `20260903T181200-recovery` |
| resilience | 13 / 13 | `20260903T190003-resilience` |
| **upgrade** | **11 / 12** (1 PARTIAL) | `20260903T201125-upgrade` |
| **authority** | **4 / 6** | `20260903T213704-authority` |
| catastrophic | 5 / 5 | `20260903T231228-catastrophic` |

**Totals: 75 / 81 scenarios PASS, 1171 checks.** `tests/PROOF.md` and
`tests/PROOF.json` are the machine-checkable form, regenerated from the
evidence bundles after the last suite.

`residue-negative-control` is *supposed* to fail — it is the negative control
for the restoration law. It appears in the proof table as
`🟦 expected-fail (expects RESIDUE)`, classified rather than hidden, and is not
counted as a defect.

The proof table is scoped to this campaign: it references exactly 11 runs,
oldest `20260903T165748`, newest `20260903T231228`, and the driver's stale-row
check reported none. No row is inherited from an earlier run.

### The five rows that need work

| suite | scenario | result | checks |
|---|---|---|---|
| authority | node-clone-identity-collision | POSTCONDITION | 19/20 |
| authority | rejoin-after-missed-generations | POSTCONDITION | 17/20 |
| soak | etcd-backend-growth-trend | FAIL | 11/12 |
| soak | heartbeat-age-stays-under-threshold | FAIL | 11/12 |
| upgrade | deploy-publish-then-converge | PARTIAL | 17/18 |

Every one is accounted for below. None was skipped, quarantined, retried until
green, or re-baselined.

## 2. The three fixes shipped in 1.2.360 — and what this run proves about each

### Fix 1 — bounded release re-dispatch → **CONFIRMED, with a positive control**

Evidence: `20260903T171346-soak/etcd-backend-growth-trend/evidence/journal/`,
a 24-minute controller journal (17:16:31 → 17:40:53) across all five nodes.

- 10 dispatch *attempts* in the whole window, all releases combined. The
  1.2.359 pathological figure was **169 in five minutes for a single release**,
  with bursts of 118 log lines per second.
- The guard did not merely stay quiet — it **fired**. At 17:22:48 the
  controller dispatched `log`, `ai-router` and `file`; at 17:22:49 it re-entered
  for the same three and each was stopped:

      release-workflow: ServiceRelease/core@globular.io/log       dispatch held for another 29s
      release-workflow: ServiceRelease/core@globular.io/ai-router dispatch held for another 29s
      release-workflow: ServiceRelease/core@globular.io/file      dispatch held for another 29s

  Three re-entries, three holds, no workflow RPC and no `waveStateBlocked`
  write — so no etcd event and no re-trigger. That is the exact loop that ran
  away on 1.2.359, caught at the first turn.
- Counting note: the `dispatching release workflow across` line is printed
  before `RunPackageReleaseWorkflow` is entered, so it counts attempts.
  Attempts 8–10 are the three held ones; actual workflow runs: 7.

### Fix 2 — the etcd wipe refuses without controller-supplied membership → **CONFIRMED, with a positive control**

Exercised in `authority/rejoin-after-missed-generations`. The decisive line is
the one the fix adds — the node agent rewriting `initial-cluster` from the
membership the controller rendered, *before* it wipes:

    22:44:24 wipe-etcd-and-rejoin: starting etcd data wipe and rejoin
    22:44:24 wipe-etcd-and-rejoin: stopped globular-etcd.service
    22:44:24 wipe-etcd-and-rejoin: set initial-cluster=node-4=https://10.10.0.14:2380,
             node-5=https://10.10.0.15:2380,node-2=https://10.10.0.12:2380,node-3=...
    22:44:24 wipe-etcd-and-rejoin: wiped /var/lib/globular/etcd/member
    22:44:24 wipe-etcd-and-rejoin: completed successfully in 181ms

Same scenario, both builds, from the two bundles:

| | 1.2.359 | 1.2.360 |
|---|---|---|
| `set initial-cluster` emitted by the agent | **0** | **1** |
| wipe attempts for node-5 | 4 (14:08:49 SUCCEEDED, 14:11:57 and 14:15:23 RPC Unavailable, 14:18:49 SUCCEEDED) | **1** (22:44:24) |
| `member count is unequal` | — | **0** |
| node-5 etcd after the wipe | never returned; re-wiped on the 3-minute cooldown | `published local member to cluster through raft`, `ready to serve client requests`, `serving client traffic securely` |
| ring | stayed at 4 | **returned to 5** |

On 1.2.359 the workflow reported `status=SUCCEEDED` while the node never came
back, and the cooldown re-issued the destructive wipe indefinitely. On 1.2.360
the wipe carried the live ring's membership, ran **once**, and the member
rejoined and served. That is the defect and its repair, measured end to end.

**Correction.** An earlier reading of this campaign recorded Fix 2 as
"unexercised". That was wrong: the check was scoped to the
`node-clone-identity-collision` bundle alone, where the path genuinely was not
entered, and generalised from one scenario to the whole suite. Running the
verification commands in §6 across all six authority bundles is what surfaced
the three `etcd auto-rejoin` lines and the seven wipe mentions that corrected
it.

### Fix 3 — `services desired set` stops blaming the publisher for its own RPC failures → **CONFIRMED, and it immediately earned its keep**

`20260903T201125-upgrade/deploy-publish-then-converge/evidence.json`:

    Error: cannot verify the kind of dns (repository unreachable: rpc error:
    code = Unauthenticated desc = cluster_uid required after cluster initialization)

On 1.2.359 the identical condition read *"the repository reported no published
version with a resolvable kind … publish it, then retry"* — about a package
published and installed on all five nodes. The verdict was right both times
(fail closed); only now is the cause nameable. That one message converted a
"flaky publish" into defect 5 below, in a single run.

## 3. Defects found

| # | Where | Status |
|---|---|---|
| 4 | soak — node agent's cached etcd client certificate | **FIXED** in tree (1.2.361), not yet field-proven |
| 5 | upgrade + authority — CLI cannot prove cluster membership | **OPEN**, filed as contract_unknown |
| 6 | authority — the restoration postcondition gives up before the working repair completes | **HARNESS**, not a product defect |
| T1 | harness — `cert-expiry-detection` passes a repair the product declared failed | **OPEN**, harness-side |

Full write-ups: `defect-4-soak.md`, `defect-5-cluster-uid.md`,
`defect-6-authority.md`.

### Defect 6 — the postcondition window is shorter than the repair cycle

`node-clone-identity-collision` fails its restoration postcondition
(`etcd_healthy_endpoints 5 → 4`) identically on 1.2.359 and 1.2.360. The cause
is not a broken repair. It is timing:

- `_verify_postconditions` in `globular-scenario` polls for a hardcoded
  **120 seconds**.
- The controller's auto-rejoin cycle is far longer: node-5's etcd was
  deactivated at 22:36:37, MemberAdd landed at **22:41:01** (~4.5 min later)
  and the wipe executed at **22:44:24** (~7.8 min later). The dispatch cooldown
  alone is 3 minutes.

So the scenario declares failure while a working repair is still in flight, and
the ring does come back — during the *next* scenario, which is why
`rejoin-after-missed-generations` captured `baseline=4` and then "failed" by
healing to 5.

Fix: give the restoration gate a per-scenario window that accommodates the
repair it is waiting on, rather than one 120s constant for every scenario. Both
authority rows should then resolve, and the second one's contaminated baseline
disappears with them.

**Correction.** This was first written up as "a pruned etcd member has no path
back into the ring — nothing performs the MemberAdd". That is false:
`etcd auto-rejoin: MemberAdd succeeded for … (node-5)` is right there in the
controller journal at 22:41:01. The claim came from grepping one scenario's
bundle, finding zero, and generalising. The awareness entries filed on that
basis have been corrected.

### The shape underneath 4 and 5

Both are the same failure: **a repair path gated on the very condition it
repairs.**

1. Wedged etcd client → the only `ResetEtcdClient` caller is the endpoint-list
   refresh → which reads the endpoint key *through the wedged client*.
2. CLI needs `cluster_uid` to be recognised → obtained via etcd → which needs
   the cluster keypair only members can read.

Filed as a failure_mode with both instances and flagged for promotion to a
`meta.*` principle with a scanner: the shape is mechanically detectable as
"recovery routine R is reachable only via predicate P, and R is what makes P
true". A third candidate instance was withdrawn — see defect 6 above.

## 4. Corrections made to this analysis during the campaign

Recorded because the corrections are load-bearing, and because a certification
that hides its wrong turns is worth less than one that shows them:

- **"node-3's etcd was active throughout"** — wrong. It crash-looped through six
  PIDs, then stabilised. The stabilisation is what makes the diagnosis work: 95
  of 104 probe failures happened *after* it.
- **"the probe fabricates four endpoint errors it never measured"** — overreach.
  The peers *were* contacted. The shared-deadline defect is real but is a
  diagnostic-quality problem, not the root cause. Stated as proven before the
  peer logs were checked.
- **"`tls: client didn't provide a certificate` is cluster-wide, so not an
  explanation"** — a miscount of *all* rejections (mostly benign `EOF`).
  Counting only cert-less ones: 100% originate from node-3. It was the
  explanation.
- **"the cert repair gives up"** — withdrawn. `ensureRuntimeTLSConvergence` runs
  every heartbeat and does retry; the silence was a correctly-idle loop after
  the harness restored a valid cert. Absence of logging was read as absence of
  execution.
- **"no desired-set refusals occurred in this campaign"** — true only of the
  eight suites finished at the time; `upgrade` and `authority` then produced
  three.
- **"Fix 2 was never exercised"** — wrong, and the most consequential of these.
  The check was scoped to one authority bundle and generalised to the suite.
  Fix 2 is confirmed (§2).
- **"a pruned etcd member has no path back; nothing performs the MemberAdd"** —
  false. `etcd auto-rejoin: MemberAdd succeeded` is in the journal. Same error
  as above: grep one bundle, find zero, generalise.

The last two share one cause worth naming, because it is the same mistake I
made earlier with node-3's silent log: **treating the absence of a signal in a
narrow window as the absence of the behaviour.** Three times this campaign, a
zero count from too small a sample became a false conclusion. What caught it
was writing the verification commands in §6 and then actually running them —
the recipe was broader than the check I had done by hand, and it disagreed.

## 5. What is NOT claimed

- The defect-4 fixes are unit-proven only. They establish the mechanism —
  verified by simulating the pre-fix behaviour and watching the tests fail —
  not that a live cluster recovers. That requires a 1.2.361 build and a soak
  re-run.
- Defect 5 is unfixed by design: it requires an authorization-boundary
  decision, and making the scenario green without one would be an oracle match,
  not a resolution.
- Defect 6 is a harness timing bug with a known fix (a per-scenario restoration
  window). It is not fixed in this campaign, and the two authority rows stay red
  until it is.
- **All three shipped fixes are now confirmed by field evidence**, each with a
  positive control showing the guard firing or the repaired path completing —
  not merely a suite that went green.

## 6. How to re-check this without re-running anything

Every claim above is checkable from committed artifacts:

```bash
# The proof table and its scope.
cat tests/PROOF.md
python3 -c "import json;d=json.load(open('tests/PROOF.json'));print(len(d if isinstance(d,list) else d.get('rows',[])))"

# Fix 1 fired (three holds, one second after three dispatches):
grep -h "dispatch held for another" \
  tests/reports/20260903T171346-soak/*/evidence/journal/*/cluster-controller.log

# Fix 1's bound: 10 dispatch attempts in a 24-minute window (1.2.359: 169 in 5 min).
grep -h "dispatching release workflow across" \
  tests/reports/20260903T171346-soak/etcd-backend-growth-trend/evidence/journal/*/*.log | wc -l

# Fix 3 named the real cause instead of blaming the publisher:
grep -o "cannot verify the kind of dns[^|]*" \
  tests/reports/20260903T201125-upgrade/deploy-publish-then-converge/evidence.json

# Fix 2 was never exercised — all three of these are 0:
grep -rh "etcd auto-rejoin"       tests/reports/20260903T213704-authority/*/evidence/journal/*/cluster-controller.log | wc -l
grep -rh "holding the wipe"       tests/reports/20260903T213704-authority/*/evidence/journal/*/cluster-controller.log | wc -l
grep -rh "wipe-etcd-and-rejoin"   tests/reports/20260903T213704-authority/*/evidence/journal/*/*.log | wc -l

# Defect 4: every cert-less TLS rejection in the cluster came from node-3 (10.10.0.13).
for n in 1 2 3 4 5; do printf "node-$n: "; grep '"error":"tls: client didn.t provide a certificate"' \
  tests/reports/20260903T171346-soak/etcd-backend-growth-trend/evidence/journal/node-$n/etcd.log \
  2>/dev/null | grep -o '"remote-addr":"10\.10\.0\.[0-9]*' | sort -u | tr '\n' ' '; echo; done

# Defect 6: the pruned node can never get a config (identical on both builds).
grep -rhc "is not an etcd member yet" \
  tests/reports/20260903T213704-authority/*/evidence/journal/*/cluster-controller.log   # 1.2.360
grep -rhc "is not an etcd member yet" \
  tests/reports/20260903T130511-authority/*/evidence/journal/*/cluster-controller.log   # 1.2.359
```

## 7. Regression tests added in the tree (services repo)

| test | proves |
|---|---|
| `config/etcd_client_cert_source_test.go` (7 cases) | a restored/rotated certificate reaches the running process; an unchanged mtime is served from cache; a present-but-unusable keypair is an error, not a silent downgrade; an absent keypair still works during Day-0; a wrong-CA leaf is named; end-to-end handshake against a `client-cert-auth: true` server recovers without a restart |
| `node_agent/.../infra_health_probe_etcd_test.go` (5 cases) | reaching no member reports UNKNOWN, not FAILED; a genuine local fault still reports FAILED; a peer's answer is never proof about the local member; UNKNOWN never reads as SUCCEEDED; the local attempt cannot consume the whole probe budget |

Both suites were verified to **fail against the pre-fix behaviour** — the
caching path was reinstated temporarily and three of the seven cert tests
failed, including the end-to-end one — so they are regression tests, not
restatements of what the code already did.

## 8. Next steps, in order

1. Build **1.2.361** with the defect-4 fixes and re-run `security` + `soak` on a
   fresh cluster. The unit tests establish the mechanism; only that run
   establishes that a live cluster recovers.
2. Answer the two contract questions (defects 5 and 6). Both are filed in the
   awareness graph as `contract_unknown` with the candidate repairs and the
   fixes that are explicitly forbidden.
3. Fix T1: `cert-expiry-detection` must assert the repaired certificate is
   *usable* (SANs, chain), not merely un-expired. It currently reports PASS on a
   repair the product itself logged as failed, which is how defect 4 reached the
   soak suite disguised as an etcd problem.
4. Consider promoting the circular-repair shape to a `meta.*` principle with a
   `principle-check` scanner (sensei repo, not this one).
