# rbac-policy-all-nodes

**Suite**: security  
**Result**: FAIL  
**Time**: 2026-04-19T04:31:27.220362Z  
**Checks**: 8 passed, 2 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | rbac_service_registered | service.registered | ✓ |
| baseline | initial_role_bindings | authz.role_bindings | ✓ |
| assertions | policy_file_node1 | rbac.policy_file | ✓ |
| assertions | policy_file_node2 | rbac.policy_file | ✓ |
| assertions | policy_file_node3 | rbac.policy_file | ✓ |
| assertions | rbac_registered | service.registered | ✓ |
| assertions | role_bindings_exist | authz.role_bindings | ✗ |
| assertions | rbac_unit_active | service.status | ✓ |
| assertions | authz_layer_complete | authz.check | ✗ |

## Baseline Captures

```json
{
  "initial_role_bindings": {
    "count": 0
  }
}
```
