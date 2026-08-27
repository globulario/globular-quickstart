# control-plane-majority-loss

**Suite**: catastrophic  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-18T19:30:51.144214Z  
**Checks**: 24 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_fully_healthy | cluster.health | ✓ |
| preconditions | all_three_etcd_healthy | cluster.etcd_members | ✓ |
| preconditions | etcd_writable_before | etcd.write_test | ✓ |
| preconditions | node1_running_before | node.container_running | ✓ |
| preconditions | node2_running_before | node.container_running | ✓ |
| preconditions | node3_running_before | node.container_running | ✓ |
| baseline | baseline_cluster_health | cluster.health | ✓ |
| baseline | baseline_etcd_members | cluster.etcd_members | ✓ |
| baseline | baseline_write_latency | etcd.write_test | ✓ |
| steps | stop_node1 | chaos.stop_node | ✓ |
| steps | stop_node2 | chaos.stop_node | ✓ |
| steps | wait_for_quorum_collapse | node.container_running | ✓ |
| assertions | node1_stopped | node.container_running | ✓ |
| assertions | node2_stopped | node.container_running | ✓ |
| assertions | node3_still_alive | node.container_running | ✓ |
| assertions | cluster_in_unknown_state | cluster.health | ✓ |
| assertions | etcd_writes_blocked | etcd.write_test | ✓ |
| cleanup | start_node1 | chaos.start_node | ✓ |
| cleanup | wait_node1_etcd_online | etcd.write_test | ✓ |
| cleanup | start_node2 | chaos.start_node | ✓ |
| cleanup | wait_full_quorum_restored | cluster.etcd_members | ✓ |
| cleanup | verify_write_after_recovery | etcd.write_test | ✓ |
| cleanup | verify_cluster_healthy_after_recovery | cluster.health | ✓ |
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
    "etcd_healthy_endpoints": 4,
    "etcd_member_count": "5",
    "pki": {
      "node-1": "globular:globular/400 readable backups=0",
      "node-2": "globular:globular/600 readable backups=0",
      "node-3": "globular:globular/600 readable backups=0",
      "node-4": "globular:globular/600 readable backups=0",
      "node-5": "globular:globular/600 readable backups=0"
    }
  },
  "baseline_cluster_health": {
    "status": "healthy",
    "members": 5,
    "nodes": 5
  },
  "baseline_etcd_members": {
    "total": 3,
    "healthy": 3,
    "unhealthy": 0
  },
  "baseline_write_latency": {
    "success": true,
    "latency_ms": 268
  }
}
```
