# restart-storm-awareness

**Suite**: training  
**Result**: FAIL  
**Awareness**: AWARENESS_PASS  
**Time**: 2026-05-07T16:43:56.157766Z  
**Checks**: 10 passed, 1 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster-healthy | cluster.health | ✓ |
| preconditions | node-4-running | node.container_running | ✓ |
| baseline | pre-stop-health | cluster.health | ✓ |
| steps | stop-node-4 | chaos.stop_node | ✓ |
| steps | start-node-4 | chaos.start_node | ✓ |
| steps | wait-node-recovery | node.container_running | ✓ |
| assertions | quorum-maintained | cluster.health | ✓ |
| assertions | node-4-agent-recovered | service.status | ✗ |
| assertions | node-4-registered | node.etcd_registered | ✓ |
| assertions | all-nodes-present | cluster.nodes | ✓ |
| cleanup | ensure-node-4-running | chaos.start_node | ✓ |

## Awareness

| Artifact | Status |
|----------|--------|
| preflight | PASS |
| debug-session | PASS |
| runtime-snapshot | PASS |
| incident | CREATED |
| proposal | SKIPPED |
**Recommendation**: Architecture-sensitive task with no prior fix record. After resolving, add a fix case to docs/awareness/fix_cases.yaml.

Artifacts: `awareness/`
- [preflight.agent.txt](awareness/preflight.agent.txt)
- [debug-session.agent.txt](awareness/debug-session.agent.txt)
- [runtime-snapshot.json](awareness/runtime-snapshot.json)
- [incident.yaml](awareness/incident.yaml)

## Baseline Captures

```json
{
  "pre-stop-health": {
    "status": "healthy",
    "members": 3,
    "nodes": 5
  }
}
```
