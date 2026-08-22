#!/usr/bin/env bash
# provision-distributed-objectstore.sh — put the simulation's MinIO into the
# distributed topology a 5-node cluster is supposed to have.
#
# WHY THIS EXISTS
#
# A fresh bring-up leaves MinIO standalone on the founding node. cluster-doctor
# reports that correctly:
#
#   objectstore.standalone_in_cluster — MinIO is running in standalone mode
#   with 5 nodes — data is stored on only one node. Requests routed to other
#   nodes will see empty buckets.
#
# Distributed mode needs BOTH:
#   - >= 3 pool nodes ("MinIO pool has N nodes, need >= 3 for distributed
#     erasure coding"), which is why docker-compose gives node-3 the storage
#     profile alongside node-1 and node-2; and
#   - >= 4 drives total for EC:2+2, which is why each storage node mounts two
#     dedicated volumes at /var/lib/minio/d1 and d2.
#
# Growing standalone -> distributed rewrites .minio.sys, so it is deliberately
# NOT automatic: intent:objectstore.destructive_changes_require_approval
# reserves it for an operator with a matching generation. This script IS that
# operator step, made repeatable — `docker compose down -v` destroys the drive
# volumes, so every reset lands back in standalone and needs this run again.
#
# Safe to re-run: it exits early when the topology is already converged.
set -uo pipefail

CTRL="${CTRL:-10.10.0.11:12000}"
EXEC_NODE="${EXEC_NODE:-globular-node-1}"
# Storage nodes and their routable IPs, matching docker-compose.
STORAGE_NODES="${STORAGE_NODES:-10.10.0.11 10.10.0.12 10.10.0.13}"
DRIVES="${DRIVES:-d1 d2}"

g() { docker exec "$EXEC_NODE" sh -c "globular $* --controller $CTRL --insecure" 2>/dev/null | grep -vE '^2026.*INFO'; }

if g objectstore topology status --timeout 60s | grep -q "Mode: *distributed"; then
  echo "objectstore: already distributed — nothing to do"
  g objectstore topology status --timeout 60s | tail -6
  exit 0
fi

echo "=== waiting for disk candidates to register ==="
# node-agent publishes disk candidates on a 5-minute sync ticker, so a scan run
# straight after the cluster reports ready finds nothing. Wait for the drives
# rather than racing the ticker.
want=$(( $(echo "$STORAGE_NODES" | wc -w) * $(echo "$DRIVES" | wc -w) ))
for _ in $(seq 1 40); do
  have=$(g objectstore disk scan --timeout 120s | grep -c '/var/lib/minio/d')
  [ "$have" -ge "$want" ] && break
  sleep 30
done
echo "  ${have:-0}/${want} drives visible"
if [ "${have:-0}" -lt "$want" ]; then
  echo "ABORT: not all drives registered; refusing to build a partial pool"
  exit 1
fi

echo "=== admitting drives ==="
for ip in $STORAGE_NODES; do
  nid=$(docker exec "$EXEC_NODE" sh -c "globular cluster nodes list --controller $CTRL --insecure --timeout 30s" 2>/dev/null \
        | grep -B4 "\"$ip\"" | grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | head -1)
  if [ -z "$nid" ]; then
    nid=$(g objectstore disk scan --timeout 120s | awk '/\/var\/lib\/minio\/d1/{print $1}' | head -1)
  fi
  for d in $DRIVES; do
    g objectstore disk approve --node "$nid" --node-ip "$ip" --path "/var/lib/minio/$d" \
      --drives "$(echo "$DRIVES" | wc -w)" --timeout 60s >/dev/null
  done
  echo "  admitted $ip ($(echo "$DRIVES" | wc -w) drives)"
done

echo "=== planning ==="
plan=$(g objectstore topology plan --timeout 120s)
echo "$plan" | sed -n '1,12p'
pid=$(echo "$plan" | awk '/Proposal ID:/{print $3}')
[ -z "$pid" ] && { echo "ABORT: no proposal id"; exit 1; }

echo "=== applying proposal $pid (DESTRUCTIVE: rewrites .minio.sys) ==="
g objectstore topology apply --proposal "$pid" --i-understand-data-reset --timeout 300s

echo "=== waiting for convergence ==="
for _ in $(seq 1 40); do
  if g objectstore topology status --timeout 90s | grep -q "✓ CONVERGED"; then
    echo "objectstore: CONVERGED"
    g objectstore topology status --timeout 90s | tail -8
    exit 0
  fi
  sleep 30
done
echo "ABORT: topology did not converge"
g objectstore topology status --timeout 90s | tail -12
exit 1
