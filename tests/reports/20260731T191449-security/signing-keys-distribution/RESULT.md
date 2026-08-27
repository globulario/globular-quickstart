# signing-keys-distribution

**Suite**: security  
**Result**: FAIL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-07-31T19:31:33.005938Z  
**Checks**: 5 passed, 3 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| baseline | key_count_baseline_node1 | pki.signing_keys | ✓ |
| assertions | signing_keys_node1 | pki.signing_keys | ✗ |
| assertions | signing_keys_node2 | pki.signing_keys | ✗ |
| assertions | signing_keys_node3 | pki.signing_keys | ✗ |
| assertions | signing_keys_node4 | pki.signing_keys | ✓ |
| assertions | signing_keys_node5 | pki.signing_keys | ✓ |
| cleanup | final_health | cluster.health | ✓ |

## Pattern Validation

**Pattern result**: SKIPPED  
See [PATTERNS.md](PATTERNS.md) for full pattern evidence.

## Baseline Captures

```json
{
  "key_count_baseline_node1": {
    "present": true,
    "key_count": 16,
    "node_key_present": false,
    "node": "node-1"
  }
}
```
