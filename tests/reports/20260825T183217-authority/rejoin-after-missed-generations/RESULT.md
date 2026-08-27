# rejoin-after-missed-generations

**Suite**: authority  
**Result**: PARTIAL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-25T19:33:14.587007Z  
**Checks**: 16 passed, 4 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | target_node_running | node.container_running | ✓ |
| preconditions | liveness_settled_before | state.liveness_freshness | ✓ |
| baseline | desired_state_before | cluster.desired_state | ✓ |
| baseline | convergence_before | cluster.installed_version_convergence | ✓ |
| steps | take_the_node_down | chaos.stop_node | ✓ |
| steps | advance_generation_1 | ops.set_desired | ✗ |
| steps | advance_generation_2 | ops.set_desired | ✗ |
| steps | advance_generation_3 | ops.set_desired | ✗ |
| steps | bring_the_node_back | chaos.start_node | ✓ |
| assertions | node_registered_again | node.etcd_registered | ✓ |
| assertions | cluster_sees_all_five | cluster.health | ✓ |
| assertions | single_version_cluster_wide | cluster.installed_version_convergence | ✓ |
| assertions | desired_state_not_rolled_back | cluster.desired_state | ✓ |
| assertions | no_identity_conflicts | repository.identity_findings | ✓ |
| assertions | no_doctor_errors | doctor.report_severity | ✗ |
| assertions | reconcile_settled | cluster.reconcile_clean | ✓ |
| assertions | liveness_current_everywhere | state.liveness_freshness | ✓ |
| cleanup | ensure_node_running | chaos.start_node | ✓ |
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
    "etcd_healthy_endpoints": 3,
    "etcd_member_count": "4",
    "pki": {
      "node-1": "globular:globular/400 readable backups=0",
      "node-2": "globular:globular/600 readable backups=0",
      "node-3": "globular:globular/600 readable backups=0",
      "node-4": "globular:globular/600 readable backups=0",
      "node-5": "globular:globular/600 readable backups=0"
    }
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
    "versions": "1.2.326,1.2.326,1.2.326,1.2.326,1.2.326",
    "unique": 1
  }
}
```

## Proof Contract

- Contract declared: no (legacy scenario)
- Proof status: SUPPORTED
- Execution result: PARTIAL
- Production authoritative: **no** — simulation output is candidate evidence until governed promotion.
- Machine artifacts: `scenario-proof.json`, `learning.json`
