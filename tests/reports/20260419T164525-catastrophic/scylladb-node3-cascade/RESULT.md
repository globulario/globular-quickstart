# scylladb-node3-cascade

**Suite**: catastrophic  
**Result**: FAIL  
**Time**: 2026-04-19T16:51:56.144293Z  
**Checks**: 2 passed, 5 failed

## Checks

| Section | ID | Probe | Result |
|---------|----|----|--------|
| preconditions | cluster_healthy_before | cluster.health | ✗ |
| preconditions | all_etcd_members_healthy | cluster.etcd_members | ✗ |
| preconditions | etcd_writable_before | etcd.write_test | ✗ |
| preconditions | scylladb_container_running | node.container_running | ✓ |
| preconditions | node3_running_before | node.container_running | ✗ |
| preconditions | node1_running_before | node.container_running | ✓ |
| preconditions | node2_running_before | node.container_running | ✗ |
