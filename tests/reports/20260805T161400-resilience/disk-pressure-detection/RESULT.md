# disk-pressure-detection

**Suite**: resilience  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-05T16:17:18.458365Z  
**Checks**: 9 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | node3_running | node.container_running | ✓ |
| baseline | disk_usage_before | node.disk_usage | ✓ |
| steps | fill_disk_node3 | chaos.fill_disk | ✓ |
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
    "used_pct": 91.8,
    "free_pct": 3.1,
    "used_gb": 419.3,
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
