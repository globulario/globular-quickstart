# release-failure-audit

**Suite**: recovery  
**Result**: FAIL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-01T01:27:28.836792Z  
**Checks**: 3 passed, 1 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_reachable | cluster.health | ✓ |
| assertions | release_records_exist | release.audit | ✓ |
| assertions | release_failure_state_known | release.audit | ✗ |
| assertions | no_phantom_successes | release.audit | ✓ |

## Pattern Validation

**Pattern result**: SKIPPED  
See [PATTERNS.md](PATTERNS.md) for full pattern evidence.
