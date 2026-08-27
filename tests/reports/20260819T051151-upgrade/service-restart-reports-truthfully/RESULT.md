# service-restart-reports-truthfully

**Suite**: upgrade  
**Result**: INFRA_ERROR  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-19T05:37:00.529389Z  
**Checks**: 0 passed, 3 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✗ |
| preconditions | target_service_running_before | service.status | ✗ |
| postconditions | cluster_returned_to_baseline | health.fingerprint | ✗ |

## Pattern Validation

**Pattern result**: SKIPPED  
See [PATTERNS.md](PATTERNS.md) for full pattern evidence.
