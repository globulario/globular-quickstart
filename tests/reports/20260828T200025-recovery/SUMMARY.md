# Test Suite: recovery

**Result**: FAIL
**Date**: 2026-08-28 20:29:51 UTC
**Total**: 7 | **Pass**: 6 | **Fail**: 1 | **Skip**: 0

## Scenarios

- **[PASS]** compute-node-rejoin
- **[PASS]** etcd-detach-before-wipe
  - Awareness: preflight=SKIPPED debug-session=SKIPPED runtime-snapshot=SKIPPED incident=SKIPPED
- **[FAIL]** etcd-member-resync
- **[PASS]** installed-packages-audit
- **[PASS]** layer-parity-spot-check
  - Awareness: preflight=SKIPPED debug-session=SKIPPED runtime-snapshot=SKIPPED incident=SKIPPED
- **[PASS]** release-failure-audit
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
