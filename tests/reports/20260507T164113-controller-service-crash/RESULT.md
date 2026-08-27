# controller-service-crash

**Suite**: resilience  
**Result**: PASS  
**Awareness**: AWARENESS_PASS  
**Time**: 2026-05-07T16:41:13.905882Z  
**Checks**: 15 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | controller_registered | service.registered | ✓ |
| preconditions | write_quorum_before | etcd.write_test | ✓ |
| baseline | initial_controller_registration | service.registered | ✓ |
| baseline | initial_leader | cluster.leader | ✓ |
| steps | ensure_controller_running_node2 | chaos.restart_service | ✓ |
| steps | wait_for_node2_controller_registered | service.registered | ✓ |
| steps | sigkill_controller_node2 | chaos.sigkill_service | ✓ |
| steps | verify_etcd_unaffected | etcd.write_test | ✓ |
| steps | wait_for_re_registration | service.registered | ✓ |
| assertions | controller_registered_after | service.registered | ✓ |
| assertions | cluster_healthy_after | cluster.health | ✓ |
| assertions | write_quorum_after | etcd.write_test | ✓ |
| assertions | all_nodes_still_present | cluster.nodes | ✓ |
| cleanup | final_health | cluster.health | ✓ |

## Awareness

| Artifact | Status |
|----------|--------|
| preflight | PASS |
| debug-session | SKIPPED |
| runtime-snapshot | PASS |
| incident | SKIPPED |
| proposal | SKIPPED |

Artifacts: `awareness/`
- [preflight.agent.txt](awareness/preflight.agent.txt)
- [runtime-snapshot.json](awareness/runtime-snapshot.json)

## Baseline Captures

```json
{
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
