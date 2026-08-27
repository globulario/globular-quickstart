# Test Suite: recovery

**Result**: FAIL
**Date**: 2026-07-31 17:15:38 UTC
**Total**: 7 | **Pass**: 1 | **Fail**: 6 | **Skip**: 0

## Scenarios

- **[FAIL]** compute-node-rejoin
- **[PASS]** etcd-detach-before-wipe
  - Awareness: preflight=SKIPPED debug-session=SKIPPED runtime-snapshot=SKIPPED incident=SKIPPED
- **[FAIL]** etcd-member-resync
- **[FAIL]** installed-packages-audit
- **[FAIL]** layer-parity-spot-check
  - Awareness: preflight=SKIPPED debug-session=SKIPPED runtime-snapshot=SKIPPED incident=SKIPPED
- **[FAIL]** release-failure-audit
- **[FAIL]** service-crash-autostart

## Evidence

See individual scenario directories for full evidence bundles:
```
compute-node-rejoin
etcd-detach-before-wipe
etcd-member-resync
installed-packages-audit
layer-parity-spot-check
release-failure-audit
service-crash-autostart
SUMMARY.md
```
