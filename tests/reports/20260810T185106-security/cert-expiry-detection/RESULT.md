# cert-expiry-detection

**Suite**: security  
**Result**: POSTCONDITION  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-10T18:51:06.408794Z  
**Checks**: 8 passed, 4 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | node3_cert_valid_before | pki.cert_expiry_days | ✓ |
| baseline | cert_info_before | pki.cert_info | ✓ |
| baseline | expiry_days_before | pki.cert_expiry_days | ✓ |
| steps | inject_expired_cert | chaos.inject_expired_cert | ✓ |
| steps | verify_cert_expired | pki.cert_expiry_days | ✓ |
| steps | wait_for_repair | pki.cert_expiry_days | ✗ |
| assertions | cert_valid_after_repair | pki.cert_expiry_days | ✗ |
| assertions | cert_chain_valid | pki.cert_info | ✗ |
| assertions | cluster_healthy_after | cluster.health | ✓ |
| cleanup | restore_cert_backup | chaos.restore_cert | ✓ |
| postconditions | cluster_returned_to_baseline | health.fingerprint | ✗ |

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
      "globular-node-3"
    ],
    "etcd_healthy_endpoints": 3,
    "etcd_member_count": "5",
    "pki": {
      "node-1": "globular:globular/400 readable backups=0",
      "node-2": "globular:globular/600 readable backups=0",
      "node-3": "globular:globular/600 readable backups=0",
      "node-4": "node-not-running",
      "node-5": "node-not-running"
    }
  },
  "cert_info_before": {
    "valid": true,
    "days_remaining": 359,
    "has_vip": false,
    "vip_configured": false,
    "vip_san_ok": true,
    "not_after": "Aug  5 17:56:28 2027 GMT",
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
