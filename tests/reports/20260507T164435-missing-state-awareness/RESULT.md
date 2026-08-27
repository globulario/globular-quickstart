# missing-state-awareness

**Suite**: training  
**Result**: PASS  
**Awareness**: AWARENESS_PASS  
**Time**: 2026-05-07T16:44:35.220499Z  
**Checks**: 8 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster-healthy | cluster.health | ✓ |
| preconditions | etcd-write-quorum | etcd.write_test | ✓ |
| baseline | desired-state-snapshot | cluster.desired_state | ✓ |
| baseline | health-snapshot | cluster.health | ✓ |
| assertions | etcd-write-quorum-maintained | etcd.write_test | ✓ |
| assertions | node-agent-runtime-active-node1 | service.status | ✓ |
| assertions | node-agent-runtime-active-node2 | service.status | ✓ |
| assertions | no-stuck-workflows | workflow.last_run | ✓ |

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
  "desired-state-snapshot": {
    "count": 0,
    "services": []
  },
  "health-snapshot": {
    "status": "healthy",
    "members": 3,
    "nodes": 5
  },
  "no-stuck-workflows": {
    "status": "not_found",
    "run_id": "",
    "workflow": ""
  }
}
```
