# rollback-guard-refuses-silent-regression

**Suite**: upgrade  
**Result**: FAIL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-24T01:28:09.096215Z  
**Checks**: 10 passed, 1 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | releases_are_clean | release.audit | ✓ |
| baseline | convergence_before | cluster.installed_version_convergence | ✓ |
| steps | refuse_backwards_step | ops.set_desired | ✓ |
| steps | override_does_not_bypass_resolvability | ops.set_desired | ✓ |
| assertions | installed_version_unchanged | cluster.installed_version_convergence | ✗ |
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
      "globular-node-1"
    ],
    "etcd_healthy_endpoints": 1,
    "etcd_member_count": "1",
    "pki": {
      "node-1": "globular:globular/400 readable backups=0",
      "node-2": "node-not-running",
      "node-3": "node-not-running",
      "node-4": "node-not-running",
      "node-5": "node-not-running"
    }
  },
  "convergence_before": {
    "nodes": 0,
    "converged": 0,
    "lagging": 0,
    "versions": "",
    "unique": 0
  }
}
```

## Proof Contract

- Contract declared: no (legacy scenario)
- Proof status: SUPPORTED
- Execution result: FAIL
- Production authoritative: **no** — simulation output is candidate evidence until governed promotion.
- Machine artifacts: `scenario-proof.json`, `learning.json`
