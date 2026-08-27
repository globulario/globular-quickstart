# heartbeat-age-stays-under-threshold

**Suite**: soak  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-25T15:10:25.947628Z  
**Checks**: 12 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | all_five_nodes_visible | state.liveness_freshness | ✓ |
| baseline | liveness_at_start | state.liveness_freshness | ✓ |
| steps | margin_sample_1 | state.liveness_freshness | ✓ |
| steps | margin_sample_2 | state.liveness_freshness | ✓ |
| steps | margin_sample_3 | state.liveness_freshness | ✓ |
| steps | margin_sample_4 | state.liveness_freshness | ✓ |
| steps | margin_sample_5 | state.liveness_freshness | ✓ |
| assertions | still_five_nodes | state.liveness_freshness | ✓ |
| assertions | cluster_still_healthy | cluster.health | ✓ |
| assertions | no_error_findings_from_liveness | doctor.report_severity | ✓ |
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
  "liveness_at_start": {
    "nodes": 5,
    "max_age_s": 23,
    "stale_nodes": 0,
    "oldest": "c777633e-6d07-5713-9c4c-deb3317eee25"
  }
}
```

## Proof Contract

- Contract declared: no (legacy scenario)
- Proof status: SUPPORTED
- Execution result: PASS
- Production authoritative: **no** — simulation output is candidate evidence until governed promotion.
- Machine artifacts: `scenario-proof.json`, `learning.json`
