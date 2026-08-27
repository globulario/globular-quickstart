# compute-node-rejoin

**Suite**: recovery  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-11T05:52:05.784921Z  
**Checks**: 20 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | node5_running | node.container_running | ✓ |
| preconditions | node5_registered | node.etcd_registered | ✓ |
| preconditions | all_5_nodes_before | cluster.nodes | ✓ |
| baseline | initial_node_count | cluster.nodes | ✓ |
| baseline | initial_installed_packages | cluster.installed_packages | ✓ |
| steps | stop_node5 | chaos.stop_node | ✓ |
| steps | wait_for_stop | node.container_running | ✓ |
| steps | start_node5 | chaos.start_node | ✓ |
| steps | wait_for_agent_active | service.status | ✓ |
| steps | wait_for_heartbeat_registration | node.etcd_registered | ✓ |
| assertions | node5_container_running | node.container_running | ✓ |
| assertions | node5_agent_active | service.status | ✓ |
| assertions | node5_heartbeat_registered | node.etcd_registered | ✓ |
| assertions | all_5_nodes_after | cluster.nodes | ✓ |
| assertions | cluster_healthy_after | cluster.health | ✓ |
| assertions | write_quorum_after | etcd.write_test | ✓ |
| cleanup | final_node_count | cluster.nodes | ✓ |
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
      "b68457f5-bfb6-5452-bccc-cc36f29d1bbc",
      "c777633e-6d07-5713-9c4c-deb3317eee25"
    ]
  },
  "initial_installed_packages": {
    "total": 202,
    "node_count": 6
  },
  "final_node_count": {
    "count": 5,
    "node_ids": [
      "35ac3821-6b90-52eb-a800-41130471770b",
      "6400b443-cf38-52da-a683-de2fc5103c0b",
      "a166b992-b66d-53cb-b7c7-61dfa4dd5a36",
      "b68457f5-bfb6-5452-bccc-cc36f29d1bbc",
      "c777633e-6d07-5713-9c4c-deb3317eee25"
    ]
  }
}
```
