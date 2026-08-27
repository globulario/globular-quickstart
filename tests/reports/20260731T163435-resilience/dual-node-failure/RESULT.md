# dual-node-failure

**Suite**: resilience  
**Result**: FAIL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-07-31T16:39:13.266738Z  
**Checks**: 12 passed, 5 failed

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
| cleanup | wait_fences_cleared | cluster.health | ✗ |

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
  "node_count_before": {
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
