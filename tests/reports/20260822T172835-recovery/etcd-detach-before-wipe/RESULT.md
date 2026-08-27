# etcd-detach-before-wipe

**Suite**: recovery  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-22T17:28:57.004411Z  
**Checks**: 14 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | etcd_writable_at_start | etcd.write_test | ✓ |
| baseline | baseline_etcd_members | cluster.etcd_members | ✓ |
| steps | detach_node3 | chaos.detach_node_etcd | ✓ |
| steps | stop_node3 | chaos.stop_node | ✓ |
| steps | writable_after_first_detach | etcd.write_test | ✓ |
| steps | detach_node2 | chaos.detach_node_etcd | ✓ |
| steps | stop_node2 | chaos.stop_node | ✓ |
| assertions | sole_survivor_still_accepts_writes | etcd.write_test | ✓ |
| assertions | leader_still_elected | cluster.leader | ✓ |
| cleanup | restart_node2 | chaos.start_node | ✓ |
| cleanup | restart_node3 | chaos.start_node | ✓ |
| restoration | enforce_restoration | restoration | ✓ |
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
  "baseline_etcd_members": {
    "total": 3,
    "healthy": 3,
    "unhealthy": 0
  }
}
```

## Proof Contract

- Contract declared: no (legacy scenario)
- Proof status: SUPPORTED
- Execution result: PASS
- Production authoritative: **no** — simulation output is candidate evidence until governed promotion.
- Machine artifacts: `scenario-proof.json`, `learning.json`
