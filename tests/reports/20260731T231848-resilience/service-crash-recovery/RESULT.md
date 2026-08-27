# service-crash-recovery

**Suite**: resilience  
**Result**: FAIL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-07-31T23:53:40.104260Z  
**Checks**: 3 passed, 2 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | dns_registered_before | service.registered | ✓ |
| preconditions | dns_active_before | service.status | ✗ |
| cleanup | ensure_dns_started | chaos.restart_service | ✗ |
| cleanup | final_dns_status | service.status | ✓ |

## Pattern Validation

**Pattern result**: SKIPPED  
See [PATTERNS.md](PATTERNS.md) for full pattern evidence.

## Baseline Captures

```json
{
  "final_dns_status": {
    "unit_state": "inactive",
    "node": "node-3",
    "service": "dns"
  }
}
```
