# rbac-policy-integrity

**Suite**: security  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-10T22:11:23.879972Z  
**Checks**: 10 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | rbac_registered | service.registered | ✓ |
| baseline | baseline_rbac_policy | rbac.policy_file | ✓ |
| assertions | rbac_service_present | service.registered | ✓ |
| assertions | rbac_unit_active | service.status | ✓ |
| assertions | policy_file_node1 | rbac.policy_file | ✓ |
| assertions | policy_file_node2 | rbac.policy_file | ✓ |
| assertions | signing_keys_present | pki.signing_keys | ✓ |
| cleanup | final_rbac_check | service.registered | ✓ |
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
  "baseline_rbac_policy": {
    "present": true,
    "role_count": 22,
    "valid_json": true,
    "node": "node-1"
  }
}
```
