# rbac-policy-integrity

**Suite**: security  
**Result**: FAIL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-07-31T21:17:34.375358Z  
**Checks**: 6 passed, 3 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | rbac_registered | service.registered | ✓ |
| baseline | baseline_rbac_policy | rbac.policy_file | ✓ |
| assertions | rbac_service_present | service.registered | ✓ |
| assertions | rbac_unit_active | service.status | ✓ |
| assertions | policy_file_node1 | rbac.policy_file | ✗ |
| assertions | policy_file_node2 | rbac.policy_file | ✗ |
| assertions | signing_keys_present | pki.signing_keys | ✗ |
| cleanup | final_rbac_check | service.registered | ✓ |

## Pattern Validation

**Pattern result**: SKIPPED  
See [PATTERNS.md](PATTERNS.md) for full pattern evidence.

## Baseline Captures

```json
{
  "baseline_rbac_policy": {
    "present": false,
    "role_count": 0,
    "valid_json": false,
    "node": "node-1"
  }
}
```
