# reconcile-clean

**Suite**: functional  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-05T16:55:09.751357Z  
**Checks**: 7 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | controller_registered | service.registered | ✓ |
| baseline | cluster_health_context | cluster.health | ✓ |
| baseline | reconcile_baseline | cluster.reconcile_clean | ✓ |
| assertions | reconcile_clean_recent | cluster.reconcile_clean | ✓ |
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
    "members": 4,
    "nodes": 6
  },
  "reconcile_baseline": {
    "clean": false,
    "error_count": 182,
    "kinds": "circuit OPEN;reconcile-workflow: cluster.reconcile FAILED;reconcile-workflow: item FAILED;workflow definition cluster.reconcile not found;",
    "sample": "reconcile-workflow: item FAILED",
    "node": "node-1"
  },
  "final_reconcile_state": {
    "clean": true,
    "error_count": 0,
    "kinds": "",
    "sample": "",
    "node": "node-1"
  }
}
```
