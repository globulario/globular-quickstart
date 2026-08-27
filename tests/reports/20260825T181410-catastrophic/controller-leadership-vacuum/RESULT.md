# controller-leadership-vacuum

**Suite**: catastrophic  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-25T18:14:11.156173Z  
**Checks**: 20 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy_before | cluster.health | ✓ |
| preconditions | controller_registered_before | service.registered | ✓ |
| preconditions | etcd_quorum_before | cluster.etcd_members | ✓ |
| preconditions | etcd_writable_before | etcd.write_test | ✓ |
| baseline | baseline_health | cluster.health | ✓ |
| baseline | baseline_leader | cluster.leader | ✓ |
| baseline | baseline_service_count | services.count | ✓ |
| steps | kill_controller_node1 | chaos.sigkill_service | ✓ |
| steps | kill_controller_node2 | chaos.sigkill_service | ✓ |
| steps | kill_controller_node3 | chaos.sigkill_service | ✓ |
| steps | wait_for_leader_election | service.registered | ✓ |
| assertions | etcd_quorum_intact | cluster.etcd_members | ✓ |
| assertions | etcd_writes_unaffected | etcd.write_test | ✓ |
| assertions | controller_re_registered | service.registered | ✓ |
| assertions | cluster_not_dead | cluster.health | ✓ |
| assertions | workflow_survived_vacuum | service.registered | ✓ |
| cleanup | final_health | cluster.health | ✓ |
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
    "etcd_healthy_endpoints": 5,
    "etcd_member_count": "5",
    "pki": {
      "node-1": "globular:globular/400 readable backups=0",
      "node-2": "globular:globular/600 readable backups=0",
      "node-3": "globular:globular/600 readable backups=0",
      "node-4": "globular:globular/600 readable backups=0",
      "node-5": "globular:globular/600 readable backups=0"
    }
  },
  "baseline_health": {
    "status": "healthy",
    "members": 5,
    "nodes": 5
  },
  "baseline_leader": {
    "leader_endpoint": "10.10.0.11:12000",
    "is_leader": true
  },
  "baseline_service_count": {
    "count": 29,
    "service_ids": [
      "099c1762-5cf3-37aa-a777-63ccec0bd7ed",
      "0fa34ecb-3c60-3d3a-a132-f7adc6764a55",
      "10595db3-3e7b-343e-9f86-94a6e317585f",
      "27fe9af8-2d20-4c1b-80e7-6d8ca8d00919",
      "2bfada01-cac5-3bd2-baa1-e56defbc9ff9",
      "2ed69e66-1c8d-3b83-912c-3b1ccf5dd764",
      "34c0fd47-fa40-3a81-bfdb-25757ad3080f",
      "4f442c3f-54b3-3cbe-9155-654c359d5eb3",
      "5cb3840f-089b-3e7c-98bd-4cfbed1c445f",
      "6416894b-ec10-387a-a734-fec3fc1e914e",
      "7a7ca0e0-6659-4f6b-9bea-28922ed28622",
      "84723d53-3b03-38a8-b876-50809c8491cd",
      "8b384839-8473-3b00-9ccc-7cb36fe97836",
      "93882e68-6037-351e-8ec1-5999aa4b7996",
      "ae220301-9352-393b-be03-90707f486149",
      "c5f8d601-bb57-3220-8a20-2f1f34dac0a5",
      "cluster_controller.ClusterControllerService",
      "cluster_doctor.ClusterDoctorService",
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

## Proof Contract

- Contract declared: no (legacy scenario)
- Proof status: SUPPORTED
- Execution result: PASS
- Production authoritative: **no** — simulation output is candidate evidence until governed promotion.
- Machine artifacts: `scenario-proof.json`, `learning.json`
