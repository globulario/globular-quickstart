# Test Suite: resilience

**Result**: FAIL
**Date**: 2026-08-22 19:20:20 UTC
**Total**: 13 | **Pass**: 12 | **Fail**: 1 | **Skip**: 0

## Scenarios

- **[PASS]** compute-node-stop-restart
- **[PASS]** controller-service-crash
  - Awareness: preflight=SKIPPED debug-session=SKIPPED runtime-snapshot=SKIPPED incident=SKIPPED
- **[PASS]** control-plane-single-member-loss
- **[PASS]** control-plane-transient-asymmetric-partition
- **[PASS]** disk-pressure-detection
- **[PASS]** dual-node-failure
- **[PASS]** etcd-quorum-resilience
- **[FAIL]** network-partition-fencing
- **[PASS]** node-agent-crash-recovery
  - Awareness: preflight=SKIPPED debug-session=SKIPPED runtime-snapshot=SKIPPED incident=SKIPPED
- **[PASS]** safe-rolling-control-plane-maintenance
- **[PASS]** scylladb-restart
- **[PASS]** service-crash-recovery
- **[PASS]** worker-node-failure

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
