# etcd-member-resync

**Suite**: recovery  
**Result**: FAIL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-07-31T17:13:00.125369Z  
**Checks**: 6 passed, 1 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | all_members_healthy_before | cluster.etcd_members | ✗ |
| preconditions | write_quorum_before | etcd.write_test | ✓ |
| preconditions | node2_running | node.container_running | ✓ |
| cleanup | final_member_health | cluster.etcd_members | ✓ |
| cleanup | final_write_test | etcd.write_test | ✓ |
| cleanup | final_cluster_health | cluster.health | ✓ |

## Pattern Validation

**Pattern result**: SKIPPED  
See [PATTERNS.md](PATTERNS.md) for full pattern evidence.

## Baseline Captures

```json
{
  "final_member_health": {
    "total": 3,
    "healthy": 1,
    "unhealthy": 2
  }
}
```
