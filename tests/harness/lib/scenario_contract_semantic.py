#!/usr/bin/env python3
"""Scenario proof contract with additive semantic-chaos capabilities."""
from __future__ import annotations

import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
if str(HERE) not in sys.path:
    sys.path.insert(0, str(HERE))

import scenario_contract  # noqa: E402
from semantic_chaos import SUPPORTED_SEMANTIC_ACTIONS  # noqa: E402

scenario_contract.SUPPORTED_ACTIONS.update(SUPPORTED_SEMANTIC_ACTIONS)


if __name__ == "__main__":
    scenario_contract.main()
