# restart-storm-awareness

**Suite**: training  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-24T14:24:40.736465Z  
**Checks**: 13 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster-healthy | cluster.health | ✓ |
| preconditions | node-4-running | node.container_running | ✓ |
| baseline | pre-stop-health | cluster.health | ✓ |
| steps | stop-node-4 | chaos.stop_node | ✓ |
| steps | start-node-4 | chaos.start_node | ✓ |
| steps | wait-node-recovery | node.container_running | ✓ |
| steps | wait-agent-active-after-restart | service.status | ✓ |
| assertions | quorum-maintained | cluster.health | ✓ |
| assertions | node-4-agent-recovered | service.status | ✓ |
| assertions | node-4-registered | node.etcd_registered | ✓ |
| assertions | all-nodes-present | cluster.nodes | ✓ |
| cleanup | ensure-node-4-running | chaos.start_node | ✓ |
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
  "pre-stop-health": {
    "status": "healthy",
    "members": 5,
    "nodes": 5
  }
}
```

## Proof Contract

- Contract declared: no (legacy scenario)
- Proof status: SUPPORTED
- Execution result: PASS
- Production authoritative: **no** — simulation output is candidate evidence until governed promotion.
- Machine artifacts: `scenario-proof.json`, `learning.json`
