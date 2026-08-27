# node-agent-crash-recovery

**Suite**: resilience  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-18T07:37:26.069439Z  
**Checks**: 18 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | node4_container_running | node.container_running | ✓ |
| preconditions | node4_agent_active | service.status | ✓ |
| preconditions | node4_registered_before | node.etcd_registered | ✓ |
| baseline | initial_node_count | cluster.nodes | ✓ |
| steps | sigkill_node_agent_node4 | chaos.sigkill_service | ✓ |
| steps | cluster_healthy_during_crash | cluster.health | ✓ |
| steps | write_quorum_during_crash | etcd.write_test | ✓ |
| steps | wait_for_agent_restart | service.status | ✓ |
| steps | wait_for_heartbeat_resume | node.etcd_registered | ✓ |
| assertions | node4_agent_active_after | service.status | ✓ |
| assertions | node4_registered_after | node.etcd_registered | ✓ |
| assertions | cluster_healthy_after | cluster.health | ✓ |
| assertions | all_nodes_present_after | cluster.nodes | ✓ |
| assertions | write_quorum_after | etcd.write_test | ✓ |
| cleanup | final_health | cluster.health | ✓ |
| restoration | enforce_restoration | restoration | ✓ |
| postconditions | cluster_returned_to_baseline | health.fingerprint | ✓ |

## Awareness

| Artifact | Status |
|----------|--------|
| preflight | SKIPPED |
| debug-session | SKIPPED |
| runtime-snapshot | SKIPPED |
| incident | SKIPPED |
| proposal | SKIPPED |

Artifacts: `awareness/`

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
  }
}
```
