# layer-parity-spot-check

**Suite**: recovery  
**Result**: FAIL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-07-31T20:09:03.638730Z  
**Checks**: 8 passed, 1 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_reachable | cluster.health | ✓ |
| assertions | node_agent_active_node1 | service.status | ✓ |
| assertions | node_agent_active_node2 | service.status | ✓ |
| assertions | node_agent_active_node3 | service.status | ✓ |
| assertions | node_agent_active_node4 | service.status | ✓ |
| assertions | node_agent_active_node5 | service.status | ✓ |
| assertions | dns_active_after_resilience | service.status | ✗ |
| assertions | dns_registered_post_chaos | service.registered | ✓ |
| assertions | service_count_stable | cluster.health | ✓ |

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
