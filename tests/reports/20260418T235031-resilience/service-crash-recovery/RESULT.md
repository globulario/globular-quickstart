# service-crash-recovery

**Suite**: resilience  
**Result**: FAIL  
**Time**: 2026-04-18T23:50:59.791375Z  
**Checks**: 2 passed, 1 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | dns_registered_before | service.registered | ✓ |
| preconditions | dns_active_before | service.status | ✗ |
