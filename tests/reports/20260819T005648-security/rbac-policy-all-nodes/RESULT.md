# rbac-policy-all-nodes

**Suite**: security  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-19T00:58:32.641250Z  
**Checks**: 13 passed, 0 failed

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
  "initial_role_bindings": {
    "count": 0
  }
}
```
