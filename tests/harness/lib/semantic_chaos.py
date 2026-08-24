#!/usr/bin/env python3
"""Semantic chaos actions layered on top of the legacy scenario executor.

WHAT THIS MODULE IS FOR

Two things, and they are not the same thing:

  1. DECLARING that an action is supported, so the proof contract does not
     mark a scenario UNSUPPORTED for using it. That is
     SUPPORTED_SEMANTIC_ACTIONS, consumed by scenario_contract_semantic.
  2. EXECUTING an action the legacy dispatcher cannot express. That is
     handle().

pause/resume are declared here but NOT executed here. They used to be, and
the duplicate was strictly weaker than the implementation it shadowed:

  - it took `node` literally, so `node: leader` — which controller-zombie-
    after-lease-loss uses precisely so the fault follows the lease rather
    than a hardcoded name — became the container `globular-leader`, and
    docker answered "No such container". The scenario froze nothing and then
    asserted on leadership that had never moved.
  - it never checked that the signal took: a SIGSTOP that did not land was
    recorded as a successful pause, which makes every assertion after it
    vacuous.
  - it never opened a `service_paused` obligation in the mutation ledger, so
    a scenario that paused a service and died before resuming left the
    service stopped with nothing recorded to restore it.

The legacy dispatcher does all three. So handle() returns None for these and
they run there. Add a new action here only when the legacy dispatcher genuinely
cannot express it — not to re-implement something it already does.
"""
from __future__ import annotations

from typing import Optional

# Declared supported for the proof contract. Execution lives in the legacy
# dispatcher (globular-scenario, _exec_chaos) — see the module docstring.
SUPPORTED_SEMANTIC_ACTIONS = {
    "chaos.pause_service",
    "chaos.resume_service",
}


def handle(executor, item: dict, section: str) -> Optional[bool]:
    """Handle a semantic action, or return None for the legacy executor.

    Currently always returns None: every declared action is executed by the
    legacy dispatcher. Kept as the extension point for actions that the legacy
    dispatcher cannot express.
    """
    return None
