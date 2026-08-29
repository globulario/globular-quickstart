# rollback-guard-refuses-silent-regression

**Suite**: upgrade  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-29T07:54:11.241658Z  
**Checks**: 11 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | releases_are_clean | release.audit | ✓ |
| baseline | convergence_before | cluster.installed_version_convergence | ✓ |
| steps | refuse_backwards_step | ops.set_desired | ✓ |
| steps | override_does_not_bypass_resolvability | ops.set_desired | ✓ |
| assertions | installed_version_unchanged | cluster.installed_version_convergence | ✓ |
| assertions | no_release_failures_introduced | release.audit | ✓ |
| assertions | repository_identity_still_clean | repository.identity_findings | ✓ |
| assertions | cluster_still_healthy | cluster.health | ✓ |
| assertions | liveness_unaffected | state.liveness_freshness | ✓ |
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
  "convergence_before": {
    "nodes": 5,
    "converged": 5,
    "lagging": 0,
    "versions": "1.2.329,1.2.329,1.2.329,1.2.329,1.2.329",
    "unique": 1
  }
}
```

## Proof Contract

- Contract declared: no (legacy scenario)
- Proof status: SUPPORTED
- Execution result: PASS
- Production authoritative: **no** — simulation output is candidate evidence until governed promotion.
- Machine artifacts: `scenario-proof.json`, `learning.json`
