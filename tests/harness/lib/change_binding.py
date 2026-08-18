#!/usr/bin/env python3
"""Bind quickstart proof/learning artifacts to a governed ChangeEnvelope candidate."""
from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

TRUE_VALUES = {"1", "true", "yes", "on"}


def _required() -> bool:
    return os.environ.get("GLOBULAR_REQUIRE_CHANGE_BINDING", "").strip().lower() in TRUE_VALUES


def _binding(proof: dict) -> dict:
    return {
        "id": os.environ.get("GLOBULAR_CHANGE_ID", "").strip(),
        "envelope_ref": os.environ.get("GLOBULAR_CHANGE_ENVELOPE_REF", "").strip(),
        "candidate_repository": os.environ.get("GLOBULAR_CANDIDATE_REPOSITORY", "").strip(),
        "candidate_revision": os.environ.get("GLOBULAR_CANDIDATE_REVISION", "").strip(),
        "simulation_revision": str(proof.get("source_revision") or ""),
    }


def _validate(binding: dict, required: bool) -> list[str]:
    present = any(binding.get(k) for k in ("id", "envelope_ref", "candidate_repository", "candidate_revision"))
    if not present and not required:
        return []
    errors = []
    for field in ("id", "candidate_repository", "candidate_revision", "simulation_revision"):
        if not binding.get(field):
            errors.append(f"change binding requires {field}")
    return errors


def _load(path: Path) -> dict:
    if not path.exists():
        return {}
    with path.open() as fh:
        return json.load(fh)


def _write(path: Path, payload: dict) -> None:
    path.write_text(json.dumps(payload, indent=2) + "\n")


def apply(output_dir: Path) -> int:
    proof_path = output_dir / "scenario-proof.json"
    if not proof_path.exists():
        print(f"  [change] ERROR: missing {proof_path}", file=sys.stderr)
        return 2

    proof = _load(proof_path)
    binding = _binding(proof)
    required = _required()
    present = any(binding.get(k) for k in ("id", "envelope_ref", "candidate_repository", "candidate_revision"))
    if not present and not required:
        return 0

    errors = _validate(binding, required)
    proof["change"] = binding
    proof["change_binding_status"] = "INVALID" if errors else "BOUND"
    if errors:
        proof.setdefault("errors", [])
        for err in errors:
            if err not in proof["errors"]:
                proof["errors"].append(err)
        proof["proof_eligible"] = False
        if isinstance(proof.get("execution"), dict):
            proof["execution"]["proof_eligible"] = False
    _write(proof_path, proof)

    learning_path = output_dir / "learning.json"
    if learning_path.exists():
        learning = _load(learning_path)
        learning["change"] = binding
        learning["change_binding_status"] = proof["change_binding_status"]
        _write(learning_path, learning)

    if errors:
        for err in errors:
            print(f"  [change] ERROR: {err}", file=sys.stderr)
        return 2
    print(
        "  [change] BOUND: "
        f"{binding['id']} -> {binding['candidate_repository']}@{binding['candidate_revision']}"
    )
    return 0


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("output_dir")
    args = parser.parse_args()
    sys.exit(apply(Path(args.output_dir)))


if __name__ == "__main__":
    main()
