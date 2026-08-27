# installed-packages-audit

**Suite**: recovery  
**Result**: PASS  
**Awareness**: AWARENESS_SKIPPED  
**Time**: 2026-08-01T01:27:12.393360Z  
**Checks**: 7 passed, 0 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_reachable | cluster.health | ✓ |
| assertions | cluster_installed_total | cluster.installed_packages | ✓ |
| assertions | node1_packages | node.installed_packages | ✓ |
| assertions | node2_packages | node.installed_packages | ✓ |
| assertions | node3_packages | node.installed_packages | ✓ |
| assertions | node4_packages | node.installed_packages | ✓ |
| assertions | node5_packages | node.installed_packages | ✓ |

## Pattern Validation

**Pattern result**: SKIPPED  
See [PATTERNS.md](PATTERNS.md) for full pattern evidence.
