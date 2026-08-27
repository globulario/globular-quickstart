# layer-parity-spot-check

**Suite**: recovery  
**Result**: FAIL  
**Awareness**: AWARENESS_PASS  
**Time**: 2026-05-07T16:39:08.374767Z  
**Checks**: 9 passed, 5 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_reachable | cluster.health | ✓ |
| assertions | node1_packages_present | node.installed_packages | ✗ |
| assertions | node2_packages_present | node.installed_packages | ✗ |
| assertions | node3_packages_present | node.installed_packages | ✗ |
| assertions | node4_packages_present | node.installed_packages | ✗ |
| assertions | node5_packages_present | node.installed_packages | ✗ |
| assertions | node_agent_active_node1 | service.status | ✓ |
| assertions | node_agent_active_node2 | service.status | ✓ |
| assertions | node_agent_active_node3 | service.status | ✓ |
| assertions | node_agent_active_node4 | service.status | ✓ |
| assertions | node_agent_active_node5 | service.status | ✓ |
| assertions | dns_active_after_resilience | service.status | ✓ |
| assertions | dns_registered_post_chaos | service.registered | ✓ |
| assertions | service_count_stable | cluster.health | ✓ |

## Awareness

| Artifact | Status |
|----------|--------|
| preflight | PASS |
| debug-session | PASS |
| runtime-snapshot | PASS |
| incident | CREATED |
| proposal | SKIPPED |
**Recommendation**: Architecture-sensitive task with no prior fix record. After resolving, add a fix case to docs/awareness/fix_cases.yaml.

Artifacts: `awareness/`
- [preflight.agent.txt](awareness/preflight.agent.txt)
- [debug-session.agent.txt](awareness/debug-session.agent.txt)
- [runtime-snapshot.json](awareness/runtime-snapshot.json)
- [incident.yaml](awareness/incident.yaml)
