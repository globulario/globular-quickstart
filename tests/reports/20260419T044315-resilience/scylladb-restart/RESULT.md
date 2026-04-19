# scylladb-restart

**Suite**: resilience  
**Result**: PASS  
**Time**: 2026-04-19T04:45:45.096230Z  
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
    "count": 24,
    "service_ids": [
      "1569a22c-d639-36bb-b516-7f716d793cbb",
      "31599ae6-d997-36be-a16d-8811eacca0ae",
      "3c01fd2b-d4b8-3b4a-ace1-b182324b3364",
      "4d0a895c-7913-3242-b768-1d1ef6bd6f32",
      "50496209-a8e3-4f6d-a9bd-cb8473b6166e",
      "5cb1dafd-7695-4b64-b4db-8cc1f1f0ebd1",
      "85975f66-8771-34c8-b1d5-34e03568a91b",
      "98106388-9002-343e-804f-88b8f1adae6a",
      "a63f79a0-ead8-30c6-86f5-d372b20cfcf6",
      "a7d8e0f2-b544-32b2-8ab3-bd54a99b6ff9",
      "c744ba26-ed3a-36d4-8945-a90100b2f903",
      "cab35d5c-d761-38a8-b9c2-ccd5b53c66bd",
      "cluster_controller.ClusterControllerService",
      "cluster_doctor.ClusterDoctorService",
      "ded4c357-28ae-39c1-a56f-36dc7f6da3dd",
      "ec890946-8f10-484c-9412-4acfe2986e04",
      "f38b79bb-ee7b-3a74-9df7-a99750cd53db",
      "f65f56d1-9f6d-3f29-801b-7dcb2ba28d2e",
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
