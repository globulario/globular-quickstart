# service-crash-autostart

**Suite**: recovery  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-07-31T23:56:48.017770Z  
**Checks**: 18 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | workflow_active_before | service.status | ✓ |
| preconditions | dns_active_before | service.status | ✓ |
| baseline | initial_service_count | services.count | ✓ |
| baseline | initial_cluster_health | cluster.health | ✓ |
| steps | sigkill_workflow | chaos.sigkill_service | ✓ |
| steps | wait_workflow_restarted | service.status | ✓ |
| steps | verify_cluster_healthy_after_workflow_crash | cluster.health | ✓ |
| steps | wait_workflow_reregistered | service.registered | ✓ |
| steps | sigkill_dns | chaos.sigkill_service | ✓ |
| steps | wait_dns_restarted | service.status | ✓ |
| assertions | workflow_active_after | service.status | ✓ |
| assertions | dns_active_after | service.status | ✓ |
| assertions | workflow_registered_after | service.registered | ✓ |
| assertions | dns_registered_after | service.registered | ✓ |
| assertions | cluster_healthy_after | cluster.health | ✓ |
| assertions | write_quorum_after | etcd.write_test | ✓ |
| cleanup | final_health | cluster.health | ✓ |

## Pattern Validation

**Pattern result**: SKIPPED  
See [PATTERNS.md](PATTERNS.md) for full pattern evidence.

## Baseline Captures

```json
{
  "initial_service_count": {
    "count": 29,
    "service_ids": [
      "0fa34ecb-3c60-3d3a-a132-f7adc6764a55",
      "10595db3-3e7b-343e-9f86-94a6e317585f",
      "255b75f8-1ef6-4abd-89f6-60770eed30c3",
      "2bfada01-cac5-3bd2-baa1-e56defbc9ff9",
      "2ed69e66-1c8d-3b83-912c-3b1ccf5dd764",
      "34c0fd47-fa40-3a81-bfdb-25757ad3080f",
      "4f442c3f-54b3-3cbe-9155-654c359d5eb3",
      "5b3597ba-7219-4736-bd6f-224d9a9ad174",
      "5cb3840f-089b-3e7c-98bd-4cfbed1c445f",
      "6416894b-ec10-387a-a734-fec3fc1e914e",
      "84723d53-3b03-38a8-b876-50809c8491cd",
      "8b384839-8473-3b00-9ccc-7cb36fe97836",
      "93882e68-6037-351e-8ec1-5999aa4b7996",
      "ae220301-9352-393b-be03-90707f486149",
      "c5f8d601-bb57-3220-8a20-2f1f34dac0a5",
      "cluster_controller.ClusterControllerService",
      "cluster_doctor.ClusterDoctorService",
      "e6ab9161-9336-3e49-bd82-2c5edc48693c",
      "f0e8ee87-daf1-3070-ae65-f1a9bf010c9d",
      "f6ababbc-e5d7-4efd-aa2e-2b58151f9e1c",
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
  },
  "initial_cluster_health": {
    "status": "healthy",
    "members": 3,
    "nodes": 5
  }
}
```
