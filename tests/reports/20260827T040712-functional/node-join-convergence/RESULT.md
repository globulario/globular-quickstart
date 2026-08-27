# node-join-convergence

**Suite**: functional  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-27T04:11:25.858116Z  
**Checks**: 17 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | target_node_registered_before | node.etcd_registered | ✓ |
| baseline | installed_packages_before | node.installed_packages | ✓ |
| baseline | desired_state_before | cluster.desired_state | ✓ |
| steps | stop_target_node | chaos.stop_node | ✓ |
| steps | wait_for_departure_observed | cluster.health | ✓ |
| steps | start_target_node | chaos.start_node | ✓ |
| steps | wait_for_reregistration | node.etcd_registered | ✓ |
| steps | wait_for_convergence | cluster.reconcile_clean | ✓ |
| steps | wait_for_doctor_to_settle | doctor.report_severity | ✓ |
| assertions | node_registered_after | node.etcd_registered | ✓ |
| assertions | etcd_membership_intact | cluster.etcd_members | ✓ |
| assertions | cluster_healthy_after | cluster.health | ✓ |
| assertions | reconcile_clean_after | cluster.reconcile_clean | ✓ |
| assertions | packages_installed_after | node.installed_packages | ✓ |
| cleanup | final_cluster_health | cluster.health | ✓ |
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
  "installed_packages_before": {
    "count": 28,
    "node": "node-5",
    "uuid": "35ac3821-6b90-52eb-a800-41130471770b"
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
  "packages_installed_after": {
    "count": 28,
    "node": "node-5",
    "uuid": "35ac3821-6b90-52eb-a800-41130471770b"
  }
}
```

## Proof Contract

- Contract declared: no (legacy scenario)
- Proof status: SUPPORTED
- Execution result: PASS
- Production authoritative: **no** — simulation output is candidate evidence until governed promotion.
- Machine artifacts: `scenario-proof.json`, `learning.json`
