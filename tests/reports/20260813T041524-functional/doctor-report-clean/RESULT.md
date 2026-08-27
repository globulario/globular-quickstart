# doctor-report-clean

**Suite**: functional  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-13T04:15:24.927927Z  
**Checks**: 9 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | all_nodes_heartbeating | cluster.nodes | ✓ |
| baseline | doctor_baseline | doctor.report_severity | ✓ |
| steps | wait_for_settled_harvest | doctor.report_severity | ✓ |
| assertions | doctor_reachable | doctor.report_severity | ✓ |
| assertions | harvest_complete | doctor.report_severity | ✓ |
| assertions | no_error_findings | doctor.report_severity | ✓ |
| cleanup | final_doctor_state | doctor.report_severity | ✓ |
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
  "doctor_baseline": {
    "reachable": true,
    "info": 1,
    "warn": 1,
    "error": 0,
    "total": 2,
    "worst": "WARN",
    "reduced_harvest": false
  },
  "final_doctor_state": {
    "reachable": true,
    "info": 1,
    "warn": 1,
    "error": 0,
    "total": 2,
    "worst": "WARN",
    "reduced_harvest": false
  }
}
```
