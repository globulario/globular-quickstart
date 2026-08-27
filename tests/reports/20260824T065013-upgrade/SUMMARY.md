# Test Suite: upgrade

**Result**: FAIL
**Date**: 2026-08-24 08:06:45 UTC
**Total**: 12 | **Pass**: 6 | **Fail**: 6 | **Skip**: 0

## Scenarios

- **[PASS]** deploy-publish-then-converge
- **[FAIL]** desired-state-refuses-what-it-cannot-resolve
- **[PASS]** etcd-backend-does-not-ratchet
- **[PASS]** etcd-defrag-actually-reclaims
- **[FAIL]** first-join-from-clean-node
- **[FAIL]** liveness-survives-state-writes
- **[FAIL]** package-upgrade-converges-on-all-nodes
- **[FAIL]** platform-upgrade-release-boundary
- **[PASS]** published-artifact-is-installable-everywhere
- **[PASS]** rejoin-with-stale-membership-state-is-bounded
- **[FAIL]** rollback-guard-refuses-silent-regression
- **[PASS]** service-restart-reports-truthfully

## Evidence

See individual scenario directories for full evidence bundles:
```
deploy-publish-then-converge
desired-state-refuses-what-it-cannot-resolve
etcd-backend-does-not-ratchet
etcd-defrag-actually-reclaims
first-join-from-clean-node
liveness-survives-state-writes
package-upgrade-converges-on-all-nodes
platform-upgrade-release-boundary
published-artifact-is-installable-everywhere
rejoin-with-stale-membership-state-is-bounded
rollback-guard-refuses-silent-regression
service-restart-reports-truthfully
SUMMARY.md
```
