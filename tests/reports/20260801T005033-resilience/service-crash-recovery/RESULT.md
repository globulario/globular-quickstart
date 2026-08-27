# service-crash-recovery

**Suite**: resilience  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-01T01:24:48.909706Z  
**Checks**: 12 passed, 0 failed

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
| cleanup | ensure_dns_started | chaos.restart_service | ✓ |
| cleanup | final_dns_status | service.status | ✓ |

## Pattern Validation

**Pattern result**: SKIPPED  
See [PATTERNS.md](PATTERNS.md) for full pattern evidence.

## Baseline Captures

```json
{
  "baseline_node_count": {
    "status": "healthy",
    "members": 5,
    "nodes": 6
  },
  "final_dns_status": {
    "unit_state": "activating",
    "node": "node-3",
    "service": "dns"
  }
}
```
