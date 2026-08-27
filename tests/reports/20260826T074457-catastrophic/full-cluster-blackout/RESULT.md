# full-cluster-blackout

**Suite**: catastrophic  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-26T07:46:32.000262Z  
**Checks**: 30 passed, 0 failed

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
    "nodes": 6
  },
  "baseline_member_count": {
    "total": 3,
    "healthy": 3,
    "unhealthy": 0
  },
  "baseline_service_count": {
    "count": 36,
    "service_ids": [
      "099c1762-5cf3-37aa-a777-63ccec0bd7ed",
      "0fa34ecb-3c60-3d3a-a132-f7adc6764a55",
      "10595db3-3e7b-343e-9f86-94a6e317585f",
      "1a6e85a6-2f8d-3e4c-9ae1-a757815792c4",
      "254bb608-84f7-4fa4-b5cc-488f5638a054",
      "2bfada01-cac5-3bd2-baa1-e56defbc9ff9",
      "2ed69e66-1c8d-3b83-912c-3b1ccf5dd764",
      "309ba8df-6359-4db8-8baa-84a5871c6929",
      "34c0fd47-fa40-3a81-bfdb-25757ad3080f",
      "4f442c3f-54b3-3cbe-9155-654c359d5eb3",
      "5cb3840f-089b-3e7c-98bd-4cfbed1c445f",
      "6416894b-ec10-387a-a734-fec3fc1e914e",
      "64aa50e4-2783-3323-bc69-8c218e611cb9",
      "7e87e10b-de4c-346c-a10a-9ad73a5572dd",
      "84723d53-3b03-38a8-b876-50809c8491cd",
      "8b384839-8473-3b00-9ccc-7cb36fe97836",
      "8c2becb3-c41d-3d8a-ab4d-49a062406134",
      "93882e68-6037-351e-8ec1-5999aa4b7996",
      "a54c7ffb-19bc-38bc-b4a1-14fbfb71a4c4",
      "ae220301-9352-393b-be03-90707f486149",
      "c5f8d601-bb57-3220-8a20-2f1f34dac0a5",
      "cluster_controller.ClusterControllerService",
      "cluster_doctor.ClusterDoctorService",
      "e6ab9161-9336-3e49-bd82-2c5edc48693c",
      "f0e8ee87-daf1-3070-ae65-f1a9bf010c9d",
      "f5efada9-a1ca-3860-90fa-0692548d89ba",
      "f649d9ec-02fe-3116-bb2e-0e720402b789",
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
  "baseline_installed_packages": {
    "total": 203,
    "node_count": 5
  },
  "baseline_write_latency": {
    "success": true,
    "latency_ms": 267
  }
}
```

## Proof Contract

- Contract declared: no (legacy scenario)
- Proof status: SUPPORTED
- Execution result: PASS
- Production authoritative: **no** — simulation output is candidate evidence until governed promotion.
- Machine artifacts: `scenario-proof.json`, `learning.json`
