# controller-service-crash

**Suite**: resilience  
**Result**: FAIL  
**Time**: 2026-04-19T04:43:29.365497Z  
**Checks**: 12 passed, 2 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | controller_registered | service.registered | ✓ |
| preconditions | write_quorum_before | etcd.write_test | ✓ |
| baseline | initial_controller_registration | service.registered | ✓ |
| baseline | initial_leader | cluster.leader | ✓ |
| steps | kill_controller_node2 | chaos.kill_service | ✓ |
| steps | verify_etcd_unaffected | etcd.write_test | ✓ |
| steps | wait_for_controller_restart | service.status | ✗ |
| steps | wait_for_re_registration | service.registered | ✓ |
| assertions | controller_active_node2 | service.status | ✗ |
| assertions | controller_registered_after | service.registered | ✓ |
| assertions | cluster_healthy_after | cluster.health | ✓ |
| assertions | write_quorum_after | etcd.write_test | ✓ |
| assertions | all_nodes_still_present | cluster.nodes | ✓ |

## Baseline Captures

```json
{
  "initial_controller_registration": {
    "registered": true,
    "match_count": 2
  },
  "initial_leader": {
    "leader_endpoint": "10.10.0.12:12000",
    "is_leader": true
  }
}
```
