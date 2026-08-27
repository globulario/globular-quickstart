# Test Suite: recovery

**Result**: FAIL
**Date**: 2026-08-10 20:32:24 UTC
**Total**: 7 | **Pass**: 1 | **Fail**: 6 | **Skip**: 0

## Scenarios

- **[FAIL]** compute-node-rejoin
- **[FAIL]** etcd-detach-before-wipe
  - Awareness: preflight=SKIPPED debug-session=SKIPPED runtime-snapshot=SKIPPED incident=SKIPPED
- **[FAIL]** etcd-member-resync
- **[FAIL]** installed-packages-audit
- **[FAIL]** layer-parity-spot-check
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
