# day0-single-node-awareness

**Suite**: training  
**Result**: PASS  
**Awareness**: AWARENESS_PASS  
**Time**: 2026-05-07T16:43:23.811127Z  
**Checks**: 7 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | node-1-running | node.container_running | ✓ |
| preconditions | cluster-healthy | cluster.health | ✓ |
| baseline | initial-health | cluster.health | ✓ |
| assertions | etcd-healthy | cluster.health | ✓ |
| assertions | nodes-heartbeating | cluster.nodes | ✓ |
| assertions | node-agent-active | service.status | ✓ |
| assertions | controller-active | service.status | ✓ |

## Awareness

| Artifact | Status |
|----------|--------|
| preflight | PASS |
| debug-session | SKIPPED |
| runtime-snapshot | PASS |
| incident | SKIPPED |
| proposal | SKIPPED |

Artifacts: `awareness/`
- [preflight.agent.txt](awareness/preflight.agent.txt)
- [runtime-snapshot.json](awareness/runtime-snapshot.json)

## Baseline Captures

```json
{
  "initial-health": {
    "status": "healthy",
    "members": 3,
    "nodes": 5
  }
}
```
