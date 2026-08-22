#!/usr/bin/env bash
set -uo pipefail

# test-concurrent-join.sh — regression test for the Day-1 join race.
#
# WHY THIS IS A SCRIPT AND NOT A YAML SCENARIO
#
# The harness has chaos.stop_node / chaos.start_node, but a restart is NOT a
# join: the state volume persists, bootstrap.sh sees
# .quickstart-bootstrap-complete and exits. Reproducing a real join needs the
# node's volume destroyed so the join script runs again — an action the harness
# has no verb for. Rather than bolt a destructive volume-wipe verb onto the
# scenario language, the test lives here.
#
# THE DEFECT IT GUARDS (observed 2026-07-31, release 1.2.288)
#
# Join phase 5.4 writes /var/lib/globular/config/etcd.yaml from a membership
# snapshot taken BEFORE phase 5.5's `etcdctl member add`. `member add` prints
# the authoritative ETCD_INITIAL_CLUSTER for exactly this purpose; the script
# ignores it. Serialized joins hide the bug — nothing changes membership in
# that window. Concurrent joins land inside it:
#
#   node-3 etcd.yaml: initial-cluster = globular-etcd,node-3        (2 members)
#   actual membership:                  globular-etcd,node-2,node-3 (3 members)
#   → fatal: error validating peerURLs ... member count is unequal
#
# Blast radius is the whole cluster, not one node: etcd allows one learner
# (max-learners=1). node-3's etcd never starts, so it never catches up, so the
# controller can never promote it, so the learner slot stays wedged and EVERY
# later join dies with "too many learner members in cluster".
#
# PASS = both nodes join concurrently and etcd ends with all members started
#        and promoted to voters.
# FAIL = a wedged learner, an unstarted member, or a join that never completes.
#
# Requires: a healthy cluster with node-1..3 already formed.
# Destructive: wipes node-4 and node-5 state.

cd "$(dirname "$0")/.."

ETCDCTL='docker exec globular-node-1 /usr/lib/globular/bin/etcdctl
  --endpoints=https://10.10.0.11:2379
  --cacert=/var/lib/globular/pki/ca.crt
  --cert=/var/lib/globular/pki/issued/services/service.crt
  --key=/var/lib/globular/pki/issued/services/service.key'

log()  { echo "[concurrent-join] $*"; }
fail() { echo "[concurrent-join] FAIL: $*" >&2; exit 1; }

members() { $ETCDCTL member list 2>/dev/null; }

# ── preconditions ────────────────────────────────────────────────────────────
docker exec globular-node-1 test -f /var/lib/globular/.quickstart-bootstrap-complete 2>/dev/null \
    || fail "node-1 has not completed Day-0 — run 'make up' first"

before=$(members | grep -c . || echo 0)
log "membership before: $before"
[ "$before" -ge 2 ] || fail "need at least node-1 + one joined node before testing (have $before)"

# ── wipe node-4 and node-5 so a REAL join runs ───────────────────────────────
log "removing node-4 and node-5 (state wipe → forces a real join) ..."
docker compose rm -sf node-4 node-5 >/dev/null 2>&1 || true
for n in node4 node5; do
    docker volume rm "globular-quickstart_${n}-state" >/dev/null 2>&1 || true
done

# Drop any stale members so the join starts from a clean membership.
for id in $(members | awk -F', ' '/node-4|node-5/ {print $1}'); do
    log "removing stale etcd member $id"
    $ETCDCTL member remove "$id" >/dev/null 2>&1 || true
done

