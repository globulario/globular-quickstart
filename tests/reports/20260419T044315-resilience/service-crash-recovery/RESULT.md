# service-crash-recovery

**Suite**: resilience  
**Result**: PASS  
**Time**: 2026-04-19T04:45:57.747195Z  
**Checks**: 11 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | dns_registered_before | service.registered | ✓ |
| preconditions | dns_active_before | service.status | ✓ |
| baseline | baseline_node_count | cluster.health | ✓ |
| steps | kill_dns_service | chaos.sigkill_service | ✓ |
| steps | wait_dns_restarted | service.status | ✓ |
| steps | wait_dns_reregistered | service.registered | ✓ |
| assertions | dns_unit_active_after | service.status | ✓ |
| assertions | dns_registered_after | service.registered | ✓ |
| assertions | cluster_still_healthy | cluster.health | ✓ |
| cleanup | final_dns_status | service.status | ✓ |

## Baseline Captures

```json
{
  "baseline_node_count": {
    "status": "healthy",
    "members": 3,
    "nodes": 5
  },
  "final_dns_status": {
    "unit_state": "active",
    "node": "node-3",
    "service": "dns"
  }
}
```
