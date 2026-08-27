# full-cluster-blackout

**Suite**: catastrophic  
**Result**: FAIL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-23T05:00:25.159455Z  
**Checks**: 10 passed, 4 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy_before | cluster.health | ✗ |
| preconditions | all_etcd_members_healthy | cluster.etcd_members | ✗ |
| preconditions | etcd_writable_pre_blackout | etcd.write_test | ✓ |
| preconditions | controller_registered_before | service.registered | ✓ |
| preconditions | workflow_registered_before | service.registered | ✓ |
| cleanup | start_node1 | chaos.start_node | ✓ |
| cleanup | start_node2 | chaos.start_node | ✓ |
| cleanup | wait_two_members_online | cluster.etcd_members | ✗ |
| cleanup | start_node3 | chaos.start_node | ✓ |
| cleanup | wait_full_quorum | cluster.etcd_members | ✗ |
| cleanup | verify_health_after_blackout | cluster.health | ✓ |
| cleanup | verify_etcd_writable_after_recovery | etcd.write_test | ✓ |
| cleanup | verify_controller_survived | service.registered | ✓ |
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
