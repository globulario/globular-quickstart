# release-failure-audit

**Suite**: recovery  
**Result**: PASS  
**Time**: 2026-04-19T04:57:04.717211Z  
**Checks**: 4 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_reachable | cluster.health | ✓ |
| assertions | release_records_exist | release.audit | ✓ |
| assertions | release_failure_state_known | release.audit | ✓ |
| assertions | no_phantom_successes | release.audit | ✓ |
