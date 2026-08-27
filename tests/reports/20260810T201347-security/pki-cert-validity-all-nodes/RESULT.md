# pki-cert-validity-all-nodes

**Suite**: security  
**Result**: FAIL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-10T20:17:16.987912Z  
**Checks**: 2 passed, 1 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✗ |
| cleanup | final_cert_check | pki.cert_info | ✓ |
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
    "etcd_healthy_endpoints": 0,
    "etcd_member_count": "0",
    "pki": {
      "node-1": "root:root/400 UNREADABLE backups=0",
      "node-2": "missing UNREADABLE backups=0",
      "node-3": "missing UNREADABLE backups=0",
      "node-4": "missing UNREADABLE backups=0",
      "node-5": "missing UNREADABLE backups=0"
    }
  },
  "final_cert_check": {
    "valid": true,
    "days_remaining": 364,
    "has_vip": false,
    "vip_configured": false,
    "vip_san_ok": true,
    "not_after": "Aug 10 20:14:33 2027 GMT",
    "node": "node-1"
  }
}
```
