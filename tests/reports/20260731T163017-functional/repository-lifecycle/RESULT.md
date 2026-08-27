# repository-lifecycle

**Suite**: functional  
**Result**: PARTIAL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-07-31T16:30:26.114839Z  
**Checks**: 7 passed, 2 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | repository_registered | service.registered | ✓ |
| baseline | baseline_desired_state | cluster.desired_state | ✓ |
| steps | wait_desired_state_populated | cluster.desired_state | ✗ |
| assertions | repository_service_registered | service.registered | ✓ |
| assertions | repository_in_service_matrix | cluster.service_matrix | ✓ |
| assertions | desired_state_populated | cluster.desired_state | ✗ |
| assertions | controller_registered | service.registered | ✓ |
| cleanup | final_desired_state | cluster.desired_state | ✓ |

## Pattern Validation

**Pattern result**: SKIPPED  
See [PATTERNS.md](PATTERNS.md) for full pattern evidence.

## Baseline Captures

```json
{
  "baseline_desired_state": {
    "count": 0,
    "services": []
  },
  "final_desired_state": {
    "count": 0,
    "services": []
  }
}
```
