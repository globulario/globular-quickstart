# control-plane-single-member-loss

**Suite**: resilience  
**Result**: FAIL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-05T16:16:55.462795Z  
**Checks**: 5 passed, 1 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | all_three_members_healthy | cluster.etcd_members | ✗ |
| preconditions | write_quorum_before | etcd.write_test | ✓ |
| preconditions | node3_running | node.container_running | ✓ |
| cleanup | final_member_health | cluster.etcd_members | ✓ |
| cleanup | final_write_test | etcd.write_test | ✓ |

## Pattern Validation

**Pattern result**: SKIPPED  
See [PATTERNS.md](PATTERNS.md) for full pattern evidence.

## Baseline Captures

```json
{
  "final_member_health": {
    "total": 3,
    "healthy": 2,
    "unhealthy": 1
  }
}
```
