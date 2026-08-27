# disk-pressure-detection

**Suite**: resilience  
**Result**: PARTIAL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-10T23:42:10.356997Z  
**Checks**: 9 passed, 1 failed

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
| postconditions | cluster_returned_to_baseline | health.fingerprint | ✓ |

## Pattern Validation

**Pattern result**: SKIPPED  
See [PATTERNS.md](PATTERNS.md) for full pattern evidence.

## Baseline Captures

```json
{
  "_health_fingerprint": {
    "containers_running": [
      "globular-node-1",
      "globular-node-2",
      "globular-node-3",
      "globular-node-4",
      "globular-node-5"
    ],
    "etcd_healthy_endpoints": 5,
    "etcd_member_count": "5",
    "pki": {
      "node-1": "globular:globular/400 readable backups=0",
      "node-2": "globular:globular/600 readable backups=0",
      "node-3": "globular:globular/600 readable backups=0",
      "node-4": "globular:globular/600 readable backups=0",
      "node-5": "globular:globular/600 readable backups=0"
    }
  },
  "disk_usage_before": {
    "used_pct": 86.2,
    "free_pct": 12.8,
    "used_gb": 290.8,
    "total_gb": 337.5,
    "path": "/var/lib/globular",
    "node": "node-3"
  },
  "clear_fill": {
    "running": true,
    "node": "node-3"
  }
}
```
