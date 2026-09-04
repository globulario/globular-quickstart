# etcd-defrag-actually-reclaims

**Suite**: upgrade  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-09-04T13:40:11.137049Z  
**Checks**: 15 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | maintenance_loop_is_running | etcd.defrag_evidence | ✓ |
| preconditions | etcd_accepts_writes | etcd.write_test | ✓ |
| baseline | defrag_evidence_before | etcd.defrag_evidence | ✓ |
| baseline | backend_before | etcd.backend_growth | ✓ |
| steps | inflate_backend_past_floor | chaos.inflate_etcd | ✓ |
| assertions | a_defrag_actually_ran | etcd.defrag_evidence | ✓ |
| assertions | space_was_actually_reclaimed | etcd.defrag_evidence | ✓ |
| assertions | etcd_still_accepts_writes | etcd.write_test | ✓ |
| assertions | all_members_still_healthy | cluster.etcd_members | ✓ |
| assertions | cluster_still_healthy | cluster.health | ✓ |
| assertions | liveness_unaffected_by_maintenance | state.liveness_freshness | ✓ |
| cleanup | deflate_backend | chaos.deflate_etcd | ✓ |
| cleanup | backend_returned_to_normal | etcd.backend_growth | ✓ |
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
  "defrag_evidence_before": {
    "nodes_seen": 5,
    "loops_started": 7,
    "defrags_run": 0,
    "defrags_complete": 0,
    "total_freed_bytes": 0,
    "last": ""
  },
  "backend_before": {
    "max_db_bytes": 15364096,
    "quota_bytes": 2147483648,
    "pct_of_quota": 0,
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
