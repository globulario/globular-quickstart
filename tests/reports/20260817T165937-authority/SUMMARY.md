# Test Suite: authority

**Result**: FAIL
**Date**: 2026-08-17 17:27:02 UTC
**Total**: 6 | **Pass**: 2 | **Fail**: 4 | **Skip**: 0

## Scenarios

- **[PASS]** controller-zombie-after-lease-loss
- **[PASS]** crash-during-mutation-is-atomic
- **[FAIL]** etcd-enospc-during-state-commit
- **[FAIL]** full-blackout-thundering-herd
- **[FAIL]** node-clone-identity-collision
- **[FAIL]** rejoin-after-missed-generations

## Evidence

See individual scenario directories for full evidence bundles:
```
controller-zombie-after-lease-loss
crash-during-mutation-is-atomic
etcd-enospc-during-state-commit
full-blackout-thundering-herd
node-clone-identity-collision
rejoin-after-missed-generations
SUMMARY.md
```
