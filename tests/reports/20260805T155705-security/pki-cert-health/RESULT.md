# pki-cert-health

**Suite**: security  
**Result**: FAIL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-05T16:13:03.341466Z  
**Checks**: 8 passed, 3 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| baseline | ca_cert_baseline | pki.ca_valid | ✓ |
| assertions | ca_cert_valid_node1 | pki.ca_valid | ✓ |
| assertions | service_cert_node1 | pki.cert_info | ✗ |
| assertions | service_cert_node2 | pki.cert_info | ✓ |
| assertions | service_cert_node3 | pki.cert_info | ✓ |
| assertions | service_cert_node4 | pki.cert_info | ✓ |
| assertions | service_cert_node5 | pki.cert_info | ✓ |
| assertions | signing_keys_node1 | pki.signing_keys | ✗ |
| assertions | signing_keys_node2 | pki.signing_keys | ✗ |
| cleanup | final_cluster_health | cluster.health | ✓ |

## Pattern Validation

**Pattern result**: SKIPPED  
See [PATTERNS.md](PATTERNS.md) for full pattern evidence.

## Baseline Captures

```json
{
  "ca_cert_baseline": {
    "valid": true,
    "days_remaining": 3649,
    "not_after": "Aug  2 15:38:36 2036 GMT",
    "node": "node-1"
  }
}
```
