# controller-service-crash

**Suite**: resilience  
**Result**: PARTIAL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-23T04:45:03.443074Z  
**Checks**: 13 passed, 3 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | controller_registered | service.registered | ✓ |
| preconditions | write_quorum_before | etcd.write_test | ✓ |
| baseline | initial_controller_registration | service.registered | ✓ |
| baseline | initial_leader | cluster.leader | ✓ |
| steps | ensure_controller_running_node2 | chaos.restart_service | ✗ |
| steps | wait_for_node2_controller_registered | service.registered | ✓ |
| steps | sigkill_controller_node2 | chaos.sigkill_service | ✗ |
| steps | verify_etcd_unaffected | etcd.write_test | ✓ |
| steps | wait_for_re_registration | service.registered | ✓ |
| assertions | controller_registered_after | service.registered | ✓ |
| assertions | cluster_healthy_after | cluster.health | ✓ |
| assertions | write_quorum_after | etcd.write_test | ✓ |
| assertions | all_nodes_still_present | cluster.nodes | ✗ |
| cleanup | final_health | cluster.health | ✓ |
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
    "etcd_healthy_endpoints": 1,
    "etcd_member_count": "1",
    "pki": {
      "node-1": "globular:globular/400 readable backups=0",
      "node-2": "missing UNREADABLE backups=0",
      "node-3": "missing UNREADABLE backups=0",
      "node-4": "missing UNREADABLE backups=0",
      "node-5": "missing UNREADABLE backups=0"
    }
  },
  "initial_controller_registration": {
    "registered": true,
    "match_count": 2
  },
  "initial_leader": {
    "leader_endpoint": "10.10.0.11:12000",
    "is_leader": true
  }
}
```

## Proof Contract

- Contract declared: no (legacy scenario)
- Proof status: SUPPORTED
- Execution result: PARTIAL
- Production authoritative: **no** — simulation output is candidate evidence until governed promotion.
- Machine artifacts: `scenario-proof.json`, `learning.json`
