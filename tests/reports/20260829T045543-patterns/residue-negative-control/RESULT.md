# residue-negative-control

**Suite**: patterns  
**Result**: RESIDUE  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-29T04:56:00.305189Z  
**Checks**: 4 passed, 1 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | node5_running_before | node.container_running | ✓ |
| steps | stop_node5_and_abandon_it | chaos.stop_node | ✓ |
| assertions | node5_is_stopped | node.container_running | ✓ |
| restoration | enforce_restoration | restoration | ✗ |
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
  }
}
```

## Proof Contract

- Contract declared: no (legacy scenario)
- Proof status: SUPPORTED
- Execution result: FAIL
- Production authoritative: **no** — simulation output is candidate evidence until governed promotion.
- Machine artifacts: `scenario-proof.json`, `learning.json`
