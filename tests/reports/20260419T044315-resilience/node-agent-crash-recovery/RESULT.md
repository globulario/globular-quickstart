# node-agent-crash-recovery

**Suite**: resilience  
**Result**: PASS  
**Time**: 2026-04-19T04:45:31.609102Z  
**Checks**: 16 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | node4_container_running | node.container_running | ✓ |
| preconditions | node4_agent_active | service.status | ✓ |
| preconditions | node4_registered_before | node.etcd_registered | ✓ |
| baseline | initial_node_count | cluster.nodes | ✓ |
| steps | sigkill_node_agent_node4 | chaos.sigkill_service | ✓ |
| steps | cluster_healthy_during_crash | cluster.health | ✓ |
| steps | write_quorum_during_crash | etcd.write_test | ✓ |
| steps | wait_for_agent_restart | service.status | ✓ |
| steps | wait_for_heartbeat_resume | node.etcd_registered | ✓ |
| assertions | node4_agent_active_after | service.status | ✓ |
| assertions | node4_registered_after | node.etcd_registered | ✓ |
| assertions | cluster_healthy_after | cluster.health | ✓ |
| assertions | all_nodes_present_after | cluster.nodes | ✓ |
| assertions | write_quorum_after | etcd.write_test | ✓ |
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
  }
}
```
