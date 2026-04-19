# Test Suite: resilience

**Result**: FAIL
**Date**: 2026-04-19 04:35:34 UTC
**Total**: 8 | **Pass**: 5 | **Fail**: 3 | **Skip**: 0

## Scenarios

- **[PASS]** compute-node-stop-restart
- **[FAIL]** controller-service-crash
- **[FAIL]** control-plane-single-member-loss
- **[PASS]** etcd-quorum-resilience
- **[FAIL]** node-agent-crash-recovery
- **[PASS]** scylladb-restart
- **[PASS]** service-crash-recovery
- **[PASS]** worker-node-failure

## Evidence

See individual scenario directories for full evidence bundles:
```
compute-node-stop-restart
controller-service-crash
control-plane-single-member-loss
etcd-quorum-resilience
node-agent-crash-recovery
scylladb-restart
service-crash-recovery
SUMMARY.md
worker-node-failure
```
