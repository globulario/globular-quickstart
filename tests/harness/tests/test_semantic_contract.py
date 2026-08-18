import importlib.util
import sys
import unittest
from pathlib import Path

LIB = Path(__file__).parents[1] / "lib"
if str(LIB) not in sys.path:
    sys.path.insert(0, str(LIB))
SPEC = importlib.util.spec_from_file_location(
    "scenario_contract_semantic", LIB / "scenario_contract_semantic.py"
)
module = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(module)


class SemanticContractTest(unittest.TestCase):
    def test_pause_resume_are_proof_supported(self):
        supported = module.scenario_contract.SUPPORTED_ACTIONS
        self.assertIn("chaos.pause_service", supported)
        self.assertIn("chaos.resume_service", supported)


if __name__ == "__main__":
    unittest.main()
