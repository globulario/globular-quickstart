# day0-single-node-awareness

**Suite**: training  
**Result**: FAIL  
**Awareness**: AWARENESS_PASS  
**Time**: 2026-05-07T16:41:38.608322Z  
**Checks**: 0 passed, 2 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | node-1-running | docker.container_running | ✗ |
| preconditions | scylladb-running | docker.container_running | ✗ |

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
