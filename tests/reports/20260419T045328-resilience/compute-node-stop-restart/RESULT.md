# compute-node-stop-restart

**Suite**: resilience  
**Result**: PASS  
**Time**: 2026-04-19T04:53:28.595375Z  
**Checks**: 19 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | node4_running | node.container_running | ✓ |
| preconditions | all_nodes_present | cluster.nodes | ✓ |
| preconditions | write_test_before | etcd.write_test | ✓ |
| baseline | initial_node_count | cluster.nodes | ✓ |
| baseline | initial_etcd_members | cluster.etcd_members | ✓ |
| steps | stop_node4 | chaos.stop_node | ✓ |
| steps | wait_for_stabilization | node.container_running | ✓ |
| steps | verify_cluster_healthy_during_outage | cluster.health | ✓ |
| steps | verify_write_quorum_maintained | etcd.write_test | ✓ |
| steps | verify_etcd_members_unchanged | cluster.etcd_members | ✓ |
| steps | start_node4 | chaos.start_node | ✓ |
| steps | wait_for_node4_rejoin | node.etcd_registered | ✓ |
| assertions | cluster_healthy_after | cluster.health | ✓ |
| assertions | all_nodes_heartbeating_after | cluster.nodes | ✓ |
| assertions | node4_registered_after | node.etcd_registered | ✓ |
| assertions | write_test_after | etcd.write_test | ✓ |
| assertions | etcd_members_all_healthy | cluster.etcd_members | ✓ |
| cleanup | final_health | cluster.health | ✓ |

## Baseline Captures

```json
{
  "initial_node_count": {
    "count": 5,
    "node_ids": [
      "12944a1b-cfae-5d2f-8056-e8f633c8d3dd",
      "1a0bed89-043a-57f9-94ce-1ec9cb2bd482",
      "2da500c8-32d8-5ffc-8452-6d8af5c02038",
      "b68457f5-bfb6-5452-bccc-cc36f29d1bbc",
      "c777633e-6d07-5713-9c4c-deb3317eee25"
    ]
  },
  "initial_etcd_members": {
    "total": 3,
    "healthy": 3,
    "unhealthy": 0
  }
}
```
