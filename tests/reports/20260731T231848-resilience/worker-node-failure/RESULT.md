# worker-node-failure

**Suite**: resilience  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-07-31T23:53:57.716829Z  
**Checks**: 12 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | node4_running | service.status | ✓ |
| baseline | baseline_health | cluster.health | ✓ |
| steps | stop_node4 | chaos.stop_node | ✓ |
| steps | wait_node4_container_stopped | node.container_running | ✓ |
| steps | check_cluster_healthy_degraded | cluster.health | ✓ |
| steps | start_node4 | chaos.start_node | ✓ |
| steps | wait_node4_rejoined | service.status | ✓ |
| assertions | all_nodes_back | cluster.health | ✓ |
| assertions | etcd_quorum_intact | cluster.health | ✓ |
| assertions | node4_agent_active | service.status | ✓ |
| cleanup | final_cluster_health | cluster.health | ✓ |

## Pattern Validation

**Pattern result**: SKIPPED  
See [PATTERNS.md](PATTERNS.md) for full pattern evidence.

## Baseline Captures

```json
{
  "baseline_health": {
    "status": "healthy",
    "members": 5,
    "nodes": 5
  }
}
```
