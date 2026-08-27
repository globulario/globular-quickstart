# compute-node-rejoin

**Suite**: recovery  
**Result**: FAIL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-07-31T23:54:23.919859Z  
**Checks**: 5 passed, 1 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | node5_running | node.container_running | ✓ |
| preconditions | node5_registered | node.etcd_registered | ✗ |
| preconditions | all_5_nodes_before | cluster.nodes | ✓ |
| cleanup | final_node_count | cluster.nodes | ✓ |
| cleanup | final_health | cluster.health | ✓ |

## Pattern Validation

**Pattern result**: SKIPPED  
See [PATTERNS.md](PATTERNS.md) for full pattern evidence.

## Baseline Captures

```json
{
  "final_node_count": {
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
