# release-failure-audit

**Suite**: recovery  
**Result**: FAIL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-07-31T17:14:00.867901Z  
**Checks**: 2 passed, 2 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_reachable | cluster.health | ✓ |
| assertions | release_records_exist | release.audit | ✗ |
| assertions | release_failure_state_known | release.audit | ✗ |
| assertions | no_phantom_successes | release.audit | ✓ |

## Pattern Validation

**Pattern result**: SKIPPED  
See [PATTERNS.md](PATTERNS.md) for full pattern evidence.
