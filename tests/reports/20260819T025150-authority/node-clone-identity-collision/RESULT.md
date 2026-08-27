# node-clone-identity-collision

**Suite**: authority  
**Result**: FAIL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-19T03:23:47.281580Z  
**Checks**: 8 passed, 1 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | source_node_registered | node.etcd_registered | ✓ |
| preconditions | target_node_registered | node.etcd_registered | ✓ |
| preconditions | liveness_settled_before | state.liveness_freshness | ✗ |
| cleanup | stop_the_impostor | chaos.stop_node | ✓ |
| cleanup | restore_the_victims_own_state | chaos.restore_node_state | ✓ |
| cleanup | start_as_itself | chaos.start_node | ✓ |
| cleanup | victim_restored_and_registered | node.etcd_registered | ✓ |
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
    "etcd_healthy_endpoints": 4,
    "etcd_member_count": "5",
    "pki": {
      "node-1": "globular:globular/400 readable backups=0",
      "node-2": "globular:globular/600 readable backups=0",
      "node-3": "globular:globular/600 readable backups=0",
      "node-4": "globular:globular/600 readable backups=0",
      "node-5": "globular:globular/600 readable backups=0"
    }
  }
}
```
