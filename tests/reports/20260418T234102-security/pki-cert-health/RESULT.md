# pki-cert-health

**Suite**: security  
**Result**: PASS  
**Time**: 2026-04-18T23:41:03.879735Z  
**Checks**: 11 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| baseline | ca_cert_baseline | pki.ca_valid | ✓ |
| assertions | ca_cert_valid_node1 | pki.ca_valid | ✓ |
| assertions | service_cert_node1 | pki.cert_info | ✓ |
| assertions | service_cert_node2 | pki.cert_info | ✓ |
| assertions | service_cert_node3 | pki.cert_info | ✓ |
| assertions | service_cert_node4 | pki.cert_info | ✓ |
| assertions | service_cert_node5 | pki.cert_info | ✓ |
| assertions | signing_keys_node1 | pki.signing_keys | ✓ |
| assertions | signing_keys_node2 | pki.signing_keys | ✓ |
| cleanup | final_cluster_health | cluster.health | ✓ |

## Baseline Captures

```json
{
  "ca_cert_baseline": {
    "valid": true,
    "days_remaining": 3646,
    "not_after": "Apr 12 23:17:32 2036 GMT",
    "node": "node-1"
  }
}
```
