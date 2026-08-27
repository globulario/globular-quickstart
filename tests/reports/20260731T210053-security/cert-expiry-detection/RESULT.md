# cert-expiry-detection

**Suite**: security  
**Result**: PARTIAL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-07-31T21:00:53.564621Z  
**Checks**: 7 passed, 4 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | node3_cert_valid_before | pki.cert_expiry_days | ✓ |
| baseline | cert_info_before | pki.cert_info | ✓ |
| baseline | expiry_days_before | pki.cert_expiry_days | ✓ |
| steps | inject_expired_cert | chaos.inject_expired_cert | ✓ |
| steps | verify_cert_expired | pki.cert_expiry_days | ✗ |
| steps | wait_for_repair | pki.cert_expiry_days | ✗ |
| assertions | cert_valid_after_repair | pki.cert_expiry_days | ✗ |
| assertions | cert_chain_valid | pki.cert_info | ✗ |
| assertions | cluster_healthy_after | cluster.health | ✓ |
| cleanup | restore_cert_backup | chaos.restore_cert | ✓ |

## Pattern Validation

**Pattern result**: SKIPPED  
See [PATTERNS.md](PATTERNS.md) for full pattern evidence.

## Baseline Captures

```json
{
  "cert_info_before": {
    "valid": true,
    "days_remaining": 359,
    "has_vip": false,
    "not_after": "Jul 26 20:50:14 2027 GMT",
    "node": "node-3"
  },
  "expiry_days_before": {
    "days_remaining": 359,
    "expired": false,
    "node": "node-3",
    "cert_path": "/var/lib/globular/pki/issued/services/service.crt"
  }
}
```
