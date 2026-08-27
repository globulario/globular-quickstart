# scylladb-restart

**Suite**: resilience  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-07-31T17:11:17.218575Z  
**Checks**: 23 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | all_etcd_members_healthy | cluster.etcd_members | ✓ |
| preconditions | scylladb_container_running | node.container_running | ✓ |
| preconditions | write_quorum_before | etcd.write_test | ✓ |
| baseline | initial_cluster_health | cluster.health | ✓ |
| baseline | initial_etcd_members | cluster.etcd_members | ✓ |
| baseline | initial_service_count | services.count | ✓ |
| steps | stop_scylladb | chaos.stop_node | ✓ |
| steps | wait_for_scylladb_stopped | node.container_running | ✓ |
| steps | verify_etcd_healthy_without_scylla | cluster.health | ✓ |
| steps | verify_write_quorum_without_scylla | etcd.write_test | ✓ |
| steps | verify_etcd_members_without_scylla | cluster.etcd_members | ✓ |
| steps | verify_controller_without_scylla | service.registered | ✓ |
| steps | verify_workflow_without_scylla | service.registered | ✓ |
| steps | start_scylladb | chaos.start_node | ✓ |
| steps | wait_for_scylladb_healthy | node.container_running | ✓ |
| assertions | cluster_healthy_after | cluster.health | ✓ |
| assertions | etcd_members_healthy_after | cluster.etcd_members | ✓ |
| assertions | write_quorum_after | etcd.write_test | ✓ |
| assertions | scylladb_running_after | node.container_running | ✓ |
| assertions | all_nodes_heartbeating | cluster.nodes | ✓ |
| cleanup | final_health | cluster.health | ✓ |
| cleanup | final_etcd_members | cluster.etcd_members | ✓ |

## Pattern Validation

**Pattern result**: SKIPPED  
See [PATTERNS.md](PATTERNS.md) for full pattern evidence.

## Baseline Captures

```json
{
  "initial_cluster_health": {
    "status": "healthy",
    "members": 3,
    "nodes": 5
  },
  "initial_etcd_members": {
    "total": 3,
    "healthy": 3,
    "unhealthy": 0
  },
  "initial_service_count": {
    "count": 25,
    "service_ids": [
      "10595db3-3e7b-343e-9f86-94a6e317585f",
      "2bfada01-cac5-3bd2-baa1-e56defbc9ff9",
      "34c0fd47-fa40-3a81-bfdb-25757ad3080f",
      "4b49c975-09f1-3d2b-a0a1-53030bc62f07",
      "5cb3840f-089b-3e7c-98bd-4cfbed1c445f",
      "6416894b-ec10-387a-a734-fec3fc1e914e",
      "7ae9ec7e-4bcf-3f22-bc21-c9aebab644e3",
      "80da969b-fdf0-4cfa-bded-6121ce3cd724",
      "84723d53-3b03-38a8-b876-50809c8491cd",
      "8b384839-8473-3b00-9ccc-7cb36fe97836",
      "93882e68-6037-351e-8ec1-5999aa4b7996",
      "9c1248a4-9ba6-497f-adc8-42b4a939fd58",
      "ae220301-9352-393b-be03-90707f486149",
      "c5f8d601-bb57-3220-8a20-2f1f34dac0a5",
      "cluster_controller.ClusterControllerService",
      "cluster_doctor.ClusterDoctorService",
      "ec07ae05-1033-4270-b923-d70520ae11f1",
      "f7ec54e4-c7fd-32c1-a222-80c2b39ad930",
      "f8b714a7-2c0f-39ff-8bf1-f627649c2df6",
      "node-agent-metrics-node-1",
      "node-agent-metrics-node-2",
      "node-agent-metrics-node-3",
      "node-agent-metrics-node-4",
      "node-agent-metrics-node-5",
      "node_agent.NodeAgentService"
    ]
  },
  "final_etcd_members": {
    "total": 3,
    "healthy": 3,
    "unhealthy": 0
  }
}
```
