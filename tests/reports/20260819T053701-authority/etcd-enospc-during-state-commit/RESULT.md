# etcd-enospc-during-state-commit

**Suite**: authority  
**Result**: INFRA_ERROR  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-19T05:37:03.588351Z  
**Checks**: 1 passed, 5 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✗ |
| preconditions | no_standing_alarms | etcd.backend_growth | ✓ |
| preconditions | writes_work_before | etcd.write_test | ✗ |
| preconditions | liveness_settled_before | state.liveness_freshness | ✗ |
| cleanup | ensure_quota_released | chaos.clear_etcd_volume_fill | ✗ |
| postconditions | cluster_returned_to_baseline | health.fingerprint | ✗ |

## Pattern Validation

**Pattern result**: SKIPPED  
See [PATTERNS.md](PATTERNS.md) for full pattern evidence.
