# rbac-policy-all-nodes

**Suite**: security  
**Result**: PASS  
**Time**: 2026-04-19T05:07:16.564885Z  
**Checks**: 12 passed, 0 failed

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
| assertions | rbac_unit_active_node1 | service.status | ✓ |
| assertions | rbac_unit_active_node2 | service.status | ✓ |
| assertions | rbac_unit_active_node3 | service.status | ✓ |
| assertions | authz_layer_reachable | authz.check | ✓ |
| cleanup | final_health | cluster.health | ✓ |

## Baseline Captures

```json
{
  "initial_role_bindings": {
    "count": 0
  }
}
```
