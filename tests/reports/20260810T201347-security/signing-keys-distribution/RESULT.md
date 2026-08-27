# signing-keys-distribution

**Suite**: security  
**Result**: FAIL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-10T20:17:55.597993Z  
**Checks**: 4 passed, 5 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| baseline | key_count_baseline_node1 | pki.signing_keys | ✓ |
| assertions | signing_keys_node1 | pki.signing_keys | ✗ |
| assertions | signing_keys_node2 | pki.signing_keys | ✗ |
| assertions | signing_keys_node3 | pki.signing_keys | ✗ |
| assertions | signing_keys_node4 | pki.signing_keys | ✗ |
| assertions | signing_keys_node5 | pki.signing_keys | ✗ |
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
    "etcd_healthy_endpoints": 1,
    "etcd_member_count": "1",
    "pki": {
      "node-1": "globular:globular/400 readable backups=0",
      "node-2": "missing UNREADABLE backups=0",
      "node-3": "missing UNREADABLE backups=0",
      "node-4": "missing UNREADABLE backups=0",
      "node-5": "missing UNREADABLE backups=0"
    }
  },
  "key_count_baseline_node1": {
    "present": false,
    "key_count": 0,
    "node_key_present": false,
    "node": "node-1"
  }
}
```
