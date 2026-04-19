# controller-service-crash

**Suite**: resilience  
**Result**: FAIL  
**Time**: 2026-04-19T04:51:53.478131Z  
**Checks**: 14 passed, 1 failed

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
| steps | sigkill_controller_node2 | chaos.sigkill_service | ✓ |
| steps | verify_etcd_unaffected | etcd.write_test | ✓ |
| steps | wait_for_re_registration | service.registered | ✓ |
| assertions | controller_registered_after | service.registered | ✓ |
| assertions | cluster_healthy_after | cluster.health | ✓ |
| assertions | write_quorum_after | etcd.write_test | ✓ |
| assertions | all_nodes_still_present | cluster.nodes | ✓ |
| cleanup | final_health | cluster.health | ✓ |

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
