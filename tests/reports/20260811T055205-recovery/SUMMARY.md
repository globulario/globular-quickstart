# Test Suite: recovery

**Result**: FAIL
**Date**: 2026-08-11 05:59:03 UTC
**Total**: 7 | **Pass**: 4 | **Fail**: 3 | **Skip**: 0

## Scenarios

- **[PASS]** compute-node-rejoin
- **[FAIL]** etcd-detach-before-wipe
  - Awareness: preflight=SKIPPED debug-session=SKIPPED runtime-snapshot=SKIPPED incident=SKIPPED
- **[FAIL]** etcd-member-resync
- **[PASS]** installed-packages-audit
- **[PASS]** layer-parity-spot-check
  - Awareness: preflight=SKIPPED debug-session=SKIPPED runtime-snapshot=SKIPPED incident=SKIPPED
- **[FAIL]** release-failure-audit
- **[PASS]** service-crash-autostart

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
