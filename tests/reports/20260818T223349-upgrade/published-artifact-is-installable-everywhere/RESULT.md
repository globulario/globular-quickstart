# published-artifact-is-installable-everywhere

**Suite**: upgrade  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-18T23:13:28.556342Z  
**Checks**: 8 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | all_five_nodes_visible | repository.blob_reachable_all_nodes | ✓ |
| baseline | identity_findings_at_start | repository.identity_findings | ✓ |
| assertions | blob_present_on_every_node | repository.blob_reachable_all_nodes | ✓ |
| assertions | no_missing_blob_findings | repository.identity_findings | ✓ |
| assertions | no_ambiguous_resolution | repository.identity_findings | ✓ |
| assertions | no_build_id_checksum_conflicts | repository.identity_findings | ✓ |
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
  "identity_findings_at_start": {
    "total": 0,
    "ambiguous": 0,
    "missing_blob": 0,
    "conflict": 0
  }
}
```
