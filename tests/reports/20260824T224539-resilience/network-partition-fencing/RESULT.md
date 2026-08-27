# network-partition-fencing

**Suite**: resilience  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-24T23:12:33.367263Z  
**Checks**: 14 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | node5_running | node.container_running | ✓ |
| baseline | cluster_health_before | cluster.health | ✓ |
| baseline | node5_registered | cluster.nodes | ✓ |
| steps | wait_no_stale_quorum_alert | cluster.quorum_loss_alert | ✓ |
| steps | wait_all_nodes_ready | cluster.health | ✓ |
| steps | block_network_node5 | chaos.block_network | ✓ |
| steps | cluster_healthy_during_partition | cluster.health | ✓ |
| assertions | node5_fenced | node.partition_fenced | ✓ |
| assertions | cluster_still_healthy | cluster.health | ✓ |
| assertions | no_quorum_loss_alert | cluster.quorum_loss_alert | ✓ |
| cleanup | unblock_network_node5 | chaos.unblock_network | ✓ |
| cleanup | wait_fence_cleared | node.partition_fenced | ✓ |
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

## Proof Contract

- Contract declared: no (legacy scenario)
- Proof status: SUPPORTED
- Execution result: PASS
- Production authoritative: **no** — simulation output is candidate evidence until governed promotion.
- Machine artifacts: `scenario-proof.json`, `learning.json`
