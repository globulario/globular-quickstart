# installed-packages-audit

**Suite**: recovery  
**Result**: PASS  
**Time**: 2026-04-19T05:06:23.255538Z  
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
