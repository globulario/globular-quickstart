# scylladb-restart

**Suite**: resilience  
**Result**: FAIL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-01T01:24:34.455602Z  
**Checks**: 5 passed, 1 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | all_etcd_members_healthy | cluster.etcd_members | ✓ |
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
    "healthy": 3,
    "unhealthy": 0
  }
}
```
