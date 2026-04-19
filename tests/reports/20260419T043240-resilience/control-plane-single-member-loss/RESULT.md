# control-plane-single-member-loss

**Suite**: resilience  
**Result**: FAIL  
**Time**: 2026-04-19T04:32:52.566299Z  
**Checks**: 18 passed, 1 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | all_three_members_healthy | cluster.etcd_members | ✓ |
| preconditions | write_quorum_before | etcd.write_test | ✓ |
| preconditions | node3_running | node.container_running | ✓ |
| baseline | initial_member_health | cluster.etcd_members | ✓ |
| baseline | initial_cluster_health | cluster.health | ✓ |
| steps | stop_node3 | chaos.stop_node | ✗ |
| steps | wait_for_detection | node.container_running | ✓ |
| steps | wait_for_quorum_stability | etcd.write_test | ✓ |
| steps | start_node3 | chaos.start_node | ✓ |
| steps | wait_for_full_quorum | cluster.etcd_members | ✓ |
| assertions | all_members_healthy_after | cluster.etcd_members | ✓ |
| assertions | cluster_healthy_after | cluster.health | ✓ |
| assertions | write_quorum_after | etcd.write_test | ✓ |
| assertions | node3_running_after | node.container_running | ✓ |
| assertions | controller_still_registered | service.registered | ✓ |
| assertions | workflow_still_registered | service.registered | ✓ |
| cleanup | final_member_health | cluster.etcd_members | ✓ |
| cleanup | final_write_test | etcd.write_test | ✓ |

## Baseline Captures

```json
{
  "initial_member_health": {
    "total": 3,
    "healthy": 3,
    "unhealthy": 0
  },
  "initial_cluster_health": {
    "status": "healthy",
    "members": 3,
    "nodes": 5
  },
  "final_member_health": {
    "total": 3,
    "healthy": 3,
    "unhealthy": 0
  }
}
```
