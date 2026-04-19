# signing-keys-distribution

**Suite**: security  
**Result**: PASS  
**Time**: 2026-04-19T04:31:30.805716Z  
**Checks**: 8 passed, 0 failed

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

## Baseline Captures

```json
{
  "key_count_baseline_node1": {
    "present": true,
    "key_count": 8,
    "node_key_present": true,
    "node": "node-1"
  }
}
```
