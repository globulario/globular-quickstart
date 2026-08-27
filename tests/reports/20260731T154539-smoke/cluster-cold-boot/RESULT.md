# cluster-cold-boot

**Suite**: smoke  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-07-31T15:45:41.595805Z  
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
    "count": 0,
    "services": []
  }
}
```
