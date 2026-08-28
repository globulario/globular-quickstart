# service-registry-stability

**Suite**: soak  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-28T03:42:35.891104Z  
**Checks**: 16 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | registry_reachable | services.count | ✓ |
| preconditions | dns_registered_before | service.registered | ✓ |
| baseline | baseline_service_count | services.count | ✓ |
| steps | t0_count | services.count | ✓ |
| steps | t0_dns | service.registered | ✓ |
| steps | t0_rbac | service.registered | ✓ |
| steps | t120_count | services.count | ✓ |
| steps | t120_dns | service.registered | ✓ |
| steps | t120_rbac | service.registered | ✓ |
| steps | t240_count | services.count | ✓ |
| steps | t240_dns | service.registered | ✓ |
| steps | t240_rbac | service.registered | ✓ |
| assertions | final_count_stable | services.count | ✓ |
| assertions | final_dns_registered | service.registered | ✓ |
| assertions | final_rbac_registered | service.registered | ✓ |
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
  "baseline_service_count": {
    "count": 35,
    "service_ids": [
      "099c1762-5cf3-37aa-a777-63ccec0bd7ed",
      "0fa34ecb-3c60-3d3a-a132-f7adc6764a55",
      "10595db3-3e7b-343e-9f86-94a6e317585f",
      "1a6e85a6-2f8d-3e4c-9ae1-a757815792c4",
      "2bfada01-cac5-3bd2-baa1-e56defbc9ff9",
      "2ed69e66-1c8d-3b83-912c-3b1ccf5dd764",
      "34c0fd47-fa40-3a81-bfdb-25757ad3080f",
      "367bfbe1-72c3-4e73-9547-a7c003193e6f",
      "4f442c3f-54b3-3cbe-9155-654c359d5eb3",
      "5cb3840f-089b-3e7c-98bd-4cfbed1c445f",
      "6416894b-ec10-387a-a734-fec3fc1e914e",
      "64aa50e4-2783-3323-bc69-8c218e611cb9",
      "688741bc-9611-42f4-a92b-ce052d76fc4d",
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
