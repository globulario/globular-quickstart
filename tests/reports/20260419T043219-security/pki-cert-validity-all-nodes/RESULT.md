# pki-cert-validity-all-nodes

**Suite**: security  
**Result**: PASS  
**Time**: 2026-04-19T04:32:26.574042Z  
**Checks**: 13 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| baseline | node1_cert_baseline | pki.cert_info | ✓ |
| assertions | ca_valid_node1 | pki.ca_valid | ✓ |
| assertions | ca_valid_node2 | pki.ca_valid | ✓ |
| assertions | ca_valid_node3 | pki.ca_valid | ✓ |
| assertions | ca_valid_node4 | pki.ca_valid | ✓ |
| assertions | ca_valid_node5 | pki.ca_valid | ✓ |
| assertions | service_cert_node1 | pki.cert_info | ✓ |
| assertions | service_cert_node2 | pki.cert_info | ✓ |
| assertions | service_cert_node3 | pki.cert_info | ✓ |
| assertions | service_cert_node4 | pki.cert_info | ✓ |
| assertions | service_cert_node5 | pki.cert_info | ✓ |
| cleanup | final_cert_check | pki.cert_info | ✓ |

## Baseline Captures

```json
{
  "node1_cert_baseline": {
    "valid": true,
    "days_remaining": 361,
    "has_vip": true,
    "not_after": "Apr 15 23:17:32 2027 GMT",
    "node": "node-1"
  },
  "final_cert_check": {
    "valid": true,
    "days_remaining": 361,
    "has_vip": true,
    "not_after": "Apr 15 23:17:32 2027 GMT",
    "node": "node-1"
  }
}
```
