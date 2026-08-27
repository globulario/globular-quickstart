# etcd-detach-before-wipe

**Suite**: recovery  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-07-31T23:54:41.645540Z  
**Checks**: 12 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | etcd_writable_at_start | etcd.write_test | ✓ |
| baseline | baseline_etcd_members | cluster.etcd_members | ✓ |
| steps | detach_node3 | chaos.detach_node_etcd | ✓ |
| steps | stop_node3 | chaos.stop_node | ✓ |
| steps | writable_after_first_detach | etcd.write_test | ✓ |
| steps | detach_node2 | chaos.detach_node_etcd | ✓ |
| steps | stop_node2 | chaos.stop_node | ✓ |
| assertions | sole_survivor_still_accepts_writes | etcd.write_test | ✓ |
| assertions | leader_still_elected | cluster.leader | ✓ |
| cleanup | restart_node2 | chaos.start_node | ✓ |
| cleanup | restart_node3 | chaos.start_node | ✓ |

## Awareness

| Artifact | Status |
|----------|--------|
| preflight | SKIPPED |
| debug-session | SKIPPED |
| runtime-snapshot | SKIPPED |
| incident | SKIPPED |
| proposal | SKIPPED |

Artifacts: `awareness/`

## Pattern Validation

**Pattern result**: SKIPPED  
See [PATTERNS.md](PATTERNS.md) for full pattern evidence.

## Baseline Captures

```json
{
  "baseline_etcd_members": {
    "total": 3,
    "healthy": 2,
    "unhealthy": 1
  }
}
```
