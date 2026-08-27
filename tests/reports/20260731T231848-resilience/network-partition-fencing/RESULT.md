# network-partition-fencing

**Suite**: resilience  
**Result**: FAIL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-07-31T23:41:35.870872Z  
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
    "members": 5,
    "nodes": 5
  },
  "node5_registered": {
    "count": 5,
    "node_ids": [
      "35ac3821-6b90-52eb-a800-41130471770b",
      "6400b443-cf38-52da-a683-de2fc5103c0b",
      "a166b992-b66d-53cb-b7c7-61dfa4dd5a36",
      "c777633e-6d07-5713-9c4c-deb3317eee25",
      "c8a09d9e-3813-5357-ab58-93aa410f27fb"
    ]
  }
}
```
