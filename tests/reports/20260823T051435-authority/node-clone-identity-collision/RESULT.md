# node-clone-identity-collision

**Suite**: authority  
**Result**: POSTCONDITION  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-23T05:35:29.885753Z  
**Checks**: 4 passed, 5 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✗ |
| preconditions | source_node_registered | node.etcd_registered | ✗ |
| preconditions | target_node_registered | node.etcd_registered | ✗ |
| preconditions | liveness_settled_before | state.liveness_freshness | ✗ |
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
    "etcd_healthy_endpoints": 1,
    "etcd_member_count": "1",
    "pki": {
      "node-1": "globular:globular/400 readable backups=0",
      "node-2": "missing UNREADABLE backups=0",
      "node-3": "missing UNREADABLE backups=0",
      "node-4": "missing UNREADABLE backups=0",
      "node-5": "missing UNREADABLE backups=0"
    }
  }
}
```

## Proof Contract

- Contract declared: no (legacy scenario)
- Proof status: SUPPORTED
- Execution result: FAIL
- Production authoritative: **no** — simulation output is candidate evidence until governed promotion.
- Machine artifacts: `scenario-proof.json`, `learning.json`
