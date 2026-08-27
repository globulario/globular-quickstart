# crash-during-mutation-is-atomic

**Suite**: authority  
**Result**: INFRA_ERROR  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-19T05:37:02.686068Z  
**Checks**: 1 passed, 3 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✗ |
| preconditions | identity_clean_before | repository.identity_findings | ✓ |
| preconditions | liveness_settled_before | state.liveness_freshness | ✗ |
| postconditions | cluster_returned_to_baseline | health.fingerprint | ✗ |

## Pattern Validation

**Pattern result**: SKIPPED  
See [PATTERNS.md](PATTERNS.md) for full pattern evidence.
