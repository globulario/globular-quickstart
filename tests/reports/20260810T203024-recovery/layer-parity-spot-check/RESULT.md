# layer-parity-spot-check

**Suite**: recovery  
**Result**: FAIL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-10T20:31:42.539125Z  
**Checks**: 5 passed, 5 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_reachable | cluster.health | ✓ |
| assertions | node_agent_active_node1 | service.status | ✓ |
| assertions | node_agent_active_node2 | service.status | ✗ |
| assertions | node_agent_active_node3 | service.status | ✗ |
| assertions | node_agent_active_node4 | service.status | ✗ |
| assertions | node_agent_active_node5 | service.status | ✗ |
| assertions | dns_active_after_resilience | service.status | ✗ |
| assertions | dns_registered_post_chaos | service.registered | ✓ |
| assertions | service_count_stable | cluster.health | ✓ |
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
  }
}
```
