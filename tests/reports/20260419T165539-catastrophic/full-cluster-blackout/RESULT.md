# full-cluster-blackout

**Suite**: catastrophic  
**Result**: PASS  
**Time**: 2026-04-19T16:57:44.388621Z  
**Checks**: 29 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy_before | cluster.health | ✓ |
| preconditions | all_etcd_members_healthy | cluster.etcd_members | ✓ |
| preconditions | etcd_writable_pre_blackout | etcd.write_test | ✓ |
| preconditions | controller_registered_before | service.registered | ✓ |
| preconditions | workflow_registered_before | service.registered | ✓ |
| baseline | baseline_health | cluster.health | ✓ |
| baseline | baseline_member_count | cluster.etcd_members | ✓ |
| baseline | baseline_service_count | services.count | ✓ |
| baseline | baseline_installed_packages | cluster.installed_packages | ✓ |
| baseline | baseline_write_latency | etcd.write_test | ✓ |
| steps | stop_node1 | chaos.stop_node | ✓ |
| steps | stop_node2 | chaos.stop_node | ✓ |
| steps | stop_node3 | chaos.stop_node | ✓ |
| steps | wait_all_stopped | node.container_running | ✓ |
| assertions | node1_confirmed_stopped | node.container_running | ✓ |
| assertions | node2_confirmed_stopped | node.container_running | ✓ |
| assertions | node3_confirmed_stopped | node.container_running | ✓ |
| assertions | cluster_brain_dead | cluster.health | ✓ |
| assertions | etcd_write_rejected | etcd.write_test | ✓ |
| assertions | node4_isolated_but_running | node.container_running | ✓ |
| assertions | node5_isolated_but_running | node.container_running | ✓ |
| cleanup | start_node1 | chaos.start_node | ✓ |
| cleanup | start_node2 | chaos.start_node | ✓ |
| cleanup | wait_two_members_online | cluster.etcd_members | ✓ |
| cleanup | start_node3 | chaos.start_node | ✓ |
| cleanup | wait_full_quorum | cluster.etcd_members | ✓ |
| cleanup | verify_health_after_blackout | cluster.health | ✓ |
| cleanup | verify_etcd_writable_after_recovery | etcd.write_test | ✓ |
| cleanup | verify_controller_survived | service.registered | ✓ |

## Baseline Captures

```json
{
  "baseline_health": {
    "status": "healthy",
    "members": 3,
    "nodes": 5
  },
  "baseline_member_count": {
    "total": 3,
    "healthy": 3,
    "unhealthy": 0
  },
  "baseline_service_count": {
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
  },
  "baseline_installed_packages": {
    "total": 65,
    "node_count": 5
  },
  "baseline_write_latency": {
    "success": true,
    "latency_ms": 284
  }
}
```