# Deregister from the CONTROLLER too, not just etcd. The controller keeps its own
# node registry and its v2 authorization gate refuses a re-join for a hostname it
# already knows:
#   FAIL: join blocked: controller denied — node identity conflict: hostname already present
# That refusal is correct — it is identity-conflict protection — so the test must
# perform the operator's actual decommission step rather than only clearing etcd.
# Without this the test passes exactly once (on a cluster those nodes never
# joined) and fails on every re-run, which looks like a regression and is not.
# `nodes remove` takes a node_id (UUID), not a hostname, so resolve it first from
# the protobuf-text listing where node_id precedes its identity block. --force is
# required because we have already stopped the container, so the node is
# unreachable and the graceful drain cannot complete.
node_id_of() {
    docker exec globular-node-1 globular cluster nodes list 2>/dev/null \
      | awk -v h="$1" '
          /node_id:/ { id=$2 }
          $0 ~ "hostname: \""h"\"" { gsub(/"/,"",id); print id; exit }'
}

for n in node-4 node-5; do
    nid=$(node_id_of "$n")
    if [ -z "$nid" ]; then
        log "  (controller has no record of $n — fine on a first run)"
        continue
    fi
    log "deregistering $n ($nid) from the controller ..."
    docker exec globular-node-1 globular cluster nodes remove "$nid" --force >/dev/null 2>&1 \
        || log "  WARN: controller removal of $n returned non-zero"
done

# The controller writes the removal asynchronously; joining before it lands
# re-triggers the identity gate.
sleep 10

# ── start BOTH at once — this is the whole point ─────────────────────────────
log "starting node-4 and node-5 CONCURRENTLY ..."
docker compose up -d node-4 node-5 >/dev/null 2>&1

deadline=$(( $(date +%s) + 1200 ))
done4=0; done5=0
while [ "$(date +%s)" -lt "$deadline" ]; do
    docker exec globular-node-4 test -f /var/lib/globular/.quickstart-bootstrap-complete 2>/dev/null && done4=1
    docker exec globular-node-5 test -f /var/lib/globular/.quickstart-bootstrap-complete 2>/dev/null && done5=1
    [ "$done4" = 1 ] && [ "$done5" = 1 ] && break

    for n in 4 5; do
        if [ "$(docker exec "globular-node-$n" systemctl is-active globular-quickstart-bootstrap 2>/dev/null)" = "failed" ]; then
            echo "─── node-$n join journal ───" >&2
            docker exec "globular-node-$n" journalctl -u globular-quickstart-bootstrap \
                --no-pager -n 25 2>&1 | tail -25 >&2
            # Do NOT assert a cause here. Attributing every join failure to the
            # 5.4/5.5 ordering bug is the same misdirection as the controller's
            # "fix the join flow" message that pointed at the wrong subsystem for
            # a founding-node defect. Report what happened; let the journal above
            # say why. The ordering bug specifically shows as
            # "member count is unequal" plus an `unstarted` member.
            fail "node-$n did not complete its join under concurrency — see journal above for the cause"
        fi
    done
    sleep 15
done

[ "$done4" = 1 ] || fail "node-4 never completed its join"
[ "$done5" = 1 ] || fail "node-5 never completed its join"
log "both nodes completed their joins"

# ── etcd must be intact: no unstarted members, no stuck learners ─────────────
ml=$(members)
echo "$ml" | sed 's/^/    /'

if echo "$ml" | grep -q "unstarted"; then
    fail "an etcd member is 'unstarted' — its etcd.yaml likely carries a stale
       initial-cluster (member count unequal). This is the 5.4-before-5.5 race."
fi

# Promotion is ASYNCHRONOUS and controller-driven, so poll — do not sample once.
# The controller promotes caught-up learners one at a time, each raise taking the
# voter count to the next odd number:
#   etcd join: voters=3 ready-learners=1 → promoting 1 to reach an odd voter count
#   etcd join: voters=4 ready-learners=1 → promoting 1 ...
# Observed 00:37:32 (node-5) and 00:38:05 (node-4) — i.e. ~30s apart and both
# AFTER the bootstrap markers appeared. A single check the moment both joins
# complete therefore reports a learner that is merely young, not stuck, and this
# test failed a cluster that was in fact correct. An assertion that encodes a
# timing assumption instead of the property it means to check is a false red,
# and false reds train people to ignore the suite.
log "waiting for learner promotion (controller-driven, polled up to 300s) ..."
prom_deadline=$(( $(date +%s) + 300 ))
while :; do
    ml=$(members)
    learners=$(echo "$ml" | awk -F', ' '$NF ~ /true/ {c++} END{print c+0}')
    [ "$learners" -eq 0 ] && break
    if [ "$(date +%s)" -gt "$prom_deadline" ]; then
        echo "$ml" | sed 's/^/    /'
        fail "$learners member(s) still non-voting learners after 300s — promotion stalled.
       With max-learners=1 this wedges every subsequent join. Check the controller:
       journalctl -u globular-cluster-controller | grep -i promot"
    fi
    sleep 10
done

echo "$ml" | sed 's/^/    /'
total=$(echo "$ml" | grep -c .)
log "PASS — $total members, all started, all voters"
exit 0
