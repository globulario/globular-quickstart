# control-plane-transient-asymmetric-partition

**Suite**: resilience  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-24T05:58:15.993083Z  
**Checks**: 19 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy_before | cluster.health | ✓ |
| preconditions | full_etcd_quorum_before | cluster.etcd_members | ✓ |
| preconditions | writes_work_before | etcd.write_test | ✓ |
| preconditions | node3_running_before | node.container_running | ✓ |
| preconditions | node3_not_fenced_before | node.partition_fenced | ✓ |
| baseline | baseline_etcd_members | cluster.etcd_members | ✓ |
| baseline | baseline_cluster_health | cluster.health | ✓ |
| steps | block_node3_outbound | chaos.block_network | ✓ |
| steps | wait_until_node3_is_unhealthy_peer | cluster.etcd_members | ✓ |
| steps | prove_majority_still_accepts_writes | etcd.write_test | ✓ |
| assertions | majority_quorum_remains_available | cluster.etcd_members | ✓ |
| assertions | writes_still_succeed | etcd.write_test | ✓ |
| assertions | node3_container_never_stopped | node.container_running | ✓ |
| assertions | transient_partition_not_fenced | node.partition_fenced | ✓ |
| cleanup | unblock_node3_network | chaos.unblock_network | ✓ |
| cleanup | wait_for_full_etcd_recovery | cluster.etcd_members | ✓ |
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
  "baseline_etcd_members": {
    "total": 3,
    "healthy": 3,
    "unhealthy": 0
  },
  "baseline_cluster_health": {
    "status": "healthy",
    "members": 5,
    "nodes": 7
  }
}
```

## Proof Contract

- Contract declared: no (legacy scenario)
- Proof status: SUPPORTED
- Execution result: PASS
- Production authoritative: **no** — simulation output is candidate evidence until governed promotion.
- Machine artifacts: `scenario-proof.json`, `learning.json`
