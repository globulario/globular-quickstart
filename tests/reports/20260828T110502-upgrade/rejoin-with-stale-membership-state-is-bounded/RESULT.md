# rejoin-with-stale-membership-state-is-bounded

**Suite**: upgrade  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-28T11:43:06.427334Z  
**Checks**: 16 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | node5_is_a_member | node.etcd_registered | ✓ |
| preconditions | node5_has_packages_installed | node.installed_packages | ✓ |
| baseline | liveness_before | state.liveness_freshness | ✓ |
| baseline | doctor_before | doctor.report_severity | ✓ |
| steps | detach_node5_etcd | chaos.detach_node_etcd | ✓ |
| steps | stop_node5 | chaos.stop_node | ✓ |
| steps | remove_node5_from_cluster | ops.remove_node | ✓ |
| steps | start_node5_dirty | chaos.start_node | ✓ |
| steps | bounded_attempt_window | node.etcd_registered | ✓ |
| assertions | node5_reached_a_terminal_outcome | node.etcd_registered | ✓ |
| assertions | cluster_healthy_after | cluster.health | ✓ |
| assertions | no_identity_collision_from_stale_state | cluster.node_identity_collisions | ✓ |
| assertions | liveness_unaffected | state.liveness_freshness | ✓ |
| assertions | reconcile_clean | cluster.reconcile_clean | ✓ |
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
  "liveness_before": {
    "nodes": 5,
    "max_age_s": 32,
    "stale_nodes": 0,
    "oldest": "c8a09d9e-3813-5357-ab58-93aa410f27fb"
  },
  "doctor_before": {
    "reachable": true,
    "info": 0,
    "warn": 3,
    "error": 0,
    "total": 3,
    "worst": "WARN",
    "reduced_harvest": false
  }
}
```

## Proof Contract

- Contract declared: no (legacy scenario)
- Proof status: SUPPORTED
- Execution result: PASS
- Production authoritative: **no** — simulation output is candidate evidence until governed promotion.
- Machine artifacts: `scenario-proof.json`, `learning.json`
