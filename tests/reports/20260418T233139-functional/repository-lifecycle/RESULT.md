# repository-lifecycle

**Suite**: functional  
**Result**: FAIL  
**Time**: 2026-04-18T23:31:42.376899Z  
**Checks**: 6 passed, 2 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | repository_registered | service.registered | ✓ |
| baseline | baseline_desired_state | cluster.desired_state | ✓ |
| steps | wait_desired_state_populated | cluster.desired_state | ✓ |
| assertions | repository_service_registered | service.registered | ✓ |
| assertions | repository_unit_active | service.status | ✗ |
| assertions | desired_state_populated | cluster.desired_state | ✓ |
| assertions | controller_unit_active | service.status | ✗ |

## Baseline Captures

```json
{
  "baseline_desired_state": {
    "count": 22,
    "services": [
      "ai-executor",
      "ai-memory",
      "ai-router",
      "ai-watcher",
      "alertmanager",
      "assign-profiles",
      "authentication",
      "backup-manager",
      "cluster-controller",
      "cluster-doctor",
      "discovery",
      "dns",
      "dns-resolver",
      "event",
      "log",
      "monitoring",
      "node-agent",
      "rbac",
      "repository",
      "resource",
      "seed-etcd",
      "workflow"
    ]
  }
}
```
