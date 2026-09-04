# first-join-from-clean-node

**Suite**: upgrade  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-09-03T20:33:08.996546Z  
**Checks**: 19 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | all_five_present_before | cluster.health | ✓ |
| preconditions | target_node_running_before | node.container_running | ✓ |
| baseline | installed_packages_before | node.installed_packages | ✓ |
| steps | detach_etcd_member | chaos.detach_node_etcd | ✓ |
| steps | stop_the_node_before_deregistering | chaos.stop_node | ✓ |
| steps | remove_node_from_cluster | ops.remove_node | ✓ |
| steps | wipe_all_node_state | chaos.wipe_node_state | ✓ |
| steps | start_the_clean_node | chaos.start_node | ✓ |
| assertions | node_registered_in_etcd | node.etcd_registered | ✓ |
| assertions | cluster_sees_all_five_again | cluster.health | ✓ |
| assertions | node_has_installed_packages | node.installed_packages | ✓ |
| assertions | node_agent_is_serving | service.status | ✓ |
| assertions | etcd_quorum_intact | cluster.etcd_members | ✓ |
| assertions | writes_still_accepted | etcd.write_test | ✓ |
| assertions | liveness_current_for_every_node | state.liveness_freshness | ✓ |
| assertions | no_doctor_errors | doctor.report_severity | ✓ |
| restoration | enforce_restoration | restoration | ✓ |
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
  "installed_packages_before": {
    "count": 35,
    "node": "node-5",
    "uuid": "35ac3821-6b90-52eb-a800-41130471770b"
  }
}
```

## Proof Contract

- Contract declared: no (legacy scenario)
- Proof status: SUPPORTED
- Execution result: PASS
- Production authoritative: **no** — simulation output is candidate evidence until governed promotion.
- Machine artifacts: `scenario-proof.json`, `learning.json`
