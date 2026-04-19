# etcd-member-resync

**Suite**: recovery  
**Result**: PASS  
**Time**: 2026-04-19T04:58:12.124816Z  
**Checks**: 22 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | all_members_healthy_before | cluster.etcd_members | ✓ |
| preconditions | write_quorum_before | etcd.write_test | ✓ |
| preconditions | node2_running | node.container_running | ✓ |
| baseline | initial_member_health | cluster.etcd_members | ✓ |
| baseline | initial_write_test | etcd.write_test | ✓ |
| steps | stop_node2 | chaos.stop_node | ✓ |
| steps | wait_for_2_member_quorum | etcd.write_test | ✓ |
| steps | write_during_absence | etcd.write_test | ✓ |
| steps | verify_2_members_healthy | cluster.etcd_members | ✓ |
| steps | start_node2 | chaos.start_node | ✓ |
| steps | wait_for_node2_container | node.container_running | ✓ |
| steps | wait_for_full_resync | cluster.etcd_members | ✓ |
| steps | write_test_after_resync | etcd.write_test | ✓ |
| assertions | all_members_healthy_after | cluster.etcd_members | ✓ |
| assertions | write_quorum_after_resync | etcd.write_test | ✓ |
| assertions | cluster_healthy_after | cluster.health | ✓ |
| assertions | node2_running_after | node.container_running | ✓ |
| assertions | all_nodes_heartbeating_after | cluster.nodes | ✓ |
| cleanup | final_member_health | cluster.etcd_members | ✓ |
| cleanup | final_write_test | etcd.write_test | ✓ |
| cleanup | final_cluster_health | cluster.health | ✓ |

## Baseline Captures

```json
{
  "initial_member_health": {
    "total": 3,
    "healthy": 3,
    "unhealthy": 0
  },
  "initial_write_test": {
    "success": true,
    "latency_ms": 326
  },
  "final_member_health": {
    "total": 3,
    "healthy": 3,
    "unhealthy": 0
  }
}
```
