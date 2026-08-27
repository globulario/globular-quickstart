# day1-join-second-node-awareness

**Suite**: training  
**Result**: PASS  
**Awareness**: AWARENESS_PASS  
**Time**: 2026-05-07T16:43:32.540433Z  
**Checks**: 8 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | node-1-running | node.container_running | ✓ |
| preconditions | node-2-running | node.container_running | ✓ |
| preconditions | cluster-healthy | cluster.health | ✓ |
| baseline | pre-check-node-count | cluster.nodes | ✓ |
| assertions | etcd-quorum-healthy | cluster.health | ✓ |
| assertions | node-2-agent-active | service.status | ✓ |
| assertions | node-2-registered | node.etcd_registered | ✓ |
| assertions | all-nodes-heartbeating | cluster.nodes | ✓ |

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
  "pre-check-node-count": {
    "count": 5,
    "node_ids": [
      "12944a1b-cfae-5d2f-8056-e8f633c8d3dd",
      "1a0bed89-043a-57f9-94ce-1ec9cb2bd482",
      "2da500c8-32d8-5ffc-8452-6d8af5c02038",
      "b68457f5-bfb6-5452-bccc-cc36f29d1bbc",
      "c777633e-6d07-5713-9c4c-deb3317eee25"
    ]
  }
}
```
