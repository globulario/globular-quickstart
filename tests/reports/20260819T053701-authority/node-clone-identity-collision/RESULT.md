# node-clone-identity-collision

**Suite**: authority  
**Result**: INFRA_ERROR  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-19T05:37:05.455477Z  
**Checks**: 2 passed, 7 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✗ |
| preconditions | source_node_registered | node.etcd_registered | ✗ |
| preconditions | target_node_registered | node.etcd_registered | ✗ |
| preconditions | liveness_settled_before | state.liveness_freshness | ✗ |
| cleanup | stop_the_impostor | chaos.stop_node | ✗ |
| cleanup | restore_the_victims_own_state | chaos.restore_node_state | ✓ |
| cleanup | start_as_itself | chaos.start_node | ✗ |
| cleanup | victim_restored_and_registered | node.etcd_registered | ✓ |
| postconditions | cluster_returned_to_baseline | health.fingerprint | ✗ |

## Pattern Validation

**Pattern result**: SKIPPED  
See [PATTERNS.md](PATTERNS.md) for full pattern evidence.
