# pki-cert-validity-all-nodes

**Suite**: security  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-12T13:52:20.996823Z  
**Checks**: 14 passed, 0 failed

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
  "node1_cert_baseline": {
    "valid": true,
    "chain_valid": true,
    "days_remaining": 364,
    "has_vip": false,
    "vip_configured": false,
    "vip_san_ok": true,
    "not_after": "Aug 12 13:24:30 2027 GMT",
    "node": "node-1"
  },
  "final_cert_check": {
    "valid": true,
    "chain_valid": true,
    "days_remaining": 364,
    "has_vip": false,
    "vip_configured": false,
    "vip_san_ok": true,
    "not_after": "Aug 12 13:24:30 2027 GMT",
    "node": "node-1"
  }
}
```
