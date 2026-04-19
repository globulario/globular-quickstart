# service-crash-recovery

**Suite**: resilience  
**Result**: FAIL  
**Time**: 2026-04-18T23:45:27.394305Z  
**Checks**: 8 passed, 2 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | dns_registered_before | service.registered | ✓ |
| preconditions | dns_active_before | service.status | ✓ |
| baseline | baseline_node_count | cluster.health | ✓ |
| steps | kill_dns_service | chaos.kill_service | ✓ |
| steps | wait_dns_restarted | service.status | ✗ |
| steps | wait_dns_reregistered | service.registered | ✓ |
| assertions | dns_unit_active_after | service.status | ✗ |
| assertions | dns_registered_after | service.registered | ✓ |
| assertions | cluster_still_healthy | cluster.health | ✓ |

## Baseline Captures

```json
{
  "baseline_node_count": {
    "status": "healthy",
    "members": 3,
    "nodes": 5
  }
}
```
