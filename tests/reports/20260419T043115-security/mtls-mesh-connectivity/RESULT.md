# mtls-mesh-connectivity

**Suite**: security  
**Result**: PASS  
**Time**: 2026-04-19T04:31:17.499107Z  
**Checks**: 13 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | pki_ca_valid | pki.ca_valid | ✓ |
| baseline | cert_info_baseline | pki.cert_info | ✓ |
| assertions | node1_to_controller_node2 | pki.mtls_connect | ✓ |
| assertions | node1_to_doctor_node2 | pki.mtls_connect | ✓ |
| assertions | node2_to_rbac_node1 | pki.mtls_connect | ✓ |
| assertions | node2_to_etcd_node1 | pki.mtls_connect | ✓ |
| assertions | node3_to_authentication_node1 | pki.mtls_connect | ✓ |
| assertions | node3_to_etcd_node1 | pki.mtls_connect | ✓ |
| assertions | node4_to_etcd_node1 | pki.mtls_connect | ✓ |
| assertions | node5_to_etcd_node1 | pki.mtls_connect | ✓ |
| assertions | node1_to_self_etcd | pki.mtls_connect | ✓ |
| cleanup | final_health | cluster.health | ✓ |

## Baseline Captures

```json
{
  "cert_info_baseline": {
    "valid": true,
    "days_remaining": 361,
    "has_vip": true,
    "not_after": "Apr 15 23:17:32 2027 GMT",
    "node": "node-1"
  }
}
```
