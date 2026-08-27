# platform-upgrade-release-boundary

**Suite**: upgrade  
**Result**: PARTIAL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-23T23:53:50.965338Z  
**Checks**: 7 passed, 2 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| baseline | release_audit_at_start | release.audit | ✓ |
| steps | let_in_flight_releases_settle | release.audit | ✗ |
| assertions | release_boundary_is_unambiguous | release.audit | ✗ |
| assertions | desired_state_is_present | cluster.desired_state | ✓ |
| assertions | release_packages_have_blobs | repository.identity_findings | ✓ |
| assertions | installed_packages_present_on_every_node | cluster.installed_packages | ✓ |
| assertions | no_drift | cluster.reconcile_clean | ✓ |
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
  "release_audit_at_start": {
    "total": 24,
    "succeeded": 15,
    "failed": 4,
    "pending": 5
  }
}
```

## Proof Contract

- Contract declared: no (legacy scenario)
- Proof status: SUPPORTED
- Execution result: PARTIAL
- Production authoritative: **no** — simulation output is candidate evidence until governed promotion.
- Machine artifacts: `scenario-proof.json`, `learning.json`
