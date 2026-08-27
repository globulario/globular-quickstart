# service-health-minimal

**Suite**: smoke  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-07-31T15:45:44.007157Z  
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

## Pattern Validation

**Pattern result**: SKIPPED  
See [PATTERNS.md](PATTERNS.md) for full pattern evidence.

## Baseline Captures

```json
{
  "initial_service_count": {
    "count": 25,
    "service_ids": [
      "02a09485-a7a3-3258-9b67-821968d2ab07",
      "167ecfb1-c19c-3e1b-8498-fe40f94ec5f4",
      "4b49c975-09f1-3d2b-a0a1-53030bc62f07",
      "5c751bac-81ec-422d-94c8-fd41ebcfe1bc",
      "7f2466d4-4ce6-3cd8-af30-a01b4f265389",
      "80687845-5e21-4f3c-9c47-5c0f4288f03d",
      "8227a122-7f10-330b-b054-ee9a268461da",
      "878f9698-3f03-3638-ac7e-1156358c8069",
      "91d6a424-7ce1-354d-b955-48a0d40a4060",
      "9250534c-ba43-33b2-869f-cd0a62f1fc45",
      "a7bf401e-81d9-3480-bb99-af06400a8bce",
      "ae254290-6c38-3ce9-85e3-46cf226c5d46",
      "b5bb3370-76d7-358c-97a8-f7c40ce79551",
      "c0ea520d-4398-4c3a-9003-3fc0125be8c0",
      "cluster_controller.ClusterControllerService",
      "cluster_doctor.ClusterDoctorService",
      "d55fce2d-607f-3b58-8c76-05efac2a6cba",
      "f2e6f270-60fd-3fae-85cf-378490bacf80",
      "f48a8598-3cb5-3cc4-804d-d3eaabadd221",
      "node-agent-metrics-node-1",
      "node-agent-metrics-node-2",
      "node-agent-metrics-node-3",
      "node-agent-metrics-node-4",
      "node-agent-metrics-node-5",
      "node_agent.NodeAgentService"
    ]
  },
  "final_service_count": {
    "count": 25,
    "service_ids": [
      "02a09485-a7a3-3258-9b67-821968d2ab07",
      "167ecfb1-c19c-3e1b-8498-fe40f94ec5f4",
      "4b49c975-09f1-3d2b-a0a1-53030bc62f07",
      "5c751bac-81ec-422d-94c8-fd41ebcfe1bc",
      "7f2466d4-4ce6-3cd8-af30-a01b4f265389",
      "80687845-5e21-4f3c-9c47-5c0f4288f03d",
      "8227a122-7f10-330b-b054-ee9a268461da",
      "878f9698-3f03-3638-ac7e-1156358c8069",
      "91d6a424-7ce1-354d-b955-48a0d40a4060",
      "9250534c-ba43-33b2-869f-cd0a62f1fc45",
      "a7bf401e-81d9-3480-bb99-af06400a8bce",
      "ae254290-6c38-3ce9-85e3-46cf226c5d46",
      "b5bb3370-76d7-358c-97a8-f7c40ce79551",
      "c0ea520d-4398-4c3a-9003-3fc0125be8c0",
      "cluster_controller.ClusterControllerService",
      "cluster_doctor.ClusterDoctorService",
      "d55fce2d-607f-3b58-8c76-05efac2a6cba",
      "f2e6f270-60fd-3fae-85cf-378490bacf80",
      "f48a8598-3cb5-3cc4-804d-d3eaabadd221",
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
