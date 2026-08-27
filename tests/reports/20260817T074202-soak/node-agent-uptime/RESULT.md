# node-agent-uptime

**Suite**: soak  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-17T07:50:20.557529Z  
**Checks**: 25 passed, 0 failed

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
  "baseline_packages": {
    "total": 214,
    "node_count": 6
  }
}
```
