# scylladb-restart

**Suite**: resilience  
**Result**: FAIL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-07-31T20:06:27.453018Z  
**Checks**: 4 passed, 2 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | all_etcd_members_healthy | cluster.etcd_members | ✗ |
| preconditions | scylladb_container_running | node.container_running | ✗ |
| preconditions | write_quorum_before | etcd.write_test | ✓ |
| cleanup | final_health | cluster.health | ✓ |
| cleanup | final_etcd_members | cluster.etcd_members | ✓ |

## Pattern Validation

**Pattern result**: SKIPPED  
See [PATTERNS.md](PATTERNS.md) for full pattern evidence.

## Baseline Captures

```json
{
  "final_etcd_members": {
    "total": 3,
    "healthy": 2,
    "unhealthy": 1
  }
}
```
