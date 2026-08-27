# parity-runtime

**Suite**: functional  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-07-31T16:30:20.009947Z  
**Checks**: 15 passed, 0 failed

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

## Pattern Validation

**Pattern result**: SKIPPED  
See [PATTERNS.md](PATTERNS.md) for full pattern evidence.

## Baseline Captures

```json
{
  "baseline_service_matrix": {
    "count": 20,
    "services": [
      {
        "name": "ai_executor.AiExecutorService",
        "port": 10009,
        "address": "10.10.0.13:10009",
        "version": "1.2.288"
      },
      {
        "name": "ai_memory.AiMemoryService",
        "port": 10011,
        "address": "10.10.0.13:10011",
        "version": "1.2.288"
      },
      {
        "name": "ai_router.AiRouterService",
        "port": 10008,
        "address": "10.10.0.13",
        "version": "1.2.288"
      },
      {
        "name": "ai_watcher.AiWatcherService",
        "port": 10003,
        "address": "10.10.0.13:10003",
        "version": "1.2.288"
      },
      {
        "name": "authentication.AuthenticationService",
        "port": 10010,
        "address": "10.10.0.12:10010",
        "version": "1.2.288"
      },
      {
        "name": "backup_manager.BackupManagerService",
        "port": 10003,
        "address": "10.10.0.12:10003",
        "version": "1.2.288"
      },
      {
        "name": "cluster_controller.ClusterControllerService",
        "port": 12000,
        "address": "10.10.0.13",
        "version": "1.2.288"
      },
      {
        "name": "cluster_doctor.ClusterDoctorService",
        "port": 12005,
        "address": "10.10.0.12",
        "version": "1.2.288"
      },
      {
        "name": "discovery.PackageDiscovery",
        "port": 10001,
        "address": "10.10.0.12:10001",
        "version": "0.0.1"
      },
      {
        "name": "dns.DnsService",
        "port": 10006,
        "address": "10.10.0.14",
        "version": "1.2.288"
      },
      {
        "name": "dns.DnsService",
        "port": 10006,
        "address": "10.10.0.15",
        "version": "1.2.288"
      },
      {
        "name": "event.EventService",
        "port": 10000,
        "address": "10.10.0.12",
        "version": "1.2.288"
      },
      {
        "name": "ldap.LdapService",
        "port": 10004,
        "address": "10.10.0.12:10004",
        "version": "0.0.1"
      },
      {
        "name": "log.LogService",
        "port": 10002,
        "address": "10.10.0.12",
        "version": "1.2.288"
      },
      {
        "name": "monitoring.MonitoringService",
        "port": 10004,
        "address": "10.10.0.12:10004",
        "version": "1.2.288"
      },
      {
        "name": "node_agent.NodeAgentService",
        "port": 11000,
        "address": "10.10.0.14",
        "version": ""
      },
      {
        "name": "rbac.RbacService",
        "port": 10005,
        "address": "10.10.0.12:10005",
        "version": "1.2.288"
      },
      {
        "name": "repository.PackageRepository",
        "port": 10008,
        "address": "10.10.0.12:10008",
        "version": "1.2.288"
      },
      {
        "name": "resource.ResourceService",
        "port": 10001,
        "address": "10.10.0.15",
        "version": "1.2.288"
      },
      {
        "name": "workflow.WorkflowService",
        "port": 10220,
        "address": "10.10.0.12",
        "version": "1.2.288"
      }
    ]
  },
  "final_service_count": {
    "count": 20,
    "services": [
      {
        "name": "ai_executor.AiExecutorService",
        "port": 10009,
        "address": "10.10.0.13:10009",
        "version": "1.2.288"
      },
      {
        "name": "ai_memory.AiMemoryService",
        "port": 10011,
        "address": "10.10.0.13:10011",
        "version": "1.2.288"
      },
      {
        "name": "ai_router.AiRouterService",
        "port": 10008,
        "address": "10.10.0.13",
        "version": "1.2.288"
      },
      {
        "name": "ai_watcher.AiWatcherService",
        "port": 10003,
        "address": "10.10.0.13:10003",
        "version": "1.2.288"
      },
      {
        "name": "authentication.AuthenticationService",
        "port": 10010,
        "address": "10.10.0.12:10010",
        "version": "1.2.288"
      },
      {
        "name": "backup_manager.BackupManagerService",
        "port": 10003,
        "address": "10.10.0.12:10003",
        "version": "1.2.288"
      },
      {
        "name": "cluster_controller.ClusterControllerService",
        "port": 12000,
        "address": "10.10.0.13",
        "version": "1.2.288"
      },
      {
        "name": "cluster_doctor.ClusterDoctorService",
        "port": 12005,
        "address": "10.10.0.12",
        "version": "1.2.288"
      },
      {
        "name": "discovery.PackageDiscovery",
        "port": 10001,
        "address": "10.10.0.12:10001",
        "version": "0.0.1"
      },
      {
        "name": "dns.DnsService",
        "port": 10006,
        "address": "10.10.0.14",
        "version": "1.2.288"
      },
      {
        "name": "dns.DnsService",
        "port": 10006,
        "address": "10.10.0.15",
        "version": "1.2.288"
      },
      {
        "name": "event.EventService",
        "port": 10000,
        "address": "10.10.0.12",
        "version": "1.2.288"
      },
      {
        "name": "ldap.LdapService",
        "port": 10004,
        "address": "10.10.0.12:10004",
        "version": "0.0.1"
      },
      {
        "name": "log.LogService",
        "port": 10002,
        "address": "10.10.0.12",
        "version": "1.2.288"
      },
      {
        "name": "monitoring.MonitoringService",
        "port": 10004,
        "address": "10.10.0.12:10004",
        "version": "1.2.288"
      },
      {
        "name": "node_agent.NodeAgentService",
        "port": 11000,
        "address": "10.10.0.14",
        "version": ""
      },
      {
        "name": "rbac.RbacService",
        "port": 10005,
        "address": "10.10.0.12:10005",
        "version": "1.2.288"
      },
      {
        "name": "repository.PackageRepository",
        "port": 10008,
        "address": "10.10.0.12:10008",
        "version": "1.2.288"
      },
      {
        "name": "resource.ResourceService",
        "port": 10001,
        "address": "10.10.0.15",
        "version": "1.2.288"
      },
      {
        "name": "workflow.WorkflowService",
        "port": 10220,
        "address": "10.10.0.12",
        "version": "1.2.288"
      }
    ]
  }
}
```
