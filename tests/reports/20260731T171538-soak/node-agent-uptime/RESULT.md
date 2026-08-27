# node-agent-uptime

**Suite**: soak  
**Result**: FAIL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-07-31T17:15:50.169589Z  
**Checks**: 23 passed, 1 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | node1_agent_before | service.status | ✓ |
| preconditions | node4_agent_before | service.status | ✓ |
| baseline | baseline_packages | cluster.installed_packages | ✓ |
| steps | t0_node1 | service.status | ✓ |
| steps | t0_node2 | service.status | ✓ |
| steps | t0_node3 | service.status | ✓ |
| steps | t0_node4 | service.status | ✓ |
| steps | t0_node5 | service.status | ✓ |
| steps | t120_node1 | service.status | ✓ |
| steps | t120_node2 | service.status | ✓ |
| steps | t120_node3 | service.status | ✓ |
| steps | t120_node4 | service.status | ✓ |
| steps | t120_node5 | service.status | ✓ |
| steps | t240_node1 | service.status | ✓ |
| steps | t240_node2 | service.status | ✓ |
| steps | t240_node3 | service.status | ✓ |
| steps | t240_node4 | service.status | ✓ |
| steps | t240_node5 | service.status | ✓ |
| assertions | final_node1_active | service.status | ✓ |
| assertions | final_node2_active | service.status | ✓ |
| assertions | final_node3_active | service.status | ✓ |
| assertions | final_node4_active | service.status | ✓ |
| assertions | final_node5_active | service.status | ✓ |
| assertions | layer3_unchanged | cluster.installed_packages | ✗ |

## Pattern Validation

**Pattern result**: SKIPPED  
See [PATTERNS.md](PATTERNS.md) for full pattern evidence.

## Baseline Captures

```json
{
  "baseline_packages": {
    "total": 48,
    "node_count": 5
  }
}
```
