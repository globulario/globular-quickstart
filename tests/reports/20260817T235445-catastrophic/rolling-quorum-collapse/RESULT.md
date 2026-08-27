# rolling-quorum-collapse

**Suite**: catastrophic  
**Result**: FAIL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-17T23:57:42.530021Z  
**Checks**: 26 passed, 1 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | full_quorum_before | cluster.etcd_members | ✓ |
| preconditions | cluster_healthy_before | cluster.health | ✓ |
| preconditions | writes_ok_before | etcd.write_test | ✓ |
| preconditions | node2_running | node.container_running | ✓ |
| preconditions | node3_running | node.container_running | ✓ |
| baseline | baseline_cluster_health | cluster.health | ✓ |
| baseline | baseline_members | cluster.etcd_members | ✓ |
| baseline | baseline_write_test | etcd.write_test | ✓ |
| steps | stop_node2_phase1 | chaos.stop_node | ✓ |
| steps | wait_node2_stopped | node.container_running | ✓ |
| steps | verify_phase1_writes_ok | etcd.write_test | ✓ |
| steps | stop_node3_phase2 | chaos.stop_node | ✓ |
| steps | wait_node3_stopped | node.container_running | ✓ |
| assertions | node2_confirmed_down | node.container_running | ✓ |
| assertions | node3_confirmed_down | node.container_running | ✓ |
| assertions | node1_still_up | node.container_running | ✓ |
| assertions | etcd_member_status_at_quorum_loss | cluster.etcd_members | ✓ |
| assertions | writes_blocked_quorum_lost | etcd.write_test | ✗ |
| assertions | emergency_alert_status | cluster.quorum_loss_alert | ✓ |
| cleanup | start_node2 | chaos.start_node | ✓ |
| cleanup | wait_phase1_quorum_restored | etcd.write_test | ✓ |
| cleanup | start_node3 | chaos.start_node | ✓ |
| cleanup | wait_full_quorum_restored | cluster.etcd_members | ✓ |
| cleanup | final_cluster_health | cluster.health | ✓ |
| cleanup | final_write_test | etcd.write_test | ✓ |
| cleanup | clear_quorum_loss_alert_if_present | cluster.quorum_loss_alert | ✓ |
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
  },
  "baseline_cluster_health": {
    "status": "healthy",
    "members": 5,
    "nodes": 6
  },
  "baseline_members": {
    "total": 3,
    "healthy": 3,
    "unhealthy": 0
  },
  "baseline_write_test": {
    "success": true,
    "latency_ms": 276
  },
  "etcd_member_status_at_quorum_loss": {
    "total": 3,
    "healthy": 1,
    "unhealthy": 2
  },
  "emergency_alert_status": {
    "alert_present": false
  }
}
```
