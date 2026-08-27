# service-crash-recovery

**Suite**: resilience  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-12T03:06:04.634442Z  
**Checks**: 14 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | dns_registered_before | service.registered | ✓ |
| preconditions | dns_active_before | service.status | ✓ |
| baseline | baseline_node_count | cluster.health | ✓ |
| steps | kill_dns_service | chaos.sigkill_service | ✓ |
| steps | wait_dns_restarted | service.status | ✓ |
| steps | wait_dns_reregistered | service.registered | ✓ |
| assertions | dns_unit_active_after | service.status | ✓ |
| assertions | dns_registered_after | service.registered | ✓ |
| assertions | cluster_still_healthy | cluster.health | ✓ |
| cleanup | ensure_dns_started | chaos.restart_service | ✓ |
| cleanup | final_dns_status | service.status | ✓ |
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
  "baseline_node_count": {
    "status": "healthy",
    "members": 5,
    "nodes": 5
  },
  "final_dns_status": {
    "unit_state": "activating",
    "node": "node-3",
    "service": "dns"
  }
}
```
