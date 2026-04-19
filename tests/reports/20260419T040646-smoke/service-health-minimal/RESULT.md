# service-health-minimal

**Suite**: smoke  
**Result**: PASS  
**Time**: 2026-04-19T04:06:51.461375Z  
**Checks**: 12 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| baseline | initial_service_count | services.count | ✓ |
| steps | wait_for_core_services | services.count | ✓ |
| assertions | services_registered_count | services.count | ✓ |
| assertions | cluster_controller_registered | service.registered | ✓ |
| assertions | node_agent_registered | service.registered | ✓ |
| assertions | workflow_registered | service.registered | ✓ |
| assertions | authentication_registered | service.registered | ✓ |
| assertions | rbac_registered | service.registered | ✓ |
| assertions | etcd_unit_active_node1 | service.status | ✓ |
| assertions | node_agent_unit_active_node1 | service.status | ✓ |
| cleanup | final_service_count | services.count | ✓ |

## Baseline Captures

```json
{
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
  "final_service_count": {
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
  }
}
```
