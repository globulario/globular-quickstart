# cluster-cold-boot

**Suite**: smoke  
**Result**: PASS  
**Time**: 2026-04-19T05:12:59.731499Z  
**Checks**: 9 passed, 0 failed

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

## Baseline Captures

```json
{
  "containers_running": {
    "count": 5,
    "node_ids": [
      "12944a1b-cfae-5d2f-8056-e8f633c8d3dd",
      "1a0bed89-043a-57f9-94ce-1ec9cb2bd482",
      "2da500c8-32d8-5ffc-8452-6d8af5c02038",
      "b68457f5-bfb6-5452-bccc-cc36f29d1bbc",
      "c777633e-6d07-5713-9c4c-deb3317eee25"
    ]
  },
  "initial_node_count": {
    "count": 5,
    "node_ids": [
      "12944a1b-cfae-5d2f-8056-e8f633c8d3dd",
      "1a0bed89-043a-57f9-94ce-1ec9cb2bd482",
      "2da500c8-32d8-5ffc-8452-6d8af5c02038",
      "b68457f5-bfb6-5452-bccc-cc36f29d1bbc",
      "c777633e-6d07-5713-9c4c-deb3317eee25"
    ]
  },
  "system_config_seeded": {
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
