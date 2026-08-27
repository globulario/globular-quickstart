# Test Suite: upgrade

**Result**: FAIL
**Date**: 2026-08-17 20:10:29 UTC
**Total**: 10 | **Pass**: 6 | **Fail**: 4 | **Skip**: 0

## Scenarios

- **[PASS]** desired-state-refuses-what-it-cannot-resolve
- **[PASS]** etcd-backend-does-not-ratchet
- **[PASS]** etcd-defrag-actually-reclaims
- **[FAIL]** first-join-from-clean-node
- **[FAIL]** liveness-survives-state-writes
- **[PASS]** package-upgrade-converges-on-all-nodes
- **[FAIL]** platform-upgrade-release-boundary
- **[PASS]** published-artifact-is-installable-everywhere
- **[FAIL]** rollback-guard-refuses-silent-regression
- **[PASS]** service-restart-reports-truthfully

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
