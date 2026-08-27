# node-agent-crash-recovery

**Suite**: resilience  
**Result**: FAIL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-07-31T20:06:12.205149Z  
**Checks**: 4 passed, 1 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | node4_container_running | node.container_running | ✓ |
| preconditions | node4_agent_active | service.status | ✓ |
| preconditions | node4_registered_before | node.etcd_registered | ✗ |
| cleanup | final_health | cluster.health | ✓ |

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
