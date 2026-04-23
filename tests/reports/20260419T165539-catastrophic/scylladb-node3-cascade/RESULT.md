# scylladb-node3-cascade

**Suite**: catastrophic  
**Result**: PASS  
**Time**: 2026-04-19T17:02:53.440901Z  
**Checks**: 28 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy_before | cluster.health | ✓ |
| preconditions | all_etcd_members_healthy | cluster.etcd_members | ✓ |
| preconditions | etcd_writable_before | etcd.write_test | ✓ |
| preconditions | scylladb_container_running | node.container_running | ✓ |
| preconditions | node3_running_before | node.container_running | ✓ |
| preconditions | node1_running_before | node.container_running | ✓ |
| preconditions | node2_running_before | node.container_running | ✓ |
| baseline | baseline_cluster_health | cluster.health | ✓ |
| baseline | baseline_etcd_members | cluster.etcd_members | ✓ |
| baseline | baseline_services | services.count | ✓ |
| steps | stop_scylladb | chaos.stop_node | ✓ |
| steps | stop_node3 | chaos.stop_node | ✓ |
| steps | wait_for_detection | node.container_running | ✓ |
| steps | verify_etcd_survives_cascade | etcd.write_test | ✓ |
| assertions | scylladb_stopped | node.container_running | ✓ |
| assertions | node3_stopped | node.container_running | ✓ |
| assertions | etcd_quorum_maintained | cluster.etcd_members | ✓ |
| assertions | etcd_isolated_from_scylladb | etcd.write_test | ✓ |
| assertions | controller_survives_cascade | service.registered | ✓ |
| assertions | workflow_survives_cascade | service.registered | ✓ |
| assertions | node1_still_running | node.container_running | ✓ |
| assertions | node2_still_running | node.container_running | ✓ |
| cleanup | start_scylladb | chaos.start_node | ✓ |
| cleanup | wait_scylladb_ready | node.container_running | ✓ |
| cleanup | start_node3 | chaos.start_node | ✓ |
| cleanup | wait_full_quorum_restored | cluster.etcd_members | ✓ |
| cleanup | final_cluster_health | cluster.health | ✓ |
| cleanup | final_etcd_write | etcd.write_test | ✓ |

## Baseline Captures

```json
{
  "baseline_cluster_health": {
    "status": "healthy",
    "members": 3,
    "nodes": 5
  },
  "baseline_etcd_members": {
    "total": 3,
    "healthy": 3,
    "unhealthy": 0
  },
  "baseline_services": {
    "count": 32,
    "service_ids": [
      "1569a22c-d639-36bb-b516-7f716d793cbb",
      "167ecfb1-c19c-3e1b-8498-fe40f94ec5f4",
      "31599ae6-d997-36be-a16d-8811eacca0ae",
      "3c01fd2b-d4b8-3b4a-ace1-b182324b3364",
      "4d0a895c-7913-3242-b768-1d1ef6bd6f32",
      "50496209-a8e3-4f6d-a9bd-cb8473b6166e",
      "5cb1dafd-7695-4b64-b4db-8cc1f1f0ebd1",
      "7f2466d4-4ce6-3cd8-af30-a01b4f265389",
      "8227a122-7f10-330b-b054-ee9a268461da",
      "85975f66-8771-34c8-b1d5-34e03568a91b",
      "878f9698-3f03-3638-ac7e-1156358c8069",
      "98106388-9002-343e-804f-88b8f1adae6a",
      "a63f79a0-ead8-30c6-86f5-d372b20cfcf6",
      "a7bf401e-81d9-3480-bb99-af06400a8bce",
      "a7d8e0f2-b544-32b2-8ab3-bd54a99b6ff9",
      "ae254290-6c38-3ce9-85e3-46cf226c5d46",
      "c744ba26-ed3a-36d4-8945-a90100b2f903",
      "cab35d5c-d761-38a8-b9c2-ccd5b53c66bd",
      "cluster_controller.ClusterControllerService",
      "cluster_doctor.ClusterDoctorService",
      "ded4c357-28ae-39c1-a56f-36dc7f6da3dd",
      "ec890946-8f10-484c-9412-4acfe2986e04",
      "f2e6f270-60fd-3fae-85cf-378490bacf80",
      "f38b79bb-ee7b-3a74-9df7-a99750cd53db",
      "f48a8598-3cb5-3cc4-804d-d3eaabadd221",
      "f65f56d1-9f6d-3f29-801b-7dcb2ba28d2e",
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
