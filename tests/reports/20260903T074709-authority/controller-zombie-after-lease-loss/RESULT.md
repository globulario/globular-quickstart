# controller-zombie-after-lease-loss

**Suite**: authority  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-09-03T07:47:09.607643Z  
**Checks**: 19 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | leadership_is_established | controller.leadership | ✓ |
| preconditions | etcd_accepts_writes | etcd.write_test | ✓ |
| preconditions | liveness_settled_before | state.liveness_freshness | ✓ |
| baseline | leadership_before | controller.leadership | ✓ |
| baseline | desired_state_before | cluster.desired_state | ✓ |
| steps | freeze_the_leader | chaos.pause_service | ✓ |
| steps | new_leader_mutates_desired_state | ops.set_desired | ✓ |
| steps | thaw_the_zombie | chaos.resume_all_controllers | ✓ |
| assertions | exactly_one_leader_address | controller.leadership | ✓ |
| assertions | desired_state_intact | cluster.desired_state | ✓ |
| assertions | no_ambiguous_resolution_introduced | repository.identity_findings | ✓ |
| assertions | no_doctor_errors | doctor.report_severity | ✓ |
| assertions | reconcile_clean_after_thaw | cluster.reconcile_clean | ✓ |
| assertions | cluster_healthy_after_thaw | cluster.health | ✓ |
| assertions | etcd_still_accepts_writes | etcd.write_test | ✓ |
| assertions | liveness_current | state.liveness_freshness | ✓ |
| cleanup | ensure_no_controller_left_frozen | chaos.resume_all_controllers | ✓ |
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
  "leadership_before": {
    "leader_addr": "10.10.0.11:12000",
    "leader_node": "node-1",
    "has_leader": true,
    "claimants": 3,
    "instances": "node-1:21739:632f25a0-ef54-49e7-be3f-054ac072e0f3,node-2:4013:a19cb33f-15b5-4c56-8964-fcf93e49e977,node-3:4667:4a6fbd77-4111-421e-bd80-e7782f474868",
    "leader_instance": "node-1:21739:632f25a0-ef54-49e7-be3f-054ac072e0f3",
    "distinct_leaders": 3
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
  }
}
```

## Proof Contract

- Contract declared: no (legacy scenario)
- Proof status: SUPPORTED
- Execution result: PASS
- Production authoritative: **no** — simulation output is candidate evidence until governed promotion.
- Machine artifacts: `scenario-proof.json`, `learning.json`
