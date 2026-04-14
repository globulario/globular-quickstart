#!/bin/bash
set -euo pipefail

# assign-profiles.sh — Docker-specific: assigns node profiles by updating
# the controller state in etcd after nodes have registered.
#
# In production, profiles are set during node admission (Day-0 bootstrap).
# In the quickstart, nodes join automatically and need profile assignment
# so the DNS reconciler can generate A records.

NODE_IP="${GLOBULAR_NODE_IP:-}"
PKI=/var/lib/globular/pki
ETCDCTL=/usr/lib/globular/bin/etcdctl

ENDPOINTS=$(cat /var/lib/globular/config/etcd_endpoints | tr '\n' ',' | sed 's/,$//')
ETCD="$ETCDCTL --endpoints=$ENDPOINTS --cacert=$PKI/ca.crt --cert=$PKI/issued/services/service.crt --key=$PKI/issued/services/service.key"

echo "[profiles] Waiting for controller state with ≥3 nodes..."
for i in $(seq 1 120); do
    STATE=$($ETCD get /globular/clustercontroller/state --print-value-only 2>/dev/null || echo "")
    if [ -n "$STATE" ]; then
        NODE_COUNT=$(echo "$STATE" | jq '.nodes | length' 2>/dev/null || echo "0")
        if [ "$NODE_COUNT" -ge 3 ]; then
            echo "[profiles] Controller has $NODE_COUNT nodes."
            break
        fi
    fi
    sleep 2
done

STATE=$($ETCD get /globular/clustercontroller/state --print-value-only 2>/dev/null || echo "")
if [ -z "$STATE" ]; then
    echo "[profiles] WARNING: no controller state found"
    exit 0
fi

echo "[profiles] Current nodes:"
echo "$STATE" | jq -r '.nodes | to_entries[] | "  \(.value.identity.hostname // "?") (\(.key)): profiles=\(.value.profiles // [] | join(","))"'

# Assign profiles based on hostname
UPDATED=$(echo "$STATE" | jq '
  # Profile mapping
  {
    "node-1": ["control-plane","core","gateway"],
    "node-2": ["control-plane","core","storage"],
    "node-3": ["control-plane","core","ai"],
    "node-4": ["compute"],
    "node-5": ["compute"]
  } as $map |

  # Update each node
  .nodes |= (to_entries | map(
    (.value.identity.hostname // "") as $h |
    if $map[$h] then
      .value.profiles = $map[$h] |
      .value.advertise_fqdn = ($h + ".globular.internal")
    else . end
  ) | from_entries) |

  # Bump networking generation to trigger DNS reconciliation
  .networking_generation = ((.networking_generation // 0) + 1) |

  # Ensure cluster network spec exists
  .cluster_network_spec = (.cluster_network_spec // {}) |
  .cluster_network_spec.cluster_domain = "globular.internal" |

  # Set MinIO pool nodes (storage profile nodes)
  .minio_pool_nodes = [.nodes | to_entries[] |
    select(.value.profiles | index("storage")) |
    .value.advertise_fqdn] |

  # Set VIP (gateway node IP for service aliases)
  .cluster_network_spec.vip_address = (
    [.nodes[] | select(.profiles | index("gateway")) | .identity.ips[0]] | first // ""
  )
')

# Check if anything changed
OLD_PROFILES=$(echo "$STATE" | jq '[.nodes[].profiles // []] | flatten | sort | join(",")' 2>/dev/null)
NEW_PROFILES=$(echo "$UPDATED" | jq '[.nodes[].profiles // []] | flatten | sort | join(",")' 2>/dev/null)

if [ "$OLD_PROFILES" = "$NEW_PROFILES" ]; then
    echo "[profiles] All profiles already assigned."
else
    $ETCD put /globular/clustercontroller/state "$UPDATED" >/dev/null
    echo "[profiles] Profiles assigned and networking generation bumped."
    echo "$UPDATED" | jq -r '.nodes | to_entries[] | "  \(.value.identity.hostname // "?"): \(.value.profiles | join(","))"'
fi

echo "[profiles] Done."
