# workflow-basic

**Suite**: functional  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-07-31T21:00:51.131755Z  
**Checks**: 9 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | workflow_registered | service.registered | ✓ |
| baseline | baseline_workflow_status | service.status | ✓ |
| steps | wait_workflow_active | service.status | ✓ |
| assertions | workflow_service_registered | service.registered | ✓ |
| assertions | workflow_unit_active_node1 | service.status | ✓ |
| assertions | workflow_unit_active_node2 | service.status | ✓ |
| assertions | workflow_unit_active_node3 | service.status | ✓ |
| cleanup | final_cluster_health | cluster.health | ✓ |

## Pattern Validation

**Pattern result**: SKIPPED  
See [PATTERNS.md](PATTERNS.md) for full pattern evidence.

## Baseline Captures

```json
{
  "baseline_workflow_status": {
    "unit_state": "active",
    "node": "node-1",
    "service": "workflow"
  }
}
```
