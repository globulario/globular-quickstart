# etcd-write-verified

**Suite**: functional  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-13T00:31:10.989168Z  
**Checks**: 9 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | all_etcd_members_healthy | cluster.etcd_members | ✓ |
| baseline | initial_write_test | etcd.write_test | ✓ |
| assertions | write_test_succeeds | etcd.write_test | ✓ |
| assertions | write_latency_acceptable | etcd.write_test | ✓ |
| assertions | all_members_healthy | cluster.etcd_members | ✓ |
| assertions | cluster_still_healthy | cluster.health | ✓ |
| cleanup | final_write_test | etcd.write_test | ✓ |
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
  "initial_write_test": {
    "success": true,
    "latency_ms": 285
  }
}
```
