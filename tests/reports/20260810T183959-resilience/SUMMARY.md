# Test Suite: resilience

**Result**: FAIL
**Date**: 2026-08-10 19:21:58 UTC
**Total**: 11 | **Pass**: 3 | **Fail**: 8 | **Skip**: 0

## Scenarios

- **[FAIL]** compute-node-stop-restart
- **[PASS]** controller-service-crash
  - Awareness: preflight=SKIPPED debug-session=SKIPPED runtime-snapshot=SKIPPED incident=SKIPPED
- **[PASS]** control-plane-single-member-loss
- **[FAIL]** disk-pressure-detection
- **[FAIL]** dual-node-failure
- **[PASS]** etcd-quorum-resilience
- **[FAIL]** network-partition-fencing
- **[FAIL]** node-agent-crash-recovery
  - Awareness: preflight=SKIPPED debug-session=SKIPPED runtime-snapshot=SKIPPED incident=SKIPPED
- **[FAIL]** scylladb-restart
- **[FAIL]** service-crash-recovery
- **[FAIL]** worker-node-failure

## Evidence

See individual scenario directories for full evidence bundles:
```
compute-node-stop-restart
controller-service-crash
control-plane-single-member-loss
disk-pressure-detection
dual-node-failure
etcd-quorum-resilience
network-partition-fencing
node-agent-crash-recovery
scylladb-restart
service-crash-recovery
SUMMARY.md
worker-node-failure
```
