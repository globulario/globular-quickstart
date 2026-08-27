# service-registration-all

**Suite**: functional  
**Result**: FAIL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-07-31T19:14:31.793908Z  
**Checks**: 22 passed, 1 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | all_nodes_heartbeating | cluster.nodes | ✓ |
| baseline | initial_service_count | services.count | ✓ |
| steps | wait_for_full_stack | services.count | ✓ |
| assertions | service_count_adequate | services.count | ✓ |
| assertions | cluster_controller_registered | service.registered | ✓ |
| assertions | cluster_doctor_registered | service.registered | ✓ |
| assertions | workflow_registered | service.registered | ✓ |
| assertions | authentication_registered | service.registered | ✓ |
| assertions | rbac_registered | service.registered | ✓ |
| assertions | resource_registered | service.registered | ✓ |
| assertions | dns_registered | service.registered | ✓ |
| assertions | node_agent_registered | service.registered | ✓ |
| assertions | discovery_registered | service.registered | ✗ |
| assertions | event_registered | service.registered | ✓ |
| assertions | log_registered | service.registered | ✓ |
| assertions | repository_registered | service.registered | ✓ |
| assertions | monitoring_registered | service.registered | ✓ |
| assertions | backup_manager_registered | service.registered | ✓ |
| assertions | ai_memory_registered | service.registered | ✓ |
| assertions | ai_executor_registered | service.registered | ✓ |
| assertions | node_metrics_all_nodes | service.registered | ✓ |
| cleanup | final_health | cluster.health | ✓ |

## Pattern Validation

**Pattern result**: SKIPPED  
See [PATTERNS.md](PATTERNS.md) for full pattern evidence.

## Baseline Captures

```json
{
  "initial_service_count": {
    "count": 28,
    "service_ids": [
      "0fa34ecb-3c60-3d3a-a132-f7adc6764a55",
      "10595db3-3e7b-343e-9f86-94a6e317585f",
      "2bfada01-cac5-3bd2-baa1-e56defbc9ff9",
      "2ed69e66-1c8d-3b83-912c-3b1ccf5dd764",
      "34c0fd47-fa40-3a81-bfdb-25757ad3080f",
      "4f442c3f-54b3-3cbe-9155-654c359d5eb3",
      "5cb3840f-089b-3e7c-98bd-4cfbed1c445f",
      "6416894b-ec10-387a-a734-fec3fc1e914e",
      "84723d53-3b03-38a8-b876-50809c8491cd",
      "87ce3b08-543b-49d2-b162-6538dd97868a",
      "8b384839-8473-3b00-9ccc-7cb36fe97836",
      "93882e68-6037-351e-8ec1-5999aa4b7996",
      "ae220301-9352-393b-be03-90707f486149",
      "c5f8d601-bb57-3220-8a20-2f1f34dac0a5",
      "cluster_controller.ClusterControllerService",
      "cluster_doctor.ClusterDoctorService",
      "e6ab9161-9336-3e49-bd82-2c5edc48693c",
      "f0e8ee87-daf1-3070-ae65-f1a9bf010c9d",
      "f7953d63-0220-45d8-a5d8-6c82b548c059",
      "f7ec54e4-c7fd-32c1-a222-80c2b39ad930",
      "f8b416c0-ea49-3997-8a24-82c26619ca98",
      "f8b714a7-2c0f-39ff-8bf1-f627649c2df6",
      "node-agent-metrics-node-1",
      "node-agent-metrics-node-2",
      "node-agent-metrics-node-3",
      "node-agent-metrics-node-4",
      "node-agent-metrics-node-5",
      "node_agent.NodeAgentService"
    ]
  }
}
```
