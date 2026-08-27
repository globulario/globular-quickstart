# pki-mesh-valid

**Suite**: functional  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-07-31T16:30:22.451492Z  
**Checks**: 16 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| baseline | ca_baseline | pki.ca_valid | ✓ |
| assertions | ca_valid_node1 | pki.ca_valid | ✓ |
| assertions | ca_valid_node2 | pki.ca_valid | ✓ |
| assertions | ca_valid_node3 | pki.ca_valid | ✓ |
| assertions | service_cert_node1 | pki.cert_info | ✓ |
| assertions | service_cert_node2 | pki.cert_info | ✓ |
| assertions | service_cert_node3 | pki.cert_info | ✓ |
| assertions | service_cert_node4 | pki.cert_info | ✓ |
| assertions | service_cert_node5 | pki.cert_info | ✓ |
| assertions | signing_keys_node1 | pki.signing_keys | ✓ |
| assertions | signing_keys_node2 | pki.signing_keys | ✓ |
| assertions | signing_keys_node3 | pki.signing_keys | ✓ |
| assertions | signing_keys_node4 | pki.signing_keys | ✓ |
| assertions | signing_keys_node5 | pki.signing_keys | ✓ |
| cleanup | final_ca_check | pki.ca_valid | ✓ |

## Pattern Validation

**Pattern result**: SKIPPED  
See [PATTERNS.md](PATTERNS.md) for full pattern evidence.

## Baseline Captures

```json
{
  "ca_baseline": {
    "valid": true,
    "days_remaining": 3649,
    "not_after": "Jul 28 16:29:51 2036 GMT",
    "node": "node-1"
  }
}
```
