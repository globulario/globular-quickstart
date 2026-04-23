# node-agent-uptime

**Suite**: soak  
**Result**: PASS  
**Time**: 2026-04-19T05:17:42.690769Z  
**Checks**: 24 passed, 0 failed

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
| assertions | layer3_unchanged | cluster.installed_packages | ✓ |

## Baseline Captures

```json
{
  "baseline_packages": {
    "total": 65,
    "node_count": 5
  }
}
```
