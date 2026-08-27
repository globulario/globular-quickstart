# etcd-member-resync

**Suite**: recovery  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-23T16:45:01.539780Z  
**Checks**: 24 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | all_members_healthy_before | cluster.etcd_members | ✓ |
| preconditions | write_quorum_before | etcd.write_test | ✓ |
| preconditions | node2_running | node.container_running | ✓ |
| baseline | initial_member_health | cluster.etcd_members | ✓ |
| baseline | initial_write_test | etcd.write_test | ✓ |
| steps | stop_node2 | chaos.stop_node | ✓ |
| steps | wait_for_2_member_quorum | etcd.write_test | ✓ |
| steps | write_during_absence | etcd.write_test | ✓ |
| steps | verify_2_members_healthy | cluster.etcd_members | ✓ |
| steps | start_node2 | chaos.start_node | ✓ |
| steps | wait_for_node2_container | node.container_running | ✓ |
| steps | wait_for_full_resync | cluster.etcd_members | ✓ |
| steps | wait_for_node2_agent | service.status | ✓ |
| steps | write_test_after_resync | etcd.write_test | ✓ |
| assertions | all_members_healthy_after | cluster.etcd_members | ✓ |
| assertions | write_quorum_after_resync | etcd.write_test | ✓ |
| assertions | cluster_healthy_after | cluster.health | ✓ |
| assertions | node2_running_after | node.container_running | ✓ |
| assertions | all_nodes_heartbeating_after | cluster.nodes | ✓ |
| cleanup | final_member_health | cluster.etcd_members | ✓ |
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
  "initial_member_health": {
    "total": 3,
    "healthy": 3,
    "unhealthy": 0
  },
  "initial_write_test": {
    "success": true,
    "latency_ms": 273
  },
  "final_member_health": {
    "total": 3,
    "healthy": 3,
    "unhealthy": 0
  }
}
```

## Proof Contract

- Contract declared: no (legacy scenario)
- Proof status: SUPPORTED
- Execution result: PASS
- Production authoritative: **no** — simulation output is candidate evidence until governed promotion.
- Machine artifacts: `scenario-proof.json`, `learning.json`
