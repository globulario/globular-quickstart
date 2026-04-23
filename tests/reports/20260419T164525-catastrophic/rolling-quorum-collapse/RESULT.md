# rolling-quorum-collapse

**Suite**: catastrophic  
**Result**: FAIL  
**Time**: 2026-04-19T16:50:16.196795Z  
**Checks**: 18 passed, 1 failed

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
| assertions | only_one_member_alive | cluster.etcd_members | ✗ |
| assertions | writes_blocked_quorum_lost | etcd.write_test | ✓ |
| assertions | emergency_alert_status | cluster.quorum_loss_alert | ✓ |

## Baseline Captures

```json
{
  "baseline_cluster_health": {
    "status": "healthy",
    "members": 3,
    "nodes": 5
  },
  "baseline_members": {
    "total": 3,
    "healthy": 3,
    "unhealthy": 0
  },
  "baseline_write_test": {
    "success": true,
    "latency_ms": 321
  },
  "emergency_alert_status": {
    "alert_present": false
  }
}
```
