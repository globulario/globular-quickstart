# scylladb-node3-cascade

**Suite**: catastrophic  
**Result**: FAIL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-23T05:10:29.608095Z  
**Checks**: 11 passed, 3 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy_before | cluster.health | ✗ |
| preconditions | all_etcd_members_healthy | cluster.etcd_members | ✗ |
| preconditions | etcd_writable_before | etcd.write_test | ✓ |
| preconditions | scylladb_service_running | service.status | ✓ |
| preconditions | node3_running_before | node.container_running | ✓ |
| preconditions | node1_running_before | node.container_running | ✓ |
| preconditions | node2_running_before | node.container_running | ✓ |
| cleanup | start_scylladb | chaos.restart_service | ✓ |
| cleanup | wait_scylladb_ready | service.status | ✓ |
| cleanup | start_node3 | chaos.start_node | ✓ |
| cleanup | wait_full_quorum_restored | cluster.etcd_members | ✗ |
| cleanup | final_cluster_health | cluster.health | ✓ |
| cleanup | final_etcd_write | etcd.write_test | ✓ |
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
