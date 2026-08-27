# network-partition-fencing

**Suite**: resilience  
**Result**: FAIL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-07-31T16:59:50.621887Z  
**Checks**: 10 passed, 1 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | node5_running | node.container_running | ✓ |
| baseline | cluster_health_before | cluster.health | ✓ |
| baseline | node5_registered | cluster.nodes | ✓ |
| steps | block_network_node5 | chaos.block_network | ✓ |
| steps | wait_warn_threshold | cluster.health | ✓ |
| assertions | node5_fenced | node.partition_fenced | ✗ |
| assertions | cluster_still_healthy | cluster.health | ✓ |
| assertions | no_quorum_loss_alert | cluster.quorum_loss_alert | ✓ |
| cleanup | unblock_network_node5 | chaos.unblock_network | ✓ |
| cleanup | wait_fence_cleared | node.partition_fenced | ✓ |

## Pattern Validation

**Pattern result**: SKIPPED  
See [PATTERNS.md](PATTERNS.md) for full pattern evidence.

## Baseline Captures

```json
{
  "cluster_health_before": {
    "status": "healthy",
    "members": 3,
    "nodes": 5
  },
  "node5_registered": {
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
