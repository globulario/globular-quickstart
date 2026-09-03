# Test Suite: upgrade

**Result**: FAIL
**Date**: 2026-09-02 20:10:54 UTC
**Total**: 12 | **Pass**: 11 | **Fail**: 1 | **Skip**: 0

## Scenarios

- **[PASS]** deploy-publish-then-converge
- **[PASS]** desired-state-refuses-what-it-cannot-resolve
- **[PASS]** etcd-backend-does-not-ratchet
- **[PASS]** etcd-defrag-actually-reclaims
- **[PASS]** first-join-from-clean-node
- **[PASS]** liveness-survives-state-writes
- **[PASS]** package-upgrade-converges-on-all-nodes
- **[FAIL]** platform-upgrade-release-boundary
- **[PASS]** published-artifact-is-installable-everywhere
- **[PASS]** rejoin-with-stale-membership-state-is-bounded
- **[PASS]** rollback-guard-refuses-silent-regression
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
