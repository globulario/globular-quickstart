# reconcile-clean

**Suite**: functional  
**Result**: FAIL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-07-31T20:59:07.589054Z  
**Checks**: 2 passed, 1 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✗ |
| preconditions | controller_registered | service.registered | ✓ |
| cleanup | final_reconcile_state | cluster.reconcile_clean | ✓ |

## Pattern Validation

**Pattern result**: SKIPPED  
See [PATTERNS.md](PATTERNS.md) for full pattern evidence.

## Baseline Captures

```json
{
  "final_reconcile_state": {
    "clean": false,
    "error_count": 46,
    "kinds": "intent resolution failed: unknown profile: ;",
    "sample": "intent resolution failed: unknown profile: ",
    "node": "node-1"
  }
}
```
