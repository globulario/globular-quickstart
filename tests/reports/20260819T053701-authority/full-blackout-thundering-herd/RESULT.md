# full-blackout-thundering-herd

**Suite**: authority  
**Result**: INFRA_ERROR  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-19T05:37:04.538004Z  
**Checks**: 0 passed, 5 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✗ |
| preconditions | leadership_established_before | controller.leadership | ✗ |
| preconditions | liveness_settled_before | state.liveness_freshness | ✗ |
| cleanup | ensure_all_nodes_running | chaos.start_all_nodes | ✗ |
| postconditions | cluster_returned_to_baseline | health.fingerprint | ✗ |

## Pattern Validation

**Pattern result**: SKIPPED  
See [PATTERNS.md](PATTERNS.md) for full pattern evidence.
