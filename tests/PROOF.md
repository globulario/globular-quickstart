# Scenario proof record

- Generated: `2026-08-25T02:28:43Z`
- Release under test: `1.2.332`
- Scenarios: **75/81 PASS**, 1168 individual checks recorded

Every row names the evidence bundle it was read from — open that
directory to re-check the claim without re-running anything. A scenario
with no bundle is `NO_EVIDENCE`, never a pass: absence of a report is
not a result.

Regenerate with `tests/harness/bin/globular-proof`.

| Suite | Scenario | Result | Checks | Verdict | Evidence |
|---|---|---|---|---|---|
| authority | controller-zombie-after-lease-loss | **PASS** | 19/19 | ✅ | `tests/reports/20260825T010706-authority/controller-zombie-after-lease-loss` |
| authority | crash-during-mutation-is-atomic | **FAIL** | 17/18 | ❌ | `tests/reports/20260825T010706-authority/crash-during-mutation-is-atomic` |
| authority | etcd-enospc-during-state-commit | **PASS** | 18/18 | ✅ | `tests/reports/20260825T010706-authority/etcd-enospc-during-state-commit` |
| authority | full-blackout-thundering-herd | **PASS** | 18/18 | ✅ | `tests/reports/20260825T010706-authority/full-blackout-thundering-herd` |
| authority | node-clone-identity-collision | **POSTCONDITION** | 19/20 | ❌ | `tests/reports/20260825T010706-authority/node-clone-identity-collision` |
| authority | rejoin-after-missed-generations | **PARTIAL** | 16/20 | ❌ | `tests/reports/20260825T010706-authority/rejoin-after-missed-generations` |
| catastrophic | control-plane-majority-loss | **PASS** | 24/24 | ✅ | `tests/reports/20260825T004941-catastrophic/control-plane-majority-loss` |
| catastrophic | controller-leadership-vacuum | **PASS** | 20/20 | ✅ | `tests/reports/20260825T004941-catastrophic/controller-leadership-vacuum` |
| catastrophic | full-cluster-blackout | **PASS** | 30/30 | ✅ | `tests/reports/20260825T004941-catastrophic/full-cluster-blackout` |
| catastrophic | rolling-quorum-collapse | **PASS** | 30/30 | ✅ | `tests/reports/20260825T004941-catastrophic/rolling-quorum-collapse` |
| catastrophic | scylladb-node3-cascade | **PASS** | 30/30 | ✅ | `tests/reports/20260825T004941-catastrophic/scylladb-node3-cascade` |
| functional | doctor-node-report-agrees-with-cluster-report | **PASS** | 10/10 | ✅ | `tests/reports/20260824T211731-functional/doctor-node-report-agrees-with-cluster-report` |
| functional | doctor-report-clean | **PASS** | 9/9 | ✅ | `tests/reports/20260824T211731-functional/doctor-report-clean` |
| functional | etcd-write-verified | **PASS** | 9/9 | ✅ | `tests/reports/20260824T211731-functional/etcd-write-verified` |
| functional | node-join-convergence | **PASS** | 17/17 | ✅ | `tests/reports/20260824T211731-functional/node-join-convergence` |
| functional | parity-runtime | **PASS** | 16/16 | ✅ | `tests/reports/20260824T211731-functional/parity-runtime` |
| functional | pki-mesh-valid | **PASS** | 17/17 | ✅ | `tests/reports/20260824T211731-functional/pki-mesh-valid` |
| functional | reconcile-clean | **PASS** | 8/8 | ✅ | `tests/reports/20260824T211731-functional/reconcile-clean` |
| functional | repository-lifecycle | **PASS** | 10/10 | ✅ | `tests/reports/20260824T211731-functional/repository-lifecycle` |
| functional | service-registration-all | **PASS** | 23/23 | ✅ | `tests/reports/20260824T211731-functional/service-registration-all` |
| functional | workflow-basic | **PASS** | 10/10 | ✅ | `tests/reports/20260824T211731-functional/workflow-basic` |
| patterns | absence-is-not-destructive-intent | **PASS** | 8/8 | ✅ | `tests/reports/20260824T212755-patterns/absence-is-not-destructive-intent` |
| patterns | bootstrap-then-promote-day1 | **PASS** | 8/8 | ✅ | `tests/reports/20260824T212755-patterns/bootstrap-then-promote-day1` |
| patterns | desired-state-reconciliation | **PASS** | 8/8 | ✅ | `tests/reports/20260824T212755-patterns/desired-state-reconciliation` |
| patterns | health-gate-circuit-breaker | **PASS** | 7/7 | ✅ | `tests/reports/20260824T212755-patterns/health-gate-circuit-breaker` |
| patterns | objectstore-authority-generation | **PASS** | 7/7 | ✅ | `tests/reports/20260824T212755-patterns/objectstore-authority-generation` |
| patterns | residue-negative-control | **RESIDUE** | 4/5 | 🟦 expected-fail | `tests/reports/20260824T212755-patterns/residue-negative-control` |
| recovery | compute-node-rejoin | **PASS** | 20/20 | ✅ | `tests/reports/20260824T221021-recovery/compute-node-rejoin` |
| recovery | etcd-detach-before-wipe | **PASS** | 13/13 | ✅ | `tests/reports/20260824T221021-recovery/etcd-detach-before-wipe` |
| recovery | etcd-member-resync | **PASS** | 24/24 | ✅ | `tests/reports/20260824T221021-recovery/etcd-member-resync` |
| recovery | installed-packages-audit | **PASS** | 8/8 | ✅ | `tests/reports/20260824T221021-recovery/installed-packages-audit` |
| recovery | layer-parity-spot-check | **PASS** | 10/10 | ✅ | `tests/reports/20260824T221021-recovery/layer-parity-spot-check` |
| recovery | release-failure-audit | **PASS** | 4/4 | ✅ | `tests/reports/20260824T221021-recovery/release-failure-audit` |
| recovery | service-crash-autostart | **PASS** | 20/20 | ✅ | `tests/reports/20260824T221021-recovery/service-crash-autostart` |
| resilience | compute-node-stop-restart | **PASS** | 20/20 | ✅ | `tests/reports/20260824T224539-resilience/compute-node-stop-restart` |
| resilience | control-plane-single-member-loss | **PASS** | 20/20 | ✅ | `tests/reports/20260824T224539-resilience/control-plane-single-member-loss` |
| resilience | control-plane-transient-asymmetric-partition | **PASS** | 19/19 | ✅ | `tests/reports/20260824T224539-resilience/control-plane-transient-asymmetric-partition` |
| resilience | controller-service-crash | **PASS** | 17/17 | ✅ | `tests/reports/20260824T224539-resilience/controller-service-crash` |
| resilience | disk-pressure-detection | **PASS** | 10/10 | ✅ | `tests/reports/20260824T224539-resilience/disk-pressure-detection` |
| resilience | dual-node-failure | **PASS** | 18/18 | ✅ | `tests/reports/20260824T224539-resilience/dual-node-failure` |
| resilience | etcd-quorum-resilience | **PASS** | 12/12 | ✅ | `tests/reports/20260824T224539-resilience/etcd-quorum-resilience` |
| resilience | network-partition-fencing | **PASS** | 14/14 | ✅ | `tests/reports/20260824T224539-resilience/network-partition-fencing` |
| resilience | node-agent-crash-recovery | **PASS** | 18/18 | ✅ | `tests/reports/20260824T224539-resilience/node-agent-crash-recovery` |
| resilience | safe-rolling-control-plane-maintenance | **PASS** | 28/28 | ✅ | `tests/reports/20260824T224539-resilience/safe-rolling-control-plane-maintenance` |
| resilience | scylladb-restart | **PASS** | 25/25 | ✅ | `tests/reports/20260824T224539-resilience/scylladb-restart` |
| resilience | service-crash-recovery | **PASS** | 14/14 | ✅ | `tests/reports/20260824T224539-resilience/service-crash-recovery` |
| resilience | worker-node-failure | **PASS** | 13/13 | ✅ | `tests/reports/20260824T224539-resilience/worker-node-failure` |
| security | authz-scope-unavailable | **PASS** | 21/21 | ✅ | `tests/reports/20260824T212556-security/authz-scope-unavailable` |
| security | cert-expiry-detection | **PASS** | 12/12 | ✅ | `tests/reports/20260824T212556-security/cert-expiry-detection` |
| security | mtls-connectivity | **PASS** | 10/10 | ✅ | `tests/reports/20260824T212556-security/mtls-connectivity` |
| security | mtls-mesh-connectivity | **PASS** | 14/14 | ✅ | `tests/reports/20260824T212556-security/mtls-mesh-connectivity` |
| security | pki-cert-health | **PASS** | 12/12 | ✅ | `tests/reports/20260824T212556-security/pki-cert-health` |
| security | pki-cert-validity-all-nodes | **PASS** | 14/14 | ✅ | `tests/reports/20260824T212556-security/pki-cert-validity-all-nodes` |
| security | rbac-policy-all-nodes | **PASS** | 13/13 | ✅ | `tests/reports/20260824T212556-security/rbac-policy-all-nodes` |
| security | rbac-policy-integrity | **PASS** | 10/10 | ✅ | `tests/reports/20260824T212556-security/rbac-policy-integrity` |
| security | signing-keys-distribution | **PASS** | 9/9 | ✅ | `tests/reports/20260824T212556-security/signing-keys-distribution` |
| smoke | authz-basic | **PASS** | 10/10 | ✅ | `tests/reports/20260824T211720-smoke/authz-basic` |
| smoke | cluster-cold-boot | **PASS** | 10/10 | ✅ | `tests/reports/20260824T211720-smoke/cluster-cold-boot` |
| smoke | service-health-minimal | **PASS** | 13/13 | ✅ | `tests/reports/20260824T211720-smoke/service-health-minimal` |
| soak | cluster-health-stability | **PASS** | 14/14 | ✅ | `tests/reports/20260824T212839-soak/cluster-health-stability` |
| soak | etcd-backend-growth-trend | **PASS** | 12/12 | ✅ | `tests/reports/20260824T212839-soak/etcd-backend-growth-trend` |
| soak | heartbeat-age-stays-under-threshold | **PASS** | 12/12 | ✅ | `tests/reports/20260824T212839-soak/heartbeat-age-stays-under-threshold` |
| soak | node-agent-uptime | **PASS** | 25/25 | ✅ | `tests/reports/20260824T212839-soak/node-agent-uptime` |
| soak | service-registry-stability | **PASS** | 16/16 | ✅ | `tests/reports/20260824T212839-soak/service-registry-stability` |
| training | day0-single-node-awareness | **PASS** | 8/8 | ✅ | `tests/reports/20260824T220800-training/day0-single-node-awareness` |
| training | day1-join-second-node-awareness | **PASS** | 9/9 | ✅ | `tests/reports/20260824T220800-training/day1-join-second-node-awareness` |
| training | install-loop-awareness | **PASS** | 10/10 | ✅ | `tests/reports/20260824T220800-training/install-loop-awareness` |
| training | missing-state-awareness | **PASS** | 9/9 | ✅ | `tests/reports/20260824T220800-training/missing-state-awareness` |
| training | restart-storm-awareness | **FAIL** | 12/13 | ❌ | `tests/reports/20260824T220800-training/restart-storm-awareness` |
| upgrade | deploy-publish-then-converge | **PASS** | 18/18 | ✅ | `tests/reports/20260824T234128-upgrade/deploy-publish-then-converge` |
| upgrade | desired-state-refuses-what-it-cannot-resolve | **FAIL** | 12/13 | ❌ | `tests/reports/20260824T234128-upgrade/desired-state-refuses-what-it-cannot-resolve` |
| upgrade | etcd-backend-does-not-ratchet | **PASS** | 9/9 | ✅ | `tests/reports/20260824T234128-upgrade/etcd-backend-does-not-ratchet` |
| upgrade | etcd-defrag-actually-reclaims | **PASS** | 15/15 | ✅ | `tests/reports/20260824T234128-upgrade/etcd-defrag-actually-reclaims` |
| upgrade | first-join-from-clean-node | **PASS** | 19/19 | ✅ | `tests/reports/20260824T234128-upgrade/first-join-from-clean-node` |
| upgrade | liveness-survives-state-writes | **PASS** | 8/8 | ✅ | `tests/reports/20260824T234128-upgrade/liveness-survives-state-writes` |
| upgrade | package-upgrade-converges-on-all-nodes | **PASS** | 11/11 | ✅ | `tests/reports/20260824T234128-upgrade/package-upgrade-converges-on-all-nodes` |
| upgrade | platform-upgrade-release-boundary | **PASS** | 9/9 | ✅ | `tests/reports/20260824T234128-upgrade/platform-upgrade-release-boundary` |
| upgrade | published-artifact-is-installable-everywhere | **PASS** | 8/8 | ✅ | `tests/reports/20260824T234128-upgrade/published-artifact-is-installable-everywhere` |
| upgrade | rejoin-with-stale-membership-state-is-bounded | **PASS** | 16/16 | ✅ | `tests/reports/20260824T234128-upgrade/rejoin-with-stale-membership-state-is-bounded` |
| upgrade | rollback-guard-refuses-silent-regression | **PASS** | 11/11 | ✅ | `tests/reports/20260824T234128-upgrade/rollback-guard-refuses-silent-regression` |
| upgrade | service-restart-reports-truthfully | **PASS** | 9/9 | ✅ | `tests/reports/20260824T234128-upgrade/service-restart-reports-truthfully` |

## Totals

- `FAIL`: 3
- `PARTIAL`: 1
- `PASS`: 75
- `POSTCONDITION`: 1
- `RESIDUE`: 1

## Scenarios that are supposed to fail

### residue-negative-control (expects `RESIDUE`)

Negative control for the restoration law. Its own description: 'This is intentionally the only scenario in the tree that is SUPPOSED to fail. Do not fix it by adding cleanup — that would delete the control.' It stops a node and never restores it; the runner must detect the outstanding mutation, reverse it, and fail the scenario. A PASS here would mean the restoration law is NOT enforced.

