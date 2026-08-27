# compute-node-stop-restart

**Suite**: resilience  
**Result**: PARTIAL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-10T18:39:59.456272Z  
**Checks**: 18 passed, 2 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | node4_running | node.container_running | ✓ |
| preconditions | all_nodes_present | cluster.nodes | ✓ |
| preconditions | write_test_before | etcd.write_test | ✓ |
| baseline | initial_node_count | cluster.nodes | ✓ |
| baseline | initial_etcd_members | cluster.etcd_members | ✓ |
| steps | stop_node4 | chaos.stop_node | ✓ |
| steps | wait_for_stabilization | node.container_running | ✓ |
| steps | verify_cluster_healthy_during_outage | cluster.health | ✓ |
| steps | verify_write_quorum_maintained | etcd.write_test | ✓ |
| steps | verify_etcd_members_unchanged | cluster.etcd_members | ✓ |
| steps | start_node4 | chaos.start_node | ✓ |
| steps | wait_for_node4_rejoin | node.etcd_registered | ✗ |
| assertions | cluster_healthy_after | cluster.health | ✓ |
| assertions | all_nodes_heartbeating_after | cluster.nodes | ✓ |
| assertions | node4_registered_after | node.etcd_registered | ✗ |
| assertions | write_test_after | etcd.write_test | ✓ |
| assertions | etcd_members_all_healthy | cluster.etcd_members | ✓ |
| cleanup | final_health | cluster.health | ✓ |
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
  "initial_node_count": {
    "count": 5,
    "node_ids": [
      "35ac3821-6b90-52eb-a800-41130471770b",
      "6400b443-cf38-52da-a683-de2fc5103c0b",
      "a166b992-b66d-53cb-b7c7-61dfa4dd5a36",
      "c777633e-6d07-5713-9c4c-deb3317eee25",
      "c8a09d9e-3813-5357-ab58-93aa410f27fb"
    ]
  },
  "initial_etcd_members": {
    "total": 3,
    "healthy": 3,
    "unhealthy": 0
  }
}
```
