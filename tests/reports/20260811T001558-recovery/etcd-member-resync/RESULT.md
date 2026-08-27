# etcd-member-resync

**Suite**: recovery  
**Result**: FAIL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-11T00:19:30.483072Z  
**Checks**: 7 passed, 1 failed

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
| postconditions | cluster_returned_to_baseline | health.fingerprint | ✓ |

## Pattern Validation

**Pattern result**: SKIPPED  
See [PATTERNS.md](PATTERNS.md) for full pattern evidence.

## Baseline Captures

```json
{
  "_health_fingerprint": {
    "containers_running": [
      "globular-node-1",
      "globular-node-2",
      "globular-node-3",
      "globular-node-4",
      "globular-node-5"
    ],
    "etcd_healthy_endpoints": 3,
    "etcd_member_count": "4",
    "pki": {
      "node-1": "globular:globular/400 readable backups=0",
      "node-2": "globular:globular/600 readable backups=0",
      "node-3": "globular:globular/600 readable backups=0",
      "node-4": "globular:globular/600 readable backups=0",
      "node-5": "globular:globular/600 readable backups=0"
    }
  },
  "final_member_health": {
    "total": 3,
    "healthy": 1,
    "unhealthy": 2
  }
}
```
