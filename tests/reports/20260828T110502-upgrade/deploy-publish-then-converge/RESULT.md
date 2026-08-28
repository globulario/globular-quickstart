# deploy-publish-then-converge

**Suite**: upgrade  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-28T11:05:02.559505Z  
**Checks**: 18 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | resolution_clean_before | repository.identity_findings | ✓ |
| preconditions | all_five_nodes_visible | repository.blob_reachable_all_nodes | ✓ |
| baseline | identity_findings_before | repository.identity_findings | ✓ |
| baseline | desired_state_before | cluster.desired_state | ✓ |
| baseline | convergence_before | cluster.installed_version_convergence | ✓ |
| steps | publish_dns_again | ops.publish | ✓ |
| steps | let_seeding_propagate | repository.blob_reachable_all_nodes | ✓ |
| steps | point_desired_at_published_version | ops.set_desired | ✓ |
| steps | let_convergence_run | cluster.installed_version_convergence | ✓ |
| assertions | blob_reachable_from_every_node | repository.blob_reachable_all_nodes | ✓ |
| assertions | no_missing_blob_findings | repository.identity_findings | ✓ |
| assertions | republish_left_resolution_unambiguous | repository.identity_findings | ✓ |
| assertions | every_node_converged_on_the_published_version | cluster.installed_version_convergence | ✓ |
| assertions | reconcile_clean | cluster.reconcile_clean | ✓ |
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
  "identity_findings_before": {
    "total": 0,
    "ambiguous": 0,
    "missing_blob": 0,
    "conflict": 0
  },
  "desired_state_before": {
    "count": 24,
    "services": [
      "ai-executor",
      "ai-memory",
      "ai-router",
      "ai-watcher",
      "authentication",
      "backup-manager",
      "cluster-controller",
      "cluster-doctor",
      "dns",
      "event",
      "file",
      "log",
      "mcp",
      "media",
      "monitoring",
      "node-agent",
      "persistence",
      "rbac",
      "repository",
      "resource",
      "search",
      "title",
      "torrent",
      "workflow"
    ]
  },
  "convergence_before": {
    "nodes": 5,
    "converged": 5,
    "lagging": 0,
    "versions": "1.2.317,1.2.317,1.2.317,1.2.317,1.2.317",
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
