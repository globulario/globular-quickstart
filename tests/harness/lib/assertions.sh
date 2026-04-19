#!/usr/bin/env bash
# assertions.sh — assertion helpers for the test harness
#
# These are lower-level building blocks used by scenario.sh and direct
# probe scripts. The main assertion evaluation lives in globular-scenario (Python)
# which handles the YAML expect: blocks. These bash helpers are for
# imperative checks in suite scripts or quick one-off validations.

# assert_eq <label> <actual> <expected>
# Exits with 1 if not equal. Returns 0 on pass.
assert_eq() {
    local label="$1" actual="$2" expected="$3"
    if [ "$actual" = "$expected" ]; then
        echo "  PASS: $label (got: $actual)"
        return 0
    else
        echo "  FAIL: $label"
        echo "    expected: $expected"
        echo "    actual:   $actual"
        return 1
    fi
}

# assert_gte <label> <actual> <min>
assert_gte() {
    local label="$1" actual="$2" min="$3"
    if [ "$actual" -ge "$min" ] 2>/dev/null; then
        echo "  PASS: $label ($actual >= $min)"
        return 0
    else
        echo "  FAIL: $label ($actual < $min)"
        return 1
    fi
}

# assert_contains <label> <haystack> <needle>
assert_contains() {
    local label="$1" haystack="$2" needle="$3"
    if echo "$haystack" | grep -q "$needle"; then
        echo "  PASS: $label (contains: $needle)"
        return 0
    else
        echo "  FAIL: $label (missing: $needle in: $haystack)"
        return 1
    fi
}

# assert_json_field <label> <json> <field> <expected_value>
# Extracts a field from JSON and compares.
assert_json_field() {
    local label="$1" json="$2" field="$3" expected="$4"
    local actual
    actual=$(echo "$json" | python3 -c \
        "import sys,json; d=json.loads(sys.stdin.read()); print(d.get('$field','<missing>'))" \
        2>/dev/null || echo "<error>")
    assert_eq "$label" "$actual" "$expected"
}

# assert_probe <probe_func> <expect_field> <expected_value>
# Runs a probe function and asserts a JSON field value.
assert_probe() {
    local probe_func="$1" expect_field="$2" expected_val="$3"
    local result
    result=$("$probe_func" 2>/dev/null)
    assert_json_field "$probe_func.$expect_field" "$result" "$expect_field" "$expected_val"
}

# assert_cluster_healthy
# Quick check: etcd endpoint health returns 0 exit code.
assert_cluster_healthy() {
    if docker exec globular-node-1 \
            /usr/lib/globular/bin/etcdctl \
            --endpoints=https://10.10.0.11:2379 \
            --cacert=/var/lib/globular/pki/ca.crt \
            --cert=/var/lib/globular/pki/issued/services/service.crt \
            --key=/var/lib/globular/pki/issued/services/service.key \
            endpoint health >/dev/null 2>&1; then
        echo "  PASS: cluster_healthy"
        return 0
    else
        echo "  FAIL: cluster_healthy (etcd endpoint health failed)"
        return 1
    fi
}
