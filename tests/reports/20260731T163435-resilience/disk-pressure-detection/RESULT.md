# disk-pressure-detection

**Suite**: resilience  
**Result**: PARTIAL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-07-31T16:37:22.413415Z  
**Checks**: 8 passed, 1 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | node3_running | node.container_running | ✓ |
| baseline | disk_usage_before | node.disk_usage | ✓ |
| steps | fill_disk_node3 | chaos.fill_disk | ✗ |
| steps | wait_for_detection | node.disk_usage | ✓ |
| assertions | disk_still_pressured | node.disk_usage | ✓ |
| assertions | cluster_still_healthy | cluster.health | ✓ |
| cleanup | clear_fill | node.container_running | ✓ |
| cleanup | remove_fill_file | chaos.clear_disk_fill | ✓ |

## Pattern Validation

**Pattern result**: SKIPPED  
See [PATTERNS.md](PATTERNS.md) for full pattern evidence.

## Baseline Captures

```json
{
  "disk_usage_before": {
    "used_pct": 83.0,
    "free_pct": 11.9,
    "used_gb": 379.1,
    "total_gb": 456.9,
    "path": "/var/lib/globular",
    "node": "node-3"
  },
  "clear_fill": {
    "running": true,
    "node": "node-3"
  }
}
```
