# controller-zombie-after-lease-loss

**Suite**: authority  
**Result**: INFRA_ERROR  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-19T05:37:01.746273Z  
**Checks**: 0 passed, 6 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✗ |
| preconditions | leadership_is_established | controller.leadership | ✗ |
| preconditions | etcd_accepts_writes | etcd.write_test | ✗ |
| preconditions | liveness_settled_before | state.liveness_freshness | ✗ |
| cleanup | ensure_no_controller_left_frozen | chaos.resume_all_controllers | ✗ |
| postconditions | cluster_returned_to_baseline | health.fingerprint | ✗ |

## Pattern Validation

**Pattern result**: SKIPPED  
See [PATTERNS.md](PATTERNS.md) for full pattern evidence.
