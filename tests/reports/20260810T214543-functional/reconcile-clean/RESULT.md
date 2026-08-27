# reconcile-clean

**Suite**: functional  
**Result**: POSTCONDITION  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-10T21:46:45.194866Z  
**Checks**: 7 passed, 1 failed

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
| postconditions | cluster_returned_to_baseline | health.fingerprint | ✗ |

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
    "etcd_healthy_endpoints": 1,
    "etcd_member_count": "1",
    "pki": {
      "node-1": "globular:globular/400 readable backups=0",
      "node-2": "missing UNREADABLE backups=0",
      "node-3": "missing UNREADABLE backups=0",
      "node-4": "missing UNREADABLE backups=0",
      "node-5": "missing UNREADABLE backups=0"
    }
  },
  "cluster_health_context": {
    "status": "healthy",
    "members": 1,
    "nodes": 1
  },
  "reconcile_baseline": {
    "clean": false,
    "error_count": 3,
    "kinds": "reconcile-workflow: cluster.reconcile FAILED;",
    "sample": "reconcile-workflow: cluster.reconcile FAILED",
    "node": "node-1"
  },
  "final_reconcile_state": {
    "clean": false,
    "error_count": 1,
    "kinds": "reconcile-workflow: cluster.reconcile FAILED;",
    "sample": "reconcile-workflow: cluster.reconcile FAILED",
    "node": "node-1"
  }
}
```
