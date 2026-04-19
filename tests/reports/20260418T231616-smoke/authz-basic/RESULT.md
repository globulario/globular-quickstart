# authz-basic

**Suite**: smoke  
**Result**: PASS  
**Time**: 2026-04-18T23:16:16.599487Z  
**Checks**: 9 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | rbac_service_registered | service.registered | ✓ |
| baseline | initial_role_binding_count | authz.role_bindings | ✓ |
| steps | wait_for_rbac_seeded | service.registered | ✓ |
| assertions | rbac_service_present | service.registered | ✓ |
| assertions | rbac_unit_active | service.status | ✓ |
| assertions | authz_layer_reachable | authz.check | ✓ |
| assertions | bootstrap_bindings_present | authz.role_bindings | ✓ |
| cleanup | final_cluster_health | cluster.health | ✓ |

## Baseline Captures

```json
{
  "initial_role_binding_count": {
    "count": 0
  }
}
```
