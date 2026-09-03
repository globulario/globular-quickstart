# etcd-backend-does-not-ratchet

**Suite**: upgrade  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-09-03T00:22:02.658270Z  
**Checks**: 9 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | etcd_write_quorum | etcd.write_test | ✓ |
| baseline | backend_state_at_start | etcd.backend_growth | ✓ |
| assertions | no_etcd_alarms | etcd.backend_growth | ✓ |
| assertions | compaction_is_configured | etcd.backend_growth | ✓ |
| assertions | defrag_is_scheduled | etcd.backend_growth | ✓ |
| assertions | backend_has_headroom | etcd.backend_growth | ✓ |
| assertions | writes_still_accepted | etcd.write_test | ✓ |
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
  "backend_state_at_start": {
    "max_db_bytes": 37724160,
    "quota_bytes": 2147483648,
    "pct_of_quota": 1,
    "defrag_scheduled": true,
    "compaction_configured": true,
    "alarms": 0
  }
}
```

## Proof Contract

- Contract declared: no (legacy scenario)
- Proof status: SUPPORTED
- Execution result: PASS
- Production authoritative: **no** — simulation output is candidate evidence until governed promotion.
- Machine artifacts: `scenario-proof.json`, `learning.json`
