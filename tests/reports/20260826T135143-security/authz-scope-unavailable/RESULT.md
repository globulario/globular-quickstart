# authz-scope-unavailable

**Suite**: security  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-26T13:51:43.630453Z  
**Checks**: 21 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | rbac_registered_before | service.registered | ✓ |
| preconditions | authz_reachable_before | authz.check | ✓ |
| baseline | role_bindings_before | authz.role_bindings | ✓ |
| baseline | policy_file_before | rbac.policy_file | ✓ |
| steps | kill_rbac | chaos.kill_service | ✓ |
| steps | observe_under_unavailable_rbac | cluster.health | ✓ |
| steps | restart_rbac | chaos.restart_service | ✓ |
| steps | wait_for_rbac_recovery | service.registered | ✓ |
| steps | wait_for_cluster_recovery | cluster.health | ✓ |
| assertions | rbac_registered_after | service.registered | ✓ |
| assertions | authz_reachable_after | authz.check | ✓ |
| assertions | role_bindings_intact | authz.role_bindings | ✓ |
| assertions | policy_file_intact | rbac.policy_file | ✓ |
| assertions | cluster_healthy_after | cluster.health | ✓ |
| assertions | reconcile_clean_after | cluster.reconcile_clean | ✓ |
| assertions | no_error_findings_after | doctor.report_severity | ✓ |
| cleanup | final_cluster_health | cluster.health | ✓ |
| cleanup | final_rbac_registered | service.registered | ✓ |
| restoration | enforce_restoration | restoration | ✓ |
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
  "role_bindings_before": {
    "count": 0
  },
  "policy_file_before": {
    "present": true,
    "role_count": 22,
    "valid_json": true,
    "node": "node-1"
  },
  "role_bindings_intact": {
    "count": 0
  },
  "policy_file_intact": {
    "present": true,
    "role_count": 22,
    "valid_json": true,
    "node": "node-1"
  }
}
```

## Proof Contract

- Contract declared: no (legacy scenario)
- Proof status: SUPPORTED
- Execution result: PASS
- Production authoritative: **no** — simulation output is candidate evidence until governed promotion.
- Machine artifacts: `scenario-proof.json`, `learning.json`
