# package-upgrade-converges-on-all-nodes

**Suite**: upgrade  
**Result**: INFRA_ERROR  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-19T05:36:57.166445Z  
**Checks**: 0 passed, 3 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy | cluster.health | ✗ |
| preconditions | nodes_present | cluster.nodes | ✗ |
| postconditions | cluster_returned_to_baseline | health.fingerprint | ✗ |

## Pattern Validation

**Pattern result**: SKIPPED  
See [PATTERNS.md](PATTERNS.md) for full pattern evidence.
