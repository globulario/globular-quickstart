# signing-keys-distribution

**Suite**: security  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-23T13:22:57.895354Z  
**Checks**: 9 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| baseline | key_count_baseline_node1 | pki.signing_keys | ✓ |
| assertions | signing_keys_node1 | pki.signing_keys | ✓ |
| assertions | signing_keys_node2 | pki.signing_keys | ✓ |
| assertions | signing_keys_node3 | pki.signing_keys | ✓ |
| assertions | signing_keys_node4 | pki.signing_keys | ✓ |
| assertions | signing_keys_node5 | pki.signing_keys | ✓ |
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
  "key_count_baseline_node1": {
    "present": true,
    "key_count": 16,
    "node_key_present": true,
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
