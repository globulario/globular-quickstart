# Test Suite: resilience

**Result**: FAIL
**Date**: 2026-08-23 04:56:50 UTC
**Total**: 13 | **Pass**: 1 | **Fail**: 12 | **Skip**: 0

## Scenarios

- **[FAIL]** compute-node-stop-restart
- **[FAIL]** controller-service-crash
  - Awareness: preflight=SKIPPED debug-session=SKIPPED runtime-snapshot=SKIPPED incident=SKIPPED
- **[FAIL]** control-plane-single-member-loss
- **[FAIL]** control-plane-transient-asymmetric-partition
- **[PASS]** disk-pressure-detection
- **[FAIL]** dual-node-failure
- **[FAIL]** etcd-quorum-resilience
- **[FAIL]** network-partition-fencing
- **[FAIL]** node-agent-crash-recovery
  - Awareness: preflight=SKIPPED debug-session=SKIPPED runtime-snapshot=SKIPPED incident=SKIPPED
- **[FAIL]** safe-rolling-control-plane-maintenance
- **[FAIL]** scylladb-restart
- **[FAIL]** service-crash-recovery
- **[FAIL]** worker-node-failure

## Evidence

See individual scenario directories for full evidence bundles:
```
compute-node-stop-restart
controller-service-crash
control-plane-single-member-loss
control-plane-transient-asymmetric-partition
disk-pressure-detection
dual-node-failure
etcd-quorum-resilience
network-partition-fencing
node-agent-crash-recovery
safe-rolling-control-plane-maintenance
scylladb-restart
service-crash-recovery
SUMMARY.md
worker-node-failure
```
