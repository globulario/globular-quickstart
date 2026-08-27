# service-restart-reports-truthfully

**Suite**: upgrade  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-17T04:24:09.112926Z  
**Checks**: 9 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | target_service_running_before | service.status | ✓ |
| baseline | restart_truthful_at_baseline | service.restart_is_truthful | ✓ |
| steps | restart_the_service | chaos.restart_service | ✓ |
| assertions | reported_state_matches_actual_state | service.restart_is_truthful | ✓ |
| assertions | unit_is_active_after_restart | service.status | ✓ |
| assertions | cluster_still_healthy | cluster.health | ✓ |
| assertions | liveness_unaffected | state.liveness_freshness | ✓ |
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
  "restart_truthful_at_baseline": {
    "claimed": "active",
    "actual": "active",
    "truthful": true
  }
}
```
