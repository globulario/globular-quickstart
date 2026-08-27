# mtls-mesh-connectivity

**Suite**: security  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-27T04:17:05.633642Z  
**Checks**: 14 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | pki_ca_valid | pki.ca_valid | ✓ |
| baseline | cert_info_baseline | pki.cert_info | ✓ |
| assertions | node1_to_controller_node2 | pki.mtls_connect | ✓ |
| assertions | node1_to_doctor_node2 | pki.mtls_connect | ✓ |
| assertions | node2_to_rbac_node1 | pki.mtls_connect | ✓ |
| assertions | node2_to_etcd_node1 | pki.mtls_connect | ✓ |
| assertions | node3_to_authentication_node1 | pki.mtls_connect | ✓ |
| assertions | node3_to_etcd_node1 | pki.mtls_connect | ✓ |
| assertions | node4_to_etcd_node1 | pki.mtls_connect | ✓ |
| assertions | node5_to_etcd_node1 | pki.mtls_connect | ✓ |
| assertions | node1_to_self_etcd | pki.mtls_connect | ✓ |
| cleanup | final_health | cluster.health | ✓ |
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
  "cert_info_baseline": {
    "valid": true,
    "chain_valid": true,
    "days_remaining": 364,
    "has_vip": false,
    "vip_configured": false,
    "vip_san_ok": true,
    "not_after": "Aug 27 03:39:56 2027 GMT",
    "node": "node-1"
  }
}
```

## Proof Contract

- Contract declared: no (legacy scenario)
- Proof status: SUPPORTED
- Execution result: PASS
- Production authoritative: **no** — simulation output is candidate evidence until governed promotion.
- Machine artifacts: `scenario-proof.json`, `learning.json`
