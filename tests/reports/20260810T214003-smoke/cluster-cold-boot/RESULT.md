# cluster-cold-boot

**Suite**: smoke  
**Result**: PARTIAL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-10T21:40:16.752647Z  
**Checks**: 7 passed, 3 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | containers_running | cluster.nodes | ✓ |
| baseline | initial_node_count | cluster.nodes | ✓ |
| steps | wait_for_etcd_quorum | cluster.health | ✓ |
| steps | wait_for_all_nodes | cluster.nodes | ✗ |
| assertions | etcd_healthy | cluster.health | ✓ |
| assertions | etcd_quorum | cluster.health | ✗ |
| assertions | nodes_heartbeating | cluster.nodes | ✗ |
| assertions | system_config_seeded | cluster.desired_state | ✓ |
| cleanup | final_health_check | cluster.health | ✓ |
| postconditions | cluster_returned_to_baseline | health.fingerprint | ✓ |

## Awareness

| Artifact | Status |
|----------|--------|
| preflight | SKIPPED |
| debug-session | SKIPPED |
| runtime-snapshot | SKIPPED |
| incident | SKIPPED |
| proposal | SKIPPED |

Artifacts: `awareness/`

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
  "containers_running": {
    "count": 0,
    "node_ids": []
  },
  "initial_node_count": {
    "count": 0,
    "node_ids": []
  },
  "system_config_seeded": {
    "count": 18,
    "services": [
      "ai-executor",
      "ai-memory",
      "ai-router",
      "ai-watcher",
      "backup-manager",
      "cluster-controller",
      "cluster-doctor",
      "dns",
      "event",
      "file",
      "log",
      "mcp",
      "monitoring",
      "persistence",
      "rbac",
      "repository",
      "resource",
      "workflow"
    ]
  }
}
```
