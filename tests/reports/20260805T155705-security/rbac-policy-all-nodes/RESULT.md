# rbac-policy-all-nodes

**Suite**: security  
**Result**: FAIL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-05T16:13:21.771953Z  
**Checks**: 9 passed, 3 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | rbac_service_registered | service.registered | ✓ |
| baseline | initial_role_bindings | authz.role_bindings | ✓ |
| assertions | policy_file_node1 | rbac.policy_file | ✗ |
| assertions | policy_file_node2 | rbac.policy_file | ✗ |
| assertions | policy_file_node3 | rbac.policy_file | ✗ |
| assertions | rbac_registered | service.registered | ✓ |
| assertions | rbac_unit_active_node1 | service.status | ✓ |
| assertions | rbac_unit_active_node2 | service.status | ✓ |
| assertions | rbac_unit_active_node3 | service.status | ✓ |
| assertions | authz_layer_reachable | authz.check | ✓ |
| cleanup | final_health | cluster.health | ✓ |

## Pattern Validation

**Pattern result**: SKIPPED  
See [PATTERNS.md](PATTERNS.md) for full pattern evidence.

## Baseline Captures

```json
{
  "initial_role_bindings": {
    "count": 0
  }
}
```
