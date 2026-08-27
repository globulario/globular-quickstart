# scylladb-node3-cascade

**Suite**: catastrophic  
**Result**: PARTIAL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-18T11:02:27.783904Z  
**Checks**: 25 passed, 5 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy_before | cluster.health | ✓ |
| preconditions | all_etcd_members_healthy | cluster.etcd_members | ✓ |
| preconditions | etcd_writable_before | etcd.write_test | ✓ |
| preconditions | scylladb_service_running | service.status | ✓ |
| preconditions | node3_running_before | node.container_running | ✓ |
| preconditions | node1_running_before | node.container_running | ✓ |
| preconditions | node2_running_before | node.container_running | ✓ |
| baseline | baseline_cluster_health | cluster.health | ✓ |
| baseline | baseline_etcd_members | cluster.etcd_members | ✓ |
| baseline | baseline_services | services.count | ✓ |
| steps | stop_scylladb | chaos.kill_service | ✓ |
| steps | stop_node3 | chaos.stop_node | ✓ |
| steps | wait_for_detection | node.container_running | ✓ |
| steps | verify_etcd_survives_cascade | etcd.write_test | ✗ |
| assertions | scylladb_stopped | service.status | ✓ |
| assertions | node3_stopped | node.container_running | ✓ |
| assertions | etcd_quorum_maintained | cluster.etcd_members | ✗ |
| assertions | etcd_isolated_from_scylladb | etcd.write_test | ✗ |
| assertions | controller_survives_cascade | service.registered | ✗ |
| assertions | workflow_survives_cascade | service.registered | ✗ |
| assertions | node1_still_running | node.container_running | ✓ |
| assertions | node2_still_running | node.container_running | ✓ |
| cleanup | start_scylladb | chaos.restart_service | ✓ |
| cleanup | wait_scylladb_ready | service.status | ✓ |
| cleanup | start_node3 | chaos.start_node | ✓ |
| cleanup | wait_full_quorum_restored | cluster.etcd_members | ✓ |
| cleanup | final_cluster_health | cluster.health | ✓ |
| cleanup | final_etcd_write | etcd.write_test | ✓ |
| restoration | enforce_restoration | restoration | ✓ |
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
    "etcd_healthy_endpoints": 3,
    "etcd_member_count": "4",
    "pki": {
      "node-1": "globular:globular/400 readable backups=0",
      "node-2": "globular:globular/600 readable backups=0",
      "node-3": "globular:globular/600 readable backups=0",
      "node-4": "globular:globular/600 readable backups=0",
      "node-5": "globular:globular/600 readable backups=0"
    }
  },
  "baseline_cluster_health": {
    "status": "healthy",
    "members": 4,
    "nodes": 5
  },
  "baseline_etcd_members": {
    "total": 3,
    "healthy": 3,
    "unhealthy": 0
  },
  "baseline_services": {
    "count": 31,
    "service_ids": [
      "099c1762-5cf3-37aa-a777-63ccec0bd7ed",
      "0c48a96d-8b4f-4e9c-bfc4-b685e1197394",
      "0fa34ecb-3c60-3d3a-a132-f7adc6764a55",
      "10595db3-3e7b-343e-9f86-94a6e317585f",
      "2bfada01-cac5-3bd2-baa1-e56defbc9ff9",
      "2ed69e66-1c8d-3b83-912c-3b1ccf5dd764",
      "3336456a-7570-424f-b454-97f6807907b8",
      "34c0fd47-fa40-3a81-bfdb-25757ad3080f",
      "4f442c3f-54b3-3cbe-9155-654c359d5eb3",
      "5cb3840f-089b-3e7c-98bd-4cfbed1c445f",
      "6416894b-ec10-387a-a734-fec3fc1e914e",
      "84723d53-3b03-38a8-b876-50809c8491cd",
      "88af02ba-52c6-4b9c-90ca-a62f68c8f66a",
      "8b384839-8473-3b00-9ccc-7cb36fe97836",
      "93882e68-6037-351e-8ec1-5999aa4b7996",
      "ae220301-9352-393b-be03-90707f486149",
      "c5f8d601-bb57-3220-8a20-2f1f34dac0a5",
      "cluster_controller.ClusterControllerService",
      "cluster_doctor.ClusterDoctorService",
      "d18c3e48-8198-4bc7-8ff6-458bee5cc924",
      "e6ab9161-9336-3e49-bd82-2c5edc48693c",
      "f0e8ee87-daf1-3070-ae65-f1a9bf010c9d",
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
