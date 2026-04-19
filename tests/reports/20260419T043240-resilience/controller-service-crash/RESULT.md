# controller-service-crash

**Suite**: resilience  
**Result**: FAIL  
**Time**: 2026-04-19T04:32:51.710392Z  
**Checks**: 2 passed, 1 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✓ |
| preconditions | controller_running_node2 | service.status | ✗ |
| preconditions | write_quorum_before | etcd.write_test | ✓ |
