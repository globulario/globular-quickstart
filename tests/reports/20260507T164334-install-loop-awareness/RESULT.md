# install-loop-awareness

**Suite**: training  
**Result**: PASS  
**Awareness**: AWARENESS_PASS  
**Time**: 2026-05-07T16:43:34.245745Z  
**Checks**: 8 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster-healthy | cluster.health | ✓ |
| preconditions | controller-registered | service.registered | ✓ |
| steps | kill-controller-node1 | chaos.sigkill_service | ✓ |
| steps | wait-for-recovery | service.registered | ✓ |
| assertions | controller-recovered | service.registered | ✓ |
| assertions | node-agent-still-active-node1 | service.status | ✓ |
| assertions | cluster-healthy-after | cluster.health | ✓ |
| assertions | write-quorum-intact | etcd.write_test | ✓ |

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
