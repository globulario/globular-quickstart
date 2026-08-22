# `upgrade` — package and platform upgrade, and the 2026-08-16 incident

Run with `make test-upgrade`. Included in `make test-v1-certification`.

## Why this suite exists

Before this suite the harness had 68 scenarios and not one of them exercised an
upgrade — the single most frequent mutation the platform performs. On
2026-08-16 an ordinary `ai-memory` package deploy escalated into a full cluster
outage over several hours. Every scenario here is a property that was assumed
rather than checked that night.

## The chain, in order

1. **A deploy reported success that had not succeeded.** `deploy-service.sh`
   decided publish success by grepping the CLI's log text, with the exit code
   discarded by `|| true`. Two of its three success patterns match *failure*
   output — `"bundle_id"` appears in error payloads, and `verify uploaded
   manifest` only ever appears inside `failed to verify uploaded manifest`. A
   publish whose read-back verification failed was recorded as a good deploy.

2. **`--force` was passed on every publish.** In the CLI that means: if an
   artifact with this identity exists with different content, `DeleteArtifact`
   then re-upload. It overrides
   `invariant.repository.artifact.content_immutable_after_publish`, and it is a
   delete-then-write with no rollback. Every routine deploy ran that window.

3. **Re-deploying an unchanged version minted a second build of it.** One
   version, two `build_id`s. The resolver requires exactly one, so it reported
   `repository.identity.version_resolution_ambiguous` and the rollout stalled.
   This is why deploys worked when the version had been bumped and stalled when
   it had not — roughly half the time.

4. **`PUBLISHED` did not mean installable.** The local CAS is per-node while the
   manifest authority is cluster-wide, so a publish materializes bytes only on
   the node that handled the upload. Seeding ran once at startup and never
   again. `cluster-controller@1.2.317`'s blob existed on one node,
   `ai-memory@1.2.317`'s on one other, and every other node raised
   `missing_blob_for_published_manifest` while the archives that would have
   healed them sat unused in `/var/lib/globular/packages/` on those same nodes.

5. **etcd filled its 2 GiB backend quota** and went NOSPACE on 4 of 5 members.
   The control plane went read-only.

6. **The wrong writer was blamed.** The controller rewriting its state blob on
   every heartbeat looked like the cause. An optimization shipped as
   `cluster-controller@1.2.317`: skip the write when nothing "semantic" changed,
   with `last_seen`, `reported_at`, `disk_free_bytes` and `checked_at`
   classified as non-semantic, plus a 5-minute floor.

7. **That took the cluster down.** `last_seen` is not decoration on the state
   record — it is the liveness signal. Persisted values ran 254–276s stale
   against the 300s floor, and readers reported 3 of 5 nodes UNREACHABLE with
   CRITICAL findings while every node agent was healthy and serving. The
   rollback was then blocked by the desired-state regression floor and needed
   `--allow-regression`.

8. **A restart RPC lied.** During recovery, the node-agent's restart returned
   `ok:true state:"active"` for a unit that stayed failed, with no start attempt
   in the journal.

## What the diagnosis got wrong

`auto-compaction` was **already** configured — periodic, 1h retention — so MVCC
history was bounded the entire time. The controller's measured write load was
~78 KB × ~4/min ≈ **30 MB/hour**, which against a 1h retention cannot fill a
2 GiB quota. The numbers were in the commit message that justified the change
and they disprove it.

The real structural cause was that **nothing ever defragments**. Compaction
frees pages logically; the backend file only ratchets upward and the high-water
mark never returns. No systemd timer, no cron entry, anywhere. That fix needs no
code change and would have prevented the outage on its own.

The measurement that settles "is this writer the problem?" — writes per key
prefix over a window — was never taken. The optimization was built on a reading
of the code instead.

## The recurring shape

Every defect above is the same one:

> **A check that cannot fail is indistinguishable from one that passes.**

- A publish gate whose patterns match failure text.
- A restart that reports the outcome it intended.
- A deploy that prints "Deployed" after failing to set desired state.
- `check schemas` that exits non-zero unconditionally, so nobody runs it.
- And the tests that let step 6 ship: **four unit tests, all green, all
  asserting that a write was skipped.** Not one asserted the system still
  worked. A test that pins a suppression proves the suppression happens; it can
  never prove the suppression was safe.

## Scenarios

| Scenario | Pins |
|----------|------|
| `liveness-survives-state-writes` | persisted `last_seen` stays fresh on an **idle** cluster — the exact condition where dedup is most tempting |
| `etcd-backend-does-not-ratchet` | compaction configured, defrag scheduled, headroom against quota, no alarms |
| `published-artifact-is-installable-everywhere` | the blob is on every node; no ambiguous / missing-blob / conflict findings |
| `package-upgrade-converges-on-all-nodes` | one installed version cluster-wide, desired == installed, and running — not merely dispatched |
| `platform-upgrade-release-boundary` | one unambiguous active release; desired build_ids resolve; one odd package version does not fail the platform |
| `service-restart-reports-truthfully` | a control action's claim matches the unit's observed state |

## Note on `liveness-survives-state-writes`

Its 210s idle step is deliberate and is why the scenario is slow. A shorter wait
would pass against the exact build that caused the outage, because the floor
that shipped was 300s. The wait has to sit inside that window for the scenario
to be able to fail.
