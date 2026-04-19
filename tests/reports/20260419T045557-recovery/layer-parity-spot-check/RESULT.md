# layer-parity-spot-check

**Suite**: recovery  
**Result**: FAIL  
**Time**: 2026-04-19T04:57:02.121461Z  
**Checks**: 13 passed, 1 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_reachable | cluster.health | ✓ |
| assertions | node1_packages_present | node.installed_packages | ✓ |
| assertions | node2_packages_present | node.installed_packages | ✓ |
| assertions | node3_packages_present | node.installed_packages | ✓ |
| assertions | node4_packages_present | node.installed_packages | ✓ |
| assertions | node5_packages_present | node.installed_packages | ✓ |
| assertions | node_agent_active_node1 | service.status | ✓ |
| assertions | node_agent_active_node2 | service.status | ✗ |
| assertions | node_agent_active_node3 | service.status | ✓ |
| assertions | node_agent_active_node4 | service.status | ✓ |
| assertions | node_agent_active_node5 | service.status | ✓ |
| assertions | dns_active_after_resilience | service.status | ✓ |
| assertions | dns_registered_post_chaos | service.registered | ✓ |
| assertions | service_count_stable | cluster.health | ✓ |
