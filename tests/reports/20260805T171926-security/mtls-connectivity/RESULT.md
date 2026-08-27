# mtls-connectivity

**Suite**: security  
**Result**: FAIL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-05T17:34:57.721431Z  
**Checks**: 8 passed, 1 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| baseline | baseline_service_matrix | cluster.service_matrix | ✓ |
| assertions | mtls_authentication | pki.mtls_connect | ✓ |
| assertions | mtls_rbac | pki.mtls_connect | ✓ |
| assertions | mtls_workflow | pki.mtls_connect | ✓ |
| assertions | mtls_event | pki.mtls_connect | ✗ |
| assertions | mtls_repository | pki.mtls_connect | ✓ |
| assertions | mtls_cross_node | pki.mtls_connect | ✓ |
| cleanup | final_cluster_health | cluster.health | ✓ |

## Pattern Validation

**Pattern result**: SKIPPED  
See [PATTERNS.md](PATTERNS.md) for full pattern evidence.

## Baseline Captures

```json
{
  "baseline_service_matrix": {
    "count": 30,
    "services": [
      {
        "name": "ai_executor.AiExecutorService",
        "port": 10010,
        "address": "10.10.0.11:10010",
        "version": "1.2.297"
      },
      {
        "name": "ai_memory.AiMemoryService",
        "port": 10016,
        "address": "10.10.0.11:10016",
        "version": "1.2.297"
      },
      {
        "name": "ai_router.AiRouterService",
        "port": 10013,
        "address": "10.10.0.11:10013",
        "version": "1.2.297"
      },
      {
        "name": "ai_watcher.AiWatcherService",
        "port": 10009,
        "address": "10.10.0.11:10009",
        "version": "1.2.297"
      },
      {
        "name": "authentication.AuthenticationService",
        "port": 10008,
        "address": "10.10.0.11:10008",
        "version": "1.2.297"
      },
      {
        "name": "backup_manager.BackupManagerService",
        "port": 10012,
        "address": "10.10.0.11:10012",
        "version": "1.2.297"
      },
      {
        "name": "blog.BlogService",
        "port": 10009,
        "address": "10.10.0.15:10009",
        "version": "1.2.297"
      },
      {
        "name": "catalog.CatalogService",
        "port": 10019,
        "address": "10.10.0.15",
        "version": "1.2.297"
      },
      {
        "name": "cluster_controller.ClusterControllerService",
        "port": 12000,
        "address": "10.10.0.12",
        "version": "1.2.297"
      },
      {
        "name": "cluster_doctor.ClusterDoctorService",
        "port": 12005,
        "address": "10.10.0.13",
        "version": "1.2.297"
      },
      {
        "name": "conversation.ConversationService",
        "port": 10018,
        "address": "10.10.0.15",
        "version": "1.2.297"
      },
      {
        "name": "dns.DnsService",
        "port": 10006,
        "address": "10.10.0.11:10006",
        "version": "1.2.297"
      },
      {
        "name": "echo.EchoService",
        "port": 10000,
        "address": "10.10.0.15",
        "version": "1.2.297"
      },
      {
        "name": "event.EventService",
        "port": 10050,
        "address": "10.10.0.11:10050",
        "version": "1.2.297"
      },
      {
        "name": "file.FileService",
        "port": 10014,
        "address": "10.10.0.11:10014",
        "version": "1.2.297"
      },
      {
        "name": "ldap.LdapService",
        "port": 10008,
        "address": "10.10.0.15:10008",
        "version": "1.2.297"
      },
      {
        "name": "log.LogService",
        "port": 10100,
        "address": "10.10.0.11:10100",
        "version": "1.2.297"
      },
      {
        "name": "mail.MailService",
        "port": 10004,
        "address": "10.10.0.15:10004",
        "version": "1.2.297"
      },
      {
        "name": "media.MediaService",
        "port": 10029,
        "address": "10.10.0.11:10029",
        "version": "1.2.297"
      },
      {
        "name": "monitoring.MonitoringService",
        "port": 10005,
        "address": "10.10.0.11:10005",
        "version": "1.2.297"
      },
      {
        "name": "node_agent.NodeAgentService",
        "port": 11000,
        "address": "10.10.0.12",
        "version": ""
      },
      {
        "name": "persistence.PersistenceService",
        "port": 10035,
        "address": "10.10.0.11:10035",
        "version": "1.2.297"
      },
      {
        "name": "rbac.RbacService",
        "port": 10002,
        "address": "10.10.0.11:10002",
        "version": "1.2.297"
      },
      {
        "name": "repository.PackageRepository",
        "port": 10003,
        "address": "10.10.0.11:10003",
        "version": "1.2.297"
      },
      {
        "name": "resource.ResourceService",
        "port": 10004,
        "address": "10.10.0.11:10004",
        "version": "1.2.297"
      },
      {
        "name": "search.SearchService",
        "port": 10015,
        "address": "10.10.0.11:10015",
        "version": "1.2.297"
      },
      {
        "name": "storage.StorageService",
        "port": 10021,
        "address": "10.10.0.12",
        "version": "1.2.297"
      },
      {
        "name": "title.TitleService",
        "port": 10016,
        "address": "10.10.0.11:10016",
        "version": "1.2.297"
      },
      {
        "name": "torrent.TorrentService",
        "port": 10017,
        "address": "10.10.0.11:10017",
        "version": "1.2.297"
      },
      {
        "name": "workflow.WorkflowService",
        "port": 10220,
        "address": "10.10.0.11:10220",
        "version": "1.2.297"
      }
    ]
  }
}
```
