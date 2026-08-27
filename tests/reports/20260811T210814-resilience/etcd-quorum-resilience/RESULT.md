# etcd-quorum-resilience

**Suite**: resilience  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-11T21:28:31.618893Z  
**Checks**: 12 passed, 0 failed

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
  "baseline_service_count": {
    "count": 31,
    "services": [
      {
        "name": "ai_executor.AiExecutorService",
        "port": 10010,
        "address": "10.10.0.11:10010",
        "version": "1.2.312"
      },
      {
        "name": "ai_memory.AiMemoryService",
        "port": 10013,
        "address": "10.10.0.11:10013",
        "version": "1.2.312"
      },
      {
        "name": "ai_router.AiRouterService",
        "port": 10012,
        "address": "10.10.0.11:10012",
        "version": "1.2.312"
      },
      {
        "name": "ai_watcher.AiWatcherService",
        "port": 10009,
        "address": "10.10.0.11:10009",
        "version": "1.2.312"
      },
      {
        "name": "authentication.AuthenticationService",
        "port": 10004,
        "address": "10.10.0.11:10004",
        "version": "1.2.312"
      },
      {
        "name": "backup_manager.BackupManagerService",
        "port": 10008,
        "address": "10.10.0.11:10008",
        "version": "1.2.312"
      },
      {
        "name": "blog.BlogService",
        "port": 10021,
        "address": "10.10.0.15",
        "version": "1.2.312"
      },
      {
        "name": "catalog.CatalogService",
        "port": 10004,
        "address": "10.10.0.15:10004",
        "version": "1.2.312"
      },
      {
        "name": "cluster_controller.ClusterControllerService",
        "port": 12000,
        "address": "10.10.0.13",
        "version": "1.2.312"
      },
      {
        "name": "cluster_doctor.ClusterDoctorService",
        "port": 12005,
        "address": "10.10.0.13",
        "version": "1.2.312"
      },
      {
        "name": "conversation.ConversationService",
        "port": 10019,
        "address": "10.10.0.15",
        "version": "1.2.312"
      },
      {
        "name": "dns.DnsService",
        "port": 10006,
        "address": "10.10.0.11:10006",
        "version": "1.2.312"
      },
      {
        "name": "echo.EchoService",
        "port": 10000,
        "address": "10.10.0.15",
        "version": "1.2.312"
      },
      {
        "name": "event.EventService",
        "port": 10050,
        "address": "10.10.0.11:10050",
        "version": "1.2.312"
      },
      {
        "name": "file.FileService",
        "port": 10014,
        "address": "10.10.0.11:10014",
        "version": "1.2.312"
      },
      {
        "name": "ldap.LdapService",
        "port": 10008,
        "address": "10.10.0.15:10008",
        "version": "1.2.312"
      },
      {
        "name": "log.LogService",
        "port": 10100,
        "address": "10.10.0.11:10100",
        "version": "1.2.312"
      },
      {
        "name": "mail.MailService",
        "port": 10018,
        "address": "10.10.0.15",
        "version": "1.2.312"
      },
      {
        "name": "media.MediaService",
        "port": 10029,
        "address": "10.10.0.11:10029",
        "version": "1.2.312"
      },
      {
        "name": "monitoring.MonitoringService",
        "port": 10005,
        "address": "10.10.0.11:10005",
        "version": "1.2.312"
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
        "version": "1.2.312"
      },
      {
        "name": "rbac.RbacService",
        "port": 10002,
        "address": "10.10.0.11:10002",
        "version": "1.2.312"
      },
      {
        "name": "repository.PackageRepository",
        "port": 10003,
        "address": "10.10.0.11:10003",
        "version": "1.2.312"
      },
      {
        "name": "resource.ResourceService",
        "port": 10011,
        "address": "10.10.0.11:10011",
        "version": "1.2.312"
      },
      {
        "name": "search.SearchService",
        "port": 10015,
        "address": "10.10.0.11:10015",
        "version": "1.2.312"
      },
      {
        "name": "sql.SqlService",
        "port": 10022,
        "address": "10.10.0.15",
        "version": ""
      },
      {
        "name": "storage.StorageService",
        "port": 10023,
        "address": "10.10.0.12",
        "version": "1.2.312"
      },
      {
        "name": "title.TitleService",
        "port": 10016,
        "address": "10.10.0.11:10016",
        "version": "1.2.312"
      },
      {
        "name": "torrent.TorrentService",
        "port": 10017,
        "address": "10.10.0.11:10017",
        "version": "1.2.312"
      },
      {
        "name": "workflow.WorkflowService",
        "port": 10220,
        "address": "10.10.0.11:10220",
        "version": "1.2.312"
      }
    ]
  }
}
```
