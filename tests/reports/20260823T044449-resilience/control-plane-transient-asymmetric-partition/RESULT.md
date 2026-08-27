# control-plane-transient-asymmetric-partition

**Suite**: resilience  
**Result**: FAIL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-23T04:46:07.071518Z  
**Checks**: 8 passed, 2 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy_before | cluster.health | ✓ |
| preconditions | full_etcd_quorum_before | cluster.etcd_members | ✗ |
| preconditions | writes_work_before | etcd.write_test | ✓ |
| preconditions | node3_running_before | node.container_running | ✓ |
| preconditions | node3_not_fenced_before | node.partition_fenced | ✓ |
| cleanup | unblock_node3_network | chaos.unblock_network | ✓ |
| cleanup | wait_for_full_etcd_recovery | cluster.etcd_members | ✗ |
| cleanup | final_write_test | etcd.write_test | ✓ |
| cleanup | final_cluster_health | cluster.health | ✓ |
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
