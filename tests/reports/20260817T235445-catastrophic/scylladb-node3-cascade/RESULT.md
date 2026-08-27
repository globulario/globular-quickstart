# scylladb-node3-cascade

**Suite**: catastrophic  
**Result**: FAIL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-17T23:59:12.722806Z  
**Checks**: 11 passed, 3 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy_before | cluster.health | ✓ |
| preconditions | all_etcd_members_healthy | cluster.etcd_members | ✓ |
| preconditions | etcd_writable_before | etcd.write_test | ✓ |
| preconditions | scylladb_container_running | node.container_running | ✗ |
| preconditions | node3_running_before | node.container_running | ✓ |
| preconditions | node1_running_before | node.container_running | ✓ |
| preconditions | node2_running_before | node.container_running | ✓ |
| cleanup | start_scylladb | chaos.start_node | ✗ |
| cleanup | wait_scylladb_ready | node.container_running | ✗ |
| cleanup | start_node3 | chaos.start_node | ✓ |
| cleanup | wait_full_quorum_restored | cluster.etcd_members | ✓ |
| cleanup | final_cluster_health | cluster.health | ✓ |
| cleanup | final_etcd_write | etcd.write_test | ✓ |
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
    "etcd_healthy_endpoints": 5,
    "etcd_member_count": "5",
    "pki": {
      "node-1": "globular:globular/400 readable backups=0",
      "node-2": "globular:globular/600 readable backups=0",
      "node-3": "globular:globular/600 readable backups=0",
      "node-4": "globular:globular/600 readable backups=0",
      "node-5": "globular:globular/600 readable backups=0"
    }
  }
}
```
