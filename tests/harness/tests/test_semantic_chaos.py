import importlib.util
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest import mock

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
    @mock.patch.object(subprocess, "run")
    def test_pause_service_sends_sigstop(self, run):
        run.return_value = subprocess.CompletedProcess([], 0, "", "")
        executor = Executor()
        ok = semantic_chaos.handle(
            executor,
            {
                "id": "pause-controller",
                "action": "chaos.pause_service",
                "params": {"node": "node-1", "service": "cluster-controller"},
            },
            "steps",
        )
        self.assertTrue(ok)
        command = run.call_args.args[0]
        self.assertEqual(command[-3:], ["-s", "STOP", "globular-cluster-controller.service"])
        self.assertEqual(len(executor.evidence.rows), 1)

    @mock.patch.object(subprocess, "run")
    def test_resume_service_sends_sigcont(self, run):
        run.return_value = subprocess.CompletedProcess([], 0, "", "")
        executor = Executor()
        ok = semantic_chaos.handle(
            executor,
            {
                "id": "resume-controller",
                "action": "chaos.resume_service",
                "params": {"node": "node-1", "service": "cluster-controller"},
            },
            "cleanup",
        )
        self.assertTrue(ok)
        self.assertIn("CONT", run.call_args.args[0])

    def test_missing_subject_fails_closed(self):
        executor = Executor()
        ok = semantic_chaos.handle(
            executor,
            {"action": "chaos.pause_service", "params": {"node": "node-1"}},
            "steps",
        )
        self.assertFalse(ok)
        self.assertEqual(len(executor.failures), 1)

    def test_unknown_action_delegates(self):
        self.assertIsNone(
            semantic_chaos.handle(
                Executor(), {"action": "chaos.stop_node", "params": {}}, "steps"
            )
        )


if __name__ == "__main__":
    unittest.main()
