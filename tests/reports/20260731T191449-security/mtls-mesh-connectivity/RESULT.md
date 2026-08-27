# mtls-mesh-connectivity

**Suite**: security  
**Result**: FAIL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-07-31T19:30:33.904173Z  
**Checks**: 12 passed, 1 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | pki_ca_valid | pki.ca_valid | ✓ |
| baseline | cert_info_baseline | pki.cert_info | ✓ |
| assertions | node1_to_controller_node2 | pki.mtls_connect | ✓ |
| assertions | node1_to_doctor_node2 | pki.mtls_connect | ✗ |
| assertions | node2_to_rbac_node1 | pki.mtls_connect | ✓ |
| assertions | node2_to_etcd_node1 | pki.mtls_connect | ✓ |
| assertions | node3_to_authentication_node1 | pki.mtls_connect | ✓ |
| assertions | node3_to_etcd_node1 | pki.mtls_connect | ✓ |
| assertions | node4_to_etcd_node1 | pki.mtls_connect | ✓ |
| assertions | node5_to_etcd_node1 | pki.mtls_connect | ✓ |
| assertions | node1_to_self_etcd | pki.mtls_connect | ✓ |
| cleanup | final_health | cluster.health | ✓ |

## Pattern Validation

**Pattern result**: SKIPPED  
See [PATTERNS.md](PATTERNS.md) for full pattern evidence.

## Baseline Captures

```json
{
  "cert_info_baseline": {
    "valid": true,
    "days_remaining": 364,
    "has_vip": false,
    "not_after": "Jul 31 19:01:00 2027 GMT",
    "node": "node-1"
  }
}
```
