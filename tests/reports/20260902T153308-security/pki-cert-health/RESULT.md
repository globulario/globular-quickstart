# pki-cert-health

**Suite**: security  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-09-02T15:34:09.570933Z  
**Checks**: 12 passed, 0 failed

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
  "ca_cert_baseline": {
    "valid": true,
    "days_remaining": 3649,
    "not_after": "Aug 30 15:07:47 2036 GMT",
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
