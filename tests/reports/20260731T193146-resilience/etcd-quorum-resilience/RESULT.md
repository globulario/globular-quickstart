# etcd-quorum-resilience

**Suite**: resilience  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-07-31T19:54:26.322271Z  
**Checks**: 11 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| baseline | baseline_service_count | cluster.service_matrix | ✓ |
| steps | stop_node5 | chaos.stop_node | ✓ |
| steps | check_quorum_intact | cluster.health | ✓ |
| steps | check_services_reachable | cluster.service_matrix | ✓ |
| steps | start_node5 | chaos.start_node | ✓ |
| steps | wait_node5_rejoined | service.status | ✓ |
| assertions | etcd_quorum_maintained | cluster.health | ✓ |
| assertions | node5_agent_active | service.status | ✓ |
| assertions | services_still_registered | cluster.service_matrix | ✓ |
| cleanup | final_cluster_health | cluster.health | ✓ |

## Pattern Validation

**Pattern result**: SKIPPED  
See [PATTERNS.md](PATTERNS.md) for full pattern evidence.

## Baseline Captures

```json
{
  "baseline_service_count": {
    "count": 23,
    "services": [
      {
        "name": "ai_executor.AiExecutorService",
        "port": 10016,
        "address": "10.10.0.11:10016",
        "version": "1.2.288"
      },
      {
        "name": "ai_memory.AiMemoryService",
        "port": 10013,
        "address": "10.10.0.11:10013",
        "version": "1.2.288"
      },
      {
        "name": "ai_router.AiRouterService",
        "port": 10012,
        "address": "10.10.0.11:10012",
        "version": "1.2.288"
      },
      {
        "name": "ai_watcher.AiWatcherService",
        "port": 10010,
        "address": "10.10.0.11:10010",
        "version": "1.2.288"
      },
      {
        "name": "authentication.AuthenticationService",
        "port": 10002,
        "address": "10.10.0.11:10002",
        "version": "1.2.288"
      },
      {
        "name": "backup_manager.BackupManagerService",
        "port": 10009,
        "address": "10.10.0.11:10009",
        "version": "1.2.288"
      },
      {
        "name": "cluster_controller.ClusterControllerService",
        "port": 12000,
        "address": "10.10.0.15",
        "version": "1.2.288"
      },
      {
        "name": "cluster_doctor.ClusterDoctorService",
        "port": 12005,
        "address": "10.10.0.15",
        "version": "1.2.288"
      },
      {
        "name": "dns.DnsService",
        "port": 10006,
        "address": "10.10.0.11:10006",
        "version": "1.2.288"
      },
      {
        "name": "event.EventService",
        "port": 10050,
        "address": "10.10.0.11:10050",
        "version": "1.2.288"
      },
      {
        "name": "file.FileService",
        "port": 10014,
        "address": "10.10.0.11:10014",
        "version": "1.2.288"
      },
      {
        "name": "log.LogService",
        "port": 10100,
        "address": "10.10.0.11:10100",
        "version": "1.2.288"
      },
      {
        "name": "media.MediaService",
        "port": 10029,
        "address": "10.10.0.11:10029",
        "version": "1.2.288"
      },
      {
        "name": "monitoring.MonitoringService",
        "port": 10005,
        "address": "10.10.0.11:10005",
        "version": "1.2.288"
      },
      {
        "name": "node_agent.NodeAgentService",
        "port": 11000,
        "address": "10.10.0.15",
        "version": ""
      },
      {
        "name": "persistence.PersistenceService",
        "port": 10035,
        "address": "10.10.0.11:10035",
        "version": "1.2.288"
      },
      {
        "name": "rbac.RbacService",
        "port": 10004,
        "address": "10.10.0.11:10004",
        "version": "1.2.288"
      },
      {
        "name": "repository.PackageRepository",
        "port": 10003,
        "address": "10.10.0.11:10003",
        "version": "1.2.288"
      },
      {
        "name": "resource.ResourceService",
        "port": 10008,
        "address": "10.10.0.11:10008",
        "version": "1.2.288"
      },
      {
        "name": "search.SearchService",
        "port": 10015,
        "address": "10.10.0.11:10015",
        "version": "1.2.288"
      },
      {
        "name": "title.TitleService",
        "port": 10016,
        "address": "10.10.0.11:10016",
        "version": "1.2.288"
      },
      {
        "name": "torrent.TorrentService",
        "port": 10017,
        "address": "10.10.0.11:10017",
        "version": "1.2.288"
      },
      {
        "name": "workflow.WorkflowService",
        "port": 10220,
        "address": "10.10.0.11:10220",
        "version": "1.2.288"
      }
    ]
  }
}
```
