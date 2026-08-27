# residue-negative-control

**Suite**: patterns  
**Result**: PARTIAL  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-05T18:07:02.739405Z  
**Checks**: 3 passed, 1 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | node5_running_before | node.container_running | ✓ |
| steps | stop_node5_and_abandon_it | chaos.stop_node | ✓ |
| assertions | node5_is_stopped | node.container_running | ✓ |
| restoration | enforce_restoration | restoration | ✗ |

## Pattern Validation

**Pattern result**: SKIPPED  
See [PATTERNS.md](PATTERNS.md) for full pattern evidence.
