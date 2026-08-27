# workflow-basic

**Suite**: functional  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-26T13:51:39.068656Z  
**Checks**: 10 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | workflow_registered | service.registered | ✓ |
| baseline | baseline_workflow_status | service.status | ✓ |
| steps | wait_workflow_active | service.status | ✓ |
| assertions | workflow_service_registered | service.registered | ✓ |
| assertions | workflow_unit_active_node1 | service.status | ✓ |
| assertions | workflow_unit_active_node2 | service.status | ✓ |
| assertions | workflow_unit_active_node3 | service.status | ✓ |
| cleanup | final_cluster_health | cluster.health | ✓ |
| postconditions | cluster_returned_to_baseline | health.fingerprint | ✓ |

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
  "baseline_workflow_status": {
    "unit_state": "active",
    "node": "node-1",
    "service": "workflow"
  }
}
```

## Proof Contract

- Contract declared: no (legacy scenario)
- Proof status: SUPPORTED
- Execution result: PASS
- Production authoritative: **no** — simulation output is candidate evidence until governed promotion.
- Machine artifacts: `scenario-proof.json`, `learning.json`
