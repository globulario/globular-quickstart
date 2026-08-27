# reconcile-clean

**Suite**: functional  
**Result**: FAIL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-07-31T22:58:53.903333Z  
**Checks**: 6 passed, 1 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | controller_registered | service.registered | ✓ |
| baseline | cluster_health_context | cluster.health | ✓ |
| baseline | reconcile_baseline | cluster.reconcile_clean | ✓ |
| assertions | reconcile_clean_recent | cluster.reconcile_clean | ✗ |
| assertions | desired_state_present | cluster.desired_state | ✓ |
| assertions | leader_elected | cluster.leader | ✓ |
| cleanup | final_reconcile_state | cluster.reconcile_clean | ✓ |

## Pattern Validation

**Pattern result**: SKIPPED  
See [PATTERNS.md](PATTERNS.md) for full pattern evidence.

## Baseline Captures

```json
{
  "cluster_health_context": {
    "status": "healthy",
    "members": 5,
    "nodes": 5
  },
  "reconcile_baseline": {
    "clean": false,
    "error_count": 13,
    "kinds": "circuit OPEN;reconcile-workflow: cluster.reconcile FAILED;reconcile-workflow: item FAILED;",
    "sample": "reconcile-workflow: cluster.reconcile FAILED",
    "node": "node-1"
  },
  "final_reconcile_state": {
    "clean": false,
    "error_count": 35,
    "kinds": "circuit OPEN;reconcile-workflow: cluster.reconcile FAILED;reconcile-workflow: item FAILED;",
    "sample": "circuit OPEN",
    "node": "node-1"
  }
}
```
