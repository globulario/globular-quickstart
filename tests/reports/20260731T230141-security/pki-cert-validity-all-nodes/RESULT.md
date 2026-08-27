# pki-cert-validity-all-nodes

**Suite**: security  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-07-31T23:18:01.448093Z  
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

## Pattern Validation

**Pattern result**: SKIPPED  
See [PATTERNS.md](PATTERNS.md) for full pattern evidence.

## Baseline Captures

```json
{
  "node1_cert_baseline": {
    "valid": true,
    "days_remaining": 364,
    "has_vip": false,
    "not_after": "Jul 31 22:43:04 2027 GMT",
    "node": "node-1"
  },
  "final_cert_check": {
    "valid": true,
    "days_remaining": 364,
    "has_vip": false,
    "not_after": "Jul 31 22:43:04 2027 GMT",
    "node": "node-1"
  }
}
```
