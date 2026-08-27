# package-upgrade-converges-on-all-nodes

**Suite**: upgrade  
**Result**: FAIL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-17T08:01:45.805456Z  
**Checks**: 10 passed, 1 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | nodes_present | cluster.nodes | ✓ |
| baseline | installed_versions_at_start | cluster.installed_version_convergence | ✓ |
| assertions | node_agent_single_version_cluster_wide | cluster.installed_version_convergence | ✓ |
| assertions | cluster_controller_single_version_cluster_wide | cluster.installed_version_convergence | ✓ |
| assertions | no_drift_between_desired_and_installed | cluster.reconcile_clean | ✗ |
| assertions | service_registry_is_populated | cluster.service_matrix | ✓ |
| assertions | doctor_reports_no_errors | doctor.report_severity | ✓ |
| assertions | resolution_is_deterministic | repository.identity_findings | ✓ |
| assertions | liveness_is_current | state.liveness_freshness | ✓ |
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
  "installed_versions_at_start": {
    "nodes": 6,
    "converged": 6,
    "lagging": 0,
    "versions": "1.2.319,1.2.319,1.2.319,1.2.319,1.2.319,1.2.319",
    "unique": 1
  }
}
```
