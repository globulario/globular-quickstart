# compute-node-rejoin

**Suite**: recovery  
**Result**: PASS  
**Time**: 2026-04-19T04:55:57.759396Z  
**Checks**: 19 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | node5_running | node.container_running | ✓ |
| preconditions | node5_registered | node.etcd_registered | ✓ |
| preconditions | all_5_nodes_before | cluster.nodes | ✓ |
| baseline | initial_node_count | cluster.nodes | ✓ |
| baseline | initial_installed_packages | cluster.installed_packages | ✓ |
| steps | stop_node5 | chaos.stop_node | ✓ |
| steps | wait_for_stop | node.container_running | ✓ |
| steps | start_node5 | chaos.start_node | ✓ |
| steps | wait_for_agent_active | service.status | ✓ |
| steps | wait_for_heartbeat_registration | node.etcd_registered | ✓ |
| assertions | node5_container_running | node.container_running | ✓ |
| assertions | node5_agent_active | service.status | ✓ |
| assertions | node5_heartbeat_registered | node.etcd_registered | ✓ |
| assertions | all_5_nodes_after | cluster.nodes | ✓ |
| assertions | cluster_healthy_after | cluster.health | ✓ |
| assertions | write_quorum_after | etcd.write_test | ✓ |
| cleanup | final_node_count | cluster.nodes | ✓ |
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
  "initial_installed_packages": {
    "total": 65,
    "node_count": 5
  },
  "final_node_count": {
    "count": 5,
    "node_ids": [
      "12944a1b-cfae-5d2f-8056-e8f633c8d3dd",
      "1a0bed89-043a-57f9-94ce-1ec9cb2bd482",
      "2da500c8-32d8-5ffc-8452-6d8af5c02038",
      "b68457f5-bfb6-5452-bccc-cc36f29d1bbc",
      "c777633e-6d07-5713-9c4c-deb3317eee25"
    ]
  }
}
```
