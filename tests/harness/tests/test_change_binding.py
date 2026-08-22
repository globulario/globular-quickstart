import importlib.util
import json
import os
import tempfile
import unittest
from pathlib import Path

SPEC = importlib.util.spec_from_file_location(
    "change_binding",
    Path(__file__).parents[1] / "lib" / "change_binding.py",
)
change_binding = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(change_binding)


class ChangeBindingTest(unittest.TestCase):
    def setUp(self):
        self.old_env = os.environ.copy()
        self.dir = Path(tempfile.mkdtemp())
        (self.dir / "scenario-proof.json").write_text(
            json.dumps({"source_revision": "sim-sha", "proof_eligible": True})
        )
        (self.dir / "learning.json").write_text(
            json.dumps({"source": "globular-quickstart-simulation"})
        )

    def tearDown(self):
        os.environ.clear()
        os.environ.update(self.old_env)

    def test_unbound_optional_is_noop(self):
        self.assertEqual(change_binding.apply(self.dir), 0)
        proof = json.loads((self.dir / "scenario-proof.json").read_text())
        self.assertNotIn("change", proof)

    def test_partial_binding_is_not_proof(self):
        os.environ["GLOBULAR_CHANGE_ID"] = "chg-1"
        self.assertEqual(change_binding.apply(self.dir), 2)
        proof = json.loads((self.dir / "scenario-proof.json").read_text())
        self.assertFalse(proof["proof_eligible"])
        self.assertEqual(proof["change_binding_status"], "INVALID")

    def test_complete_binding_propagates_to_learning(self):
        os.environ.update(
            {
                "GLOBULAR_CHANGE_ID": "chg-1",
                "GLOBULAR_CHANGE_ENVELOPE_REF": "services:change/chg-1",
                "GLOBULAR_CANDIDATE_REPOSITORY": "globulario/services",
                "GLOBULAR_CANDIDATE_REVISION": "candidate-sha",
                "GLOBULAR_CHANGE_PLAN_DIGEST": "sha256:plan",
                "GLOBULAR_PROOF_INVOCATION_ID": "inv-1",
                "GLOBULAR_PROOF_RUN_DIR": str(self.dir),
            }
        )
        self.assertEqual(change_binding.apply(self.dir), 0)
        proof = json.loads((self.dir / "scenario-proof.json").read_text())
        learning = json.loads((self.dir / "learning.json").read_text())
        self.assertEqual(proof["change"]["simulation_revision"], "sim-sha")
        self.assertEqual(proof["change"]["plan_digest"], "sha256:plan")
        self.assertEqual(learning["change"]["candidate_revision"], "candidate-sha")
        self.assertEqual(learning["change"]["plan_digest"], "sha256:plan")
        self.assertEqual(proof["change_binding_status"], "BOUND")
        self.assertEqual(proof["invocation"]["id"], "inv-1")
        self.assertEqual(proof["invocation"]["run_dir"], str(self.dir))
        self.assertEqual(learning["invocation"]["id"], "inv-1")

    def test_missing_plan_digest_is_not_proof(self):
        os.environ.update(
            {
                "GLOBULAR_CHANGE_ID": "chg-1",
                "GLOBULAR_CANDIDATE_REPOSITORY": "globulario/services",
                "GLOBULAR_CANDIDATE_REVISION": "candidate-sha",
            }
        )
        self.assertEqual(change_binding.apply(self.dir), 2)
        proof = json.loads((self.dir / "scenario-proof.json").read_text())
        self.assertFalse(proof["proof_eligible"])

    def _complete_env(self):
        return {
            "GLOBULAR_CHANGE_ID": "chg-1",
            "GLOBULAR_CHANGE_ENVELOPE_REF": "services:change/chg-1",
            "GLOBULAR_CANDIDATE_REPOSITORY": "globulario/services",
            "GLOBULAR_CANDIDATE_REVISION": "candidate-sha",
            "GLOBULAR_CHANGE_PLAN_DIGEST": "sha256:plan",
            "GLOBULAR_PROOF_INVOCATION_ID": "inv-1",
            "GLOBULAR_PROOF_RUN_DIR": "/tmp/inv-1",
        }

    def test_missing_invocation_id_is_not_proof(self):
        """A proof that cannot say which run produced it is not a proof.

        Without the invocation stamp an artifact is indistinguishable from an
        earlier or concurrent run's output, which is exactly the substitution
        the governed caller has to be able to reject.
        """
        env = self._complete_env()
        del env["GLOBULAR_PROOF_INVOCATION_ID"]
        os.environ.update(env)
        self.assertEqual(change_binding.apply(self.dir), 2)
        proof = json.loads((self.dir / "scenario-proof.json").read_text())
        self.assertFalse(proof["proof_eligible"])
        self.assertEqual(proof["change_binding_status"], "INVALID")
        self.assertIn(
            "change binding requires an invocation id", proof.get("errors", [])
        )

    def test_invocation_stamp_is_recorded_verbatim(self):
        """The stamp is carried through unaltered so the caller can match it."""
        env = self._complete_env()
        env["GLOBULAR_PROOF_INVOCATION_ID"] = "inv-20260817T000000Z-abcdef"
        os.environ.update(env)
        self.assertEqual(change_binding.apply(self.dir), 0)
        proof = json.loads((self.dir / "scenario-proof.json").read_text())
        self.assertEqual(proof["invocation"]["id"], "inv-20260817T000000Z-abcdef")

    def test_required_binding_fails_when_absent(self):
        os.environ["GLOBULAR_REQUIRE_CHANGE_BINDING"] = "1"
        self.assertEqual(change_binding.apply(self.dir), 2)
        proof = json.loads((self.dir / "scenario-proof.json").read_text())
        self.assertFalse(proof["proof_eligible"])


if __name__ == "__main__":
    unittest.main()
