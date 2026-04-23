# rbac-policy-integrity

**Suite**: security  
**Result**: PASS  
**Time**: 2026-04-19T05:07:18.824666Z  
**Checks**: 9 passed, 0 failed

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

## Baseline Captures

```json
{
  "baseline_rbac_policy": {
    "present": true,
    "role_count": 6,
    "valid_json": true,
    "node": "node-1"
  }
}
```
