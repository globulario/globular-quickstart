# node-clone-identity-collision

**Suite**: authority  
**Result**: POSTCONDITION  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-09-02T22:38:07.475959Z  
**Checks**: 19 passed, 1 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | source_node_registered | node.etcd_registered | ✓ |
| preconditions | target_node_registered | node.etcd_registered | ✓ |
| preconditions | liveness_settled_before | state.liveness_freshness | ✓ |
| baseline | nodes_before | cluster.nodes | ✓ |
| steps | snapshot_the_victim | chaos.snapshot_node_state | ✓ |
| steps | stop_the_victim | chaos.stop_node | ✓ |
| steps | clone_the_identity | chaos.clone_node_state | ✓ |
| steps | start_the_impostor | chaos.start_node | ✓ |
| assertions | no_duplicate_identity_admitted | cluster.node_identity_collisions | ✓ |
| assertions | source_node_still_registered | node.etcd_registered | ✓ |
| assertions | source_node_agent_serving | service.status | ✓ |
| assertions | cluster_still_healthy | cluster.health | ✓ |
| assertions | etcd_members_healthy | cluster.etcd_members | ✓ |
| assertions | no_identity_findings | repository.identity_findings | ✓ |
| cleanup | stop_the_impostor | chaos.stop_node | ✓ |
| cleanup | restore_the_victims_own_state | chaos.restore_node_state | ✓ |
| cleanup | start_as_itself | chaos.start_node | ✓ |
| cleanup | victim_restored_and_registered | node.etcd_registered | ✓ |
| postconditions | cluster_returned_to_baseline | health.fingerprint | ✗ |

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
  "nodes_before": {
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
- Execution result: FAIL
- Production authoritative: **no** — simulation output is candidate evidence until governed promotion.
- Machine artifacts: `scenario-proof.json`, `learning.json`
