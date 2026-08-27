# etcd-quorum-resilience

**Suite**: resilience  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-07-31T16:59:22.881265Z  
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
        "port": 10007,
        "address": "10.10.0.13:10007",
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
        "address": "10.10.0.13",
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
        "address": "10.10.0.11:10006",
        "version": "1.2.288"
      },
      {
        "name": "dns.DnsService",
        "port": 10007,
        "address": "10.10.0.12:10007",
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
        "address": "10.10.0.15",
        "version": ""
      },
      {
        "name": "rbac.RbacService",
        "port": 10006,
        "address": "10.10.0.12:10006",
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
        "port": 10005,
        "address": "10.10.0.15:10005",
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
