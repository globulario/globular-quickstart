# rollback-guard-refuses-silent-regression

**Suite**: upgrade  
**Result**: INFRA_ERROR  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-19T05:36:59.690742Z  
**Checks**: 1 passed, 2 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✗ |
| preconditions | releases_are_clean | release.audit | ✓ |
| postconditions | cluster_returned_to_baseline | health.fingerprint | ✗ |

## Pattern Validation

**Pattern result**: SKIPPED  
See [PATTERNS.md](PATTERNS.md) for full pattern evidence.
