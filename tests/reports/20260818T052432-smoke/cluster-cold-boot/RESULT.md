# cluster-cold-boot

**Suite**: smoke  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-18T05:24:35.318730Z  
**Checks**: 10 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | containers_running | cluster.nodes | ✓ |
| baseline | initial_node_count | cluster.nodes | ✓ |
| steps | wait_for_etcd_quorum | cluster.health | ✓ |
| steps | wait_for_all_nodes | cluster.nodes | ✓ |
| assertions | etcd_healthy | cluster.health | ✓ |
| assertions | etcd_quorum | cluster.health | ✓ |
| assertions | nodes_heartbeating | cluster.nodes | ✓ |
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
  "containers_running": {
    "count": 5,
    "node_ids": [
      "35ac3821-6b90-52eb-a800-41130471770b",
      "6400b443-cf38-52da-a683-de2fc5103c0b",
      "a166b992-b66d-53cb-b7c7-61dfa4dd5a36",
      "c777633e-6d07-5713-9c4c-deb3317eee25",
      "c8a09d9e-3813-5357-ab58-93aa410f27fb"
    ]
  },
  "initial_node_count": {
    "count": 5,
    "node_ids": [
      "35ac3821-6b90-52eb-a800-41130471770b",
      "6400b443-cf38-52da-a683-de2fc5103c0b",
      "a166b992-b66d-53cb-b7c7-61dfa4dd5a36",
      "c777633e-6d07-5713-9c4c-deb3317eee25",
      "c8a09d9e-3813-5357-ab58-93aa410f27fb"
    ]
  },
  "system_config_seeded": {
    "count": 24,
    "services": [
      "ai-executor",
      "ai-memory",
      "ai-router",
      "ai-watcher",
      "authentication",
      "backup-manager",
      "cluster-controller",
      "cluster-doctor",
      "dns",
      "event",
      "file",
      "log",
      "mcp",
      "media",
      "monitoring",
      "node-agent",
      "persistence",
      "rbac",
      "repository",
      "resource",
      "search",
      "title",
      "torrent",
      "workflow"
    ]
  }
}
```
