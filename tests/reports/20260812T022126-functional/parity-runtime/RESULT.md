# parity-runtime

**Suite**: functional  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-12T02:21:30.984481Z  
**Checks**: 16 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | all_nodes_heartbeating | cluster.health | ✓ |
| baseline | baseline_service_matrix | cluster.service_matrix | ✓ |
| steps | wait_full_convergence | cluster.service_matrix | ✓ |
| assertions | service_count_sufficient | cluster.service_matrix | ✓ |
| assertions | cluster_controller_present | service.registered | ✓ |
| assertions | node_agent_present | service.registered | ✓ |
| assertions | workflow_present | service.registered | ✓ |
| assertions | cluster_doctor_present | service.registered | ✓ |
| assertions | authentication_present | service.registered | ✓ |
| assertions | rbac_present | service.registered | ✓ |
| assertions | repository_present | service.registered | ✓ |
| assertions | dns_present | service.registered | ✓ |
| assertions | all_nodes_still_heartbeating | cluster.health | ✓ |
| cleanup | final_service_count | cluster.service_matrix | ✓ |
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
  "baseline_service_matrix": {
    "count": 31,
    "services": [
      {
        "name": "ai_executor.AiExecutorService",
        "port": 10013,
        "address": "10.10.0.11:10013",
        "version": "1.2.312"
      },
      {
        "name": "ai_memory.AiMemoryService",
        "port": 10016,
        "address": "10.10.0.11:10016",
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
        "port": 10010,
        "address": "10.10.0.11:10010",
        "version": "1.2.312"
      },
      {
        "name": "authentication.AuthenticationService",
        "port": 10002,
        "address": "10.10.0.11:10002",
        "version": "1.2.312"
      },
      {
        "name": "backup_manager.BackupManagerService",
        "port": 10009,
        "address": "10.10.0.11:10009",
        "version": "1.2.312"
      },
      {
        "name": "blog.BlogService",
        "port": 10008,
        "address": "10.10.0.14:10008",
        "version": "1.2.312"
      },
      {
        "name": "catalog.CatalogService",
        "port": 10018,
        "address": "10.10.0.14",
        "version": "1.2.312"
      },
      {
        "name": "cluster_controller.ClusterControllerService",
        "port": 12000,
        "address": "10.10.0.13",
        "version": "1.2.314"
      },
      {
        "name": "cluster_doctor.ClusterDoctorService",
        "port": 12005,
        "address": "10.10.0.13",
        "version": "1.2.312"
      },
      {
        "name": "conversation.ConversationService",
        "port": 10022,
        "address": "10.10.0.14",
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
        "address": "10.10.0.14",
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
        "port": 10019,
        "address": "10.10.0.14",
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
        "port": 10021,
        "address": "10.10.0.14",
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
        "address": "10.10.0.13",
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
        "port": 10004,
        "address": "10.10.0.11:10004",
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
        "port": 10008,
        "address": "10.10.0.11:10008",
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
        "port": 10023,
        "address": "10.10.0.14",
        "version": ""
      },
      {
        "name": "storage.StorageService",
        "port": 10024,
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
  },
  "final_service_count": {
    "count": 31,
    "services": [
      {
        "name": "ai_executor.AiExecutorService",
        "port": 10013,
        "address": "10.10.0.11:10013",
        "version": "1.2.312"
      },
      {
        "name": "ai_memory.AiMemoryService",
        "port": 10016,
        "address": "10.10.0.11:10016",
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
        "port": 10010,
        "address": "10.10.0.11:10010",
        "version": "1.2.312"
      },
      {
        "name": "authentication.AuthenticationService",
        "port": 10002,
        "address": "10.10.0.11:10002",
        "version": "1.2.312"
      },
      {
        "name": "backup_manager.BackupManagerService",
        "port": 10009,
        "address": "10.10.0.11:10009",
        "version": "1.2.312"
      },
      {
        "name": "blog.BlogService",
        "port": 10008,
        "address": "10.10.0.14:10008",
        "version": "1.2.312"
      },
      {
        "name": "catalog.CatalogService",
        "port": 10018,
        "address": "10.10.0.14",
        "version": "1.2.312"
      },
      {
        "name": "cluster_controller.ClusterControllerService",
        "port": 12000,
        "address": "10.10.0.13",
        "version": "1.2.314"
      },
      {
        "name": "cluster_doctor.ClusterDoctorService",
        "port": 12005,
        "address": "10.10.0.13",
        "version": "1.2.312"
      },
      {
        "name": "conversation.ConversationService",
        "port": 10022,
        "address": "10.10.0.14",
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
        "address": "10.10.0.14",
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
        "port": 10019,
        "address": "10.10.0.14",
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
        "port": 10021,
        "address": "10.10.0.14",
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
        "address": "10.10.0.13",
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
        "port": 10004,
        "address": "10.10.0.11:10004",
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
        "port": 10008,
        "address": "10.10.0.11:10008",
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
        "port": 10023,
        "address": "10.10.0.14",
        "version": ""
      },
      {
        "name": "storage.StorageService",
        "port": 10024,
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
