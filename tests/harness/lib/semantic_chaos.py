#!/usr/bin/env python3
"""Semantic chaos actions layered on top of the legacy scenario executor."""
from __future__ import annotations

import subprocess
from typing import Optional

SUPPORTED_SEMANTIC_ACTIONS = {
    "chaos.pause_service",
    "chaos.resume_service",
}


def handle(executor, item: dict, section: str) -> Optional[bool]:
    """Handle a semantic action, or return None for the legacy executor."""
    action = item.get("action", "")
    if action not in SUPPORTED_SEMANTIC_ACTIONS:
        return None

    params = item.get("params", {}) or {}
    item_id = item.get("id", action)
    node = params.get("node", "")
    service = params.get("service", "")
    if not node or not service:
        return executor._chaos_fail(  # pylint: disable=protected-access
            section, item_id, action, params, "node and service params required"
        )

    container = f"globular-{node}"
    unit = f"globular-{service}.service"
    signal = "STOP" if action == "chaos.pause_service" else "CONT"
    try:
        proc = subprocess.run(
            [
                "docker",
                "exec",
                container,
                "systemctl",
                "kill",
                "--kill-who=main",
                "-s",
                signal,
                unit,
            ],
            capture_output=True,
            text=True,
            timeout=15,
        )
    except subprocess.TimeoutExpired:
        return executor._chaos_fail(  # pylint: disable=protected-access
            section, item_id, action, params, "timed out after 15s"
        )
    except Exception as exc:  # pragma: no cover - defensive host boundary
        return executor._chaos_fail(  # pylint: disable=protected-access
            section, item_id, action, params, str(exc)
        )

    ok = proc.returncode == 0
    result = {
        "action": action,
        "container": container,
        "unit": unit,
        "signal": f"SIG{signal}",
        "exit_code": proc.returncode,
        "stderr": proc.stderr.strip()[:200],
    }
    executor.evidence.record(section, item_id, action, params, {}, result, ok)
    if not ok:
        print(f"    ERROR: {item_id} — systemctl kill -s {signal} failed")
    return ok
