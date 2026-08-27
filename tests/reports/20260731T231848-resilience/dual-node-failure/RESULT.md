# dual-node-failure

**Suite**: resilience  
**Result**: FAIL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-07-31T23:22:47.716753Z  
**Checks**: 13 passed, 4 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | node4_running | node.container_running | ✓ |
| preconditions | node5_running | node.container_running | ✓ |
| preconditions | no_prior_alert | cluster.quorum_loss_alert | ✓ |
| baseline | cluster_health_before | cluster.health | ✓ |
| baseline | node_count_before | cluster.nodes | ✓ |
| steps | stop_node4 | chaos.stop_node | ✓ |
| steps | stop_node5 | chaos.stop_node | ✓ |
| assertions | quorum_loss_alert_present | cluster.quorum_loss_alert | ✗ |
| assertions | node4_fenced | node.partition_fenced | ✗ |
| assertions | node5_fenced | node.partition_fenced | ✗ |
| assertions | etcd_quorum_intact | cluster.etcd_members | ✗ |
| assertions | etcd_writable | etcd.write_test | ✓ |
| cleanup | start_node4 | chaos.start_node | ✓ |
| cleanup | start_node5 | chaos.start_node | ✓ |
| cleanup | clear_alert_key | cluster.quorum_loss_alert | ✓ |
| cleanup | wait_fences_cleared | cluster.health | ✓ |

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
  "node_count_before": {
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
