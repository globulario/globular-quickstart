#!/usr/bin/env python3
import importlib.util
import tempfile
import unittest
from pathlib import Path

MODULE = Path(__file__).parents[1] / "lib" / "scenario_contract.py"
spec = importlib.util.spec_from_file_location("scenario_contract", MODULE)
sc = importlib.util.module_from_spec(spec)
assert spec.loader
spec.loader.exec_module(sc)


class ScenarioContractTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.probes = self.root / "probes.sh"
        self.probes.write_text(
            "probe_cluster_health() { :; }\n"
            "probe_node_partition_fenced() { :; }\n"
        )

    def tearDown(self):
        self.tmp.cleanup()

    def scenario(self, text):
        path = self.root / "scenario.yaml"
        path.write_text(text)
        return path

    def test_unknown_required_action_is_unsupported(self):
        path = self.scenario(
            """version: 1
name: x
suite: resilience
steps:
  - id: zombie
    action: chaos.pause_service
"""
        )
        proof = sc.validate_scenario(path, self.probes)
        self.assertEqual("UNSUPPORTED", proof["status"])
        self.assertFalse(proof["proof_eligible"])
        self.assertEqual(
            "chaos.pause_service",
            proof["capabilities"]["unsupported_required"][0]["action"],
        )

    def test_optional_unknown_action_is_visible_but_supported(self):
        path = self.scenario(
            """version: 1
name: x
suite: resilience
steps:
  - id: future
    action: chaos.pause_service
    required: false
"""
        )
        proof = sc.validate_scenario(path, self.probes)
        self.assertEqual("SUPPORTED", proof["status"])
        self.assertEqual(1, len(proof["capabilities"]["unsupported_optional"]))

    def test_missing_probe_is_invalid(self):
        path = self.scenario(
            """version: 1
name: x
suite: smoke
assertions:
  - id: impossible
    probe: cluster.not_real
    expect:
      ok: true
"""
        )
        proof = sc.validate_scenario(path, self.probes)
        self.assertEqual("INVALID", proof["status"])
        self.assertTrue(any("unknown probe" in e for e in proof["errors"]))

    def test_wait_until_probe_is_checked(self):
        path = self.scenario(
            """version: 1
name: x
suite: resilience
steps:
  - id: wait
    action: wait
    params:
      until:
        probe: cluster.not_real
        expect:
          ok: true
"""
        )
        proof = sc.validate_scenario(path, self.probes)
        self.assertEqual("INVALID", proof["status"])

    def test_replayable_contract_requires_seed(self):
        path = self.scenario(
            """version: 1
name: x
suite: resilience
contract:
  version: 1
  kind: exploration
  proves: no split brain
  determinism:
    replayable: true
"""
        )
        proof = sc.validate_scenario(path, self.probes)
        self.assertEqual("INVALID", proof["status"])
        self.assertTrue(any("seed" in e for e in proof["errors"]))

    def test_learning_is_non_authoritative(self):
        path = self.scenario(
            """version: 1
name: x
suite: resilience
contract:
  version: 1
  kind: repair
  proves: recovery converges
  origin:
    type: incident
    ref: inc-1
  determinism:
    replayable: true
    seed: 42
  learning:
    enabled: true
    candidate_types: [failure_mode, invariant]
assertions:
  - id: healthy
    probe: cluster.health
    expect:
      status: healthy
"""
        )
        proof = sc.validate_scenario(path, self.probes)
        payload = sc.learning_payload(
            sc.load_yaml(path),
            proof,
            "PASS",
            {
                "items": [
                    {
                        "id": "healthy",
                        "section": "assertions",
                        "probe": "cluster.health",
                        "result": {"status": "healthy"},
                        "passed": True,
                    }
                ]
            },
        )
        self.assertFalse(payload["authority"]["production_authoritative"])
        self.assertTrue(payload["authority"]["promotion_required"])
        self.assertFalse(payload["candidate_policy"]["may_promote"])


if __name__ == "__main__":
    unittest.main()
