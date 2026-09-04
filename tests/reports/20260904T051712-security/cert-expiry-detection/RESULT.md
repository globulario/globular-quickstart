# cert-expiry-detection

**Suite**: security  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-09-04T05:17:31.646068Z  
**Checks**: 12 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | node3_cert_valid_before | pki.cert_expiry_days | ✓ |
| baseline | cert_info_before | pki.cert_info | ✓ |
| baseline | expiry_days_before | pki.cert_expiry_days | ✓ |
| steps | inject_expired_cert | chaos.inject_expired_cert | ✓ |
| steps | verify_cert_expired | pki.cert_expiry_days | ✓ |
| steps | wait_for_repair | pki.cert_expiry_days | ✓ |
| assertions | cert_valid_after_repair | pki.cert_expiry_days | ✓ |
| assertions | cert_chain_valid | pki.cert_info | ✓ |
| assertions | cluster_healthy_after | cluster.health | ✓ |
| cleanup | restore_cert_backup | chaos.restore_cert | ✓ |
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
  "cert_info_before": {
    "valid": true,
    "chain_valid": true,
    "days_remaining": 359,
    "has_vip": false,
    "vip_configured": false,
    "vip_san_ok": true,
    "node_ip": "10.10.0.13",
    "has_node_ip": true,
    "node_ip_san_ok": true,
    "not_after": "Aug 30 04:55:01 2027 GMT",
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

## Proof Contract

- Contract declared: no (legacy scenario)
- Proof status: SUPPORTED
- Execution result: PASS
- Production authoritative: **no** — simulation output is candidate evidence until governed promotion.
- Machine artifacts: `scenario-proof.json`, `learning.json`
