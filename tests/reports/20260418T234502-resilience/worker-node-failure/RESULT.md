# worker-node-failure

**Suite**: resilience  
**Result**: FAIL  
**Time**: 2026-04-18T23:46:35.552754Z  
**Checks**: 11 passed, 1 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | node4_running | service.status | ✓ |
| baseline | baseline_health | cluster.health | ✓ |
| steps | stop_node4 | chaos.stop_node | ✓ |
| steps | wait_node4_departed | cluster.health | ✗ |
| steps | check_cluster_healthy_degraded | cluster.health | ✓ |
| steps | start_node4 | chaos.start_node | ✓ |
| steps | wait_node4_rejoined | cluster.health | ✓ |
| assertions | all_nodes_back | cluster.health | ✓ |
| assertions | etcd_quorum_intact | cluster.health | ✓ |
| assertions | node4_agent_active | service.status | ✓ |
| cleanup | final_cluster_health | cluster.health | ✓ |

## Baseline Captures

```json
{
  "baseline_health": {
    "status": "healthy",
    "members": 3,
    "nodes": 5
  }
}
```
