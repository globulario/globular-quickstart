# Test Suite: upgrade

**Result**: FAIL
**Date**: 2026-08-17 07:42:02 UTC
**Total**: 10 | **Pass**: 1 | **Fail**: 9 | **Skip**: 0

## Scenarios

- **[FAIL]** desired-state-refuses-what-it-cannot-resolve
- **[PASS]** etcd-backend-does-not-ratchet
- **[FAIL]** etcd-defrag-actually-reclaims
- **[FAIL]** first-join-from-clean-node
- **[FAIL]** liveness-survives-state-writes
- **[FAIL]** package-upgrade-converges-on-all-nodes
- **[FAIL]** platform-upgrade-release-boundary
- **[FAIL]** published-artifact-is-installable-everywhere
- **[FAIL]** rollback-guard-refuses-silent-regression
- **[FAIL]** service-restart-reports-truthfully

## Evidence

See individual scenario directories for full evidence bundles:
```
desired-state-refuses-what-it-cannot-resolve
etcd-backend-does-not-ratchet
etcd-defrag-actually-reclaims
first-join-from-clean-node
liveness-survives-state-writes
package-upgrade-converges-on-all-nodes
platform-upgrade-release-boundary
published-artifact-is-installable-everywhere
rollback-guard-refuses-silent-regression
service-restart-reports-truthfully
SUMMARY.md
```
