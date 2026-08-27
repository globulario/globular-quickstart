# worker-node-failure

**Suite**: resilience  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-18T21:44:34.790609Z  
**Checks**: 13 passed, 0 failed

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
  "baseline_health": {
    "status": "healthy",
    "members": 5,
    "nodes": 5
  }
}
```
