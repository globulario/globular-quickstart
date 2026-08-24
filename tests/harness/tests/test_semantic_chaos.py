"""The semantic layer declares pause/resume; the legacy dispatcher executes them.

These tests used to assert the semantic layer's own SIGSTOP/SIGCONT
implementation. That implementation was removed because it shadowed a stronger
one in globular-scenario: it took `node` literally (so `node: leader` became the
container `globular-leader` and froze nothing), never verified the signal took,
and never opened a `service_paused` obligation in the mutation ledger. What is
tested now is the contract that replaced it — the action stays declared, and
execution delegates.
"""
import importlib.util
import unittest
from pathlib import Path

LIB = Path(__file__).parents[1] / "lib"
SPEC = importlib.util.spec_from_file_location("semantic_chaos", LIB / "semantic_chaos.py")
semantic_chaos = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(semantic_chaos)


class Evidence:
    def __init__(self):
        self.rows = []

    def record(self, *args):
        self.rows.append(args)


class Executor:
    def __init__(self):
        self.evidence = Evidence()
        self.failures = []

    def _chaos_fail(self, section, item_id, action, params, reason):
        self.failures.append((section, item_id, action, params, reason))
        return False


class SemanticChaosTest(unittest.TestCase):
    def test_pause_and_resume_are_declared_supported(self):
        # The proof contract reads this set. Dropping an action from it would
        # make every scenario using it report UNSUPPORTED.
        self.assertIn("chaos.pause_service", semantic_chaos.SUPPORTED_SEMANTIC_ACTIONS)
        self.assertIn("chaos.resume_service", semantic_chaos.SUPPORTED_SEMANTIC_ACTIONS)

    def test_pause_delegates_to_the_legacy_dispatcher(self):
        # None means "not handled here" — the legacy dispatcher runs it, and
        # with it the leader-alias resolution, the /proc state check, and the
        # mutation ledger entry.
        executor = Executor()
        self.assertIsNone(
            semantic_chaos.handle(
                executor,
                {
                    "id": "pause-controller",
                    "action": "chaos.pause_service",
                    "params": {"node": "leader", "service": "cluster-controller"},
                },
                "steps",
            )
        )
        # Delegating must not record evidence or a failure of its own, or the
        # action would be reported twice.
        self.assertEqual(executor.evidence.rows, [])
        self.assertEqual(executor.failures, [])

    def test_resume_delegates_to_the_legacy_dispatcher(self):
        executor = Executor()
        self.assertIsNone(
            semantic_chaos.handle(
                executor,
                {
                    "id": "resume-controller",
                    "action": "chaos.resume_service",
                    "params": {"node": "node-1", "service": "cluster-controller"},
                },
                "cleanup",
            )
        )

    def test_unknown_action_delegates(self):
        self.assertIsNone(
            semantic_chaos.handle(
                Executor(), {"action": "chaos.stop_node", "params": {}}, "steps"
            )
        )


if __name__ == "__main__":
    unittest.main()
