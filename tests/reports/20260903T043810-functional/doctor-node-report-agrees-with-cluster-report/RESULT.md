# doctor-node-report-agrees-with-cluster-report

**Suite**: functional  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-09-03T04:38:10.342183Z  
**Checks**: 10 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | doctor_is_reachable | doctor.report_severity | ✓ |
| baseline | cluster_report_at_start | doctor.report_severity | ✓ |
| assertions | node1_agrees_with_cluster | doctor.node_vs_cluster_agreement | ✓ |
| assertions | node2_agrees_with_cluster | doctor.node_vs_cluster_agreement | ✓ |
| assertions | node3_agrees_with_cluster | doctor.node_vs_cluster_agreement | ✓ |
| assertions | node4_agrees_with_cluster | doctor.node_vs_cluster_agreement | ✓ |
| assertions | node5_agrees_with_cluster | doctor.node_vs_cluster_agreement | ✓ |
| assertions | doctor_still_producing_verdicts | doctor.report_severity | ✓ |
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
  "cluster_report_at_start": {
    "reachable": true,
    "info": 1,
    "warn": 5,
    "error": 1,
    "total": 7,
    "worst": "CRITICAL",
    "reduced_harvest": false
  }
}
```

## Proof Contract

- Contract declared: no (legacy scenario)
- Proof status: SUPPORTED
- Execution result: PASS
- Production authoritative: **no** — simulation output is candidate evidence until governed promotion.
- Machine artifacts: `scenario-proof.json`, `learning.json`
