# parity-runtime

**Suite**: functional  
**Result**: PASS  
**Time**: 2026-04-19T04:30:58.140243Z  
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

## Baseline Captures

```json
{
  "baseline_service_matrix": {
    "count": 19,
    "services": [
      {
        "name": "ai_executor.AiExecutorService",
        "port": 10009,
        "address": "10.10.0.13:10009",
        "version": "0.0.7"
      },
      {
        "name": "ai_memory.AiMemoryService",
        "port": 10010,
        "address": "10.10.0.13:10010",
        "version": "0.0.7"
      },
      {
        "name": "ai_router.AiRouterService",
        "port": 10003,
        "address": "10.10.0.13:10003",
        "version": "0.0.7"
      },
      {
        "name": "ai_watcher.AiWatcherService",
        "port": 10008,
        "address": "10.10.0.13:10008",
        "version": "0.0.7"
      },
      {
        "name": "authentication.AuthenticationService",
        "port": 10005,
        "address": "10.10.0.11:10005",
        "version": "0.0.7"
      },
      {
        "name": "backup_manager.BackupManagerService",
        "port": 10008,
        "address": "10.10.0.12:10008",
        "version": "0.0.7"
      },
      {
        "name": "cluster_controller.ClusterControllerService",
        "port": 12000,
        "address": "10.10.0.12",
        "version": "0.0.1"
      },
      {
        "name": "cluster_doctor.ClusterDoctorService",
        "port": 12100,
        "address": "10.10.0.12",
        "version": "0.1.0"
      },
      {
        "name": "discovery.PackageDiscovery",
        "port": 10001,
        "address": "10.10.0.11:10001",
        "version": "0.0.7"
      },
      {
        "name": "dns.DnsService",
        "port": 10006,
        "address": "10.10.0.11:10006",
        "version": "0.0.7"
      },
      {
        "name": "dns.DnsService",
        "port": 10006,
        "address": "10.10.0.11:10006",
        "version": "0.0.7"
      },
      {
        "name": "event.EventService",
        "port": 10000,
        "address": "10.10.0.11:10000",
        "version": "0.0.7"
      },
      {
        "name": "log.LogService",
        "port": 10002,
        "address": "10.10.0.11:10002",
        "version": "0.0.7"
      },
      {
        "name": "monitoring.MonitoringService",
        "port": 10005,
        "address": "10.10.0.12:10005",
        "version": "0.0.1"
      },
      {
        "name": "node_agent.NodeAgentService",
        "port": 11000,
        "address": "10.10.0.14",
        "version": "0.0.1"
      },
      {
        "name": "rbac.RbacService",
        "port": 10004,
        "address": "10.10.0.11:10004",
        "version": "0.0.7"
      },
      {
        "name": "repository.PackageRepository",
        "port": 10009,
        "address": "10.10.0.12:10009",
        "version": "0.0.1"
      },
      {
        "name": "resource.ResourceService",
        "port": 10005,
        "address": "10.10.0.11:10005",
        "version": "0.0.7"
      },
      {
        "name": "workflow.WorkflowService",
        "port": 10220,
        "address": "10.10.0.11:10220",
        "version": "0.0.7"
      }
    ]
  },
  "final_service_count": {
    "count": 19,
    "services": [
      {
        "name": "ai_executor.AiExecutorService",
        "port": 10009,
        "address": "10.10.0.13:10009",
        "version": "0.0.7"
      },
      {
        "name": "ai_memory.AiMemoryService",
        "port": 10010,
        "address": "10.10.0.13:10010",
        "version": "0.0.7"
      },
      {
        "name": "ai_router.AiRouterService",
        "port": 10003,
        "address": "10.10.0.13:10003",
        "version": "0.0.7"
      },
      {
        "name": "ai_watcher.AiWatcherService",
        "port": 10008,
        "address": "10.10.0.13:10008",
        "version": "0.0.7"
      },
      {
        "name": "authentication.AuthenticationService",
        "port": 10005,
        "address": "10.10.0.11:10005",
        "version": "0.0.7"
      },
      {
        "name": "backup_manager.BackupManagerService",
        "port": 10008,
        "address": "10.10.0.12:10008",
        "version": "0.0.7"
      },
      {
        "name": "cluster_controller.ClusterControllerService",
        "port": 12000,
        "address": "10.10.0.12",
        "version": "0.0.1"
      },
      {
        "name": "cluster_doctor.ClusterDoctorService",
        "port": 12100,
        "address": "10.10.0.12",
        "version": "0.1.0"
      },
      {
        "name": "discovery.PackageDiscovery",
        "port": 10001,
        "address": "10.10.0.11:10001",
        "version": "0.0.7"
      },
      {
        "name": "dns.DnsService",
        "port": 10006,
        "address": "10.10.0.11:10006",
        "version": "0.0.7"
      },
      {
        "name": "dns.DnsService",
        "port": 10006,
        "address": "10.10.0.11:10006",
        "version": "0.0.7"
      },
      {
        "name": "event.EventService",
        "port": 10000,
        "address": "10.10.0.11:10000",
        "version": "0.0.7"
      },
      {
        "name": "log.LogService",
        "port": 10002,
        "address": "10.10.0.11:10002",
        "version": "0.0.7"
      },
      {
        "name": "monitoring.MonitoringService",
        "port": 10005,
        "address": "10.10.0.12:10005",
        "version": "0.0.1"
      },
      {
        "name": "node_agent.NodeAgentService",
        "port": 11000,
        "address": "10.10.0.14",
        "version": "0.0.1"
      },
      {
        "name": "rbac.RbacService",
        "port": 10004,
        "address": "10.10.0.11:10004",
        "version": "0.0.7"
      },
      {
        "name": "repository.PackageRepository",
        "port": 10009,
        "address": "10.10.0.12:10009",
        "version": "0.0.1"
      },
      {
        "name": "resource.ResourceService",
        "port": 10005,
        "address": "10.10.0.11:10005",
        "version": "0.0.7"
      },
      {
        "name": "workflow.WorkflowService",
        "port": 10220,
        "address": "10.10.0.11:10220",
        "version": "0.0.7"
      }
    ]
  }
}
```
