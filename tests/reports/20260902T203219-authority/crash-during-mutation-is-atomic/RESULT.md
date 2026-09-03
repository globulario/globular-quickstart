# crash-during-mutation-is-atomic

**Suite**: authority  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-09-02T20:38:12.793106Z  
**Checks**: 19 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | identity_clean_before | repository.identity_findings | ✓ |
| preconditions | liveness_settled_before | state.liveness_freshness | ✓ |
| baseline | desired_state_before | cluster.desired_state | ✓ |
| baseline | convergence_before | cluster.installed_version_convergence | ✓ |
| steps | begin_the_mutation | ops.set_desired | ✓ |
| steps | kill_the_controller_mid_flight | chaos.sigkill_service | ✓ |
| steps | let_interrupted_release_reach_terminal_state | release.audit | ✓ |
| assertions | no_duplicate_or_partial_artifacts | repository.identity_findings | ✓ |
| assertions | desired_state_coherent | cluster.desired_state | ✓ |
| assertions | single_installed_version | cluster.installed_version_convergence | ✓ |
| assertions | no_release_left_failed | release.audit | ✓ |
| assertions | controller_is_serving_again | service.status | ✓ |
| assertions | leadership_reestablished | controller.leadership | ✓ |
| assertions | cluster_healthy_after | cluster.health | ✓ |
| assertions | reconcile_not_looping | cluster.reconcile_clean | ✓ |
| assertions | liveness_current | state.liveness_freshness | ✓ |
| restoration | enforce_restoration | restoration | ✓ |
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
    "versions": "1.2.331,1.2.331,1.2.331,1.2.331,1.2.331",
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
