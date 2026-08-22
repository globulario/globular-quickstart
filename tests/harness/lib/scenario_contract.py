#!/usr/bin/env python3
"""
Scenario proof-contract validator/finalizer.

This file is intentionally independent of the live cluster. It makes the
scenario definition itself part of the proof boundary:

* every referenced probe must exist;
* every required action must be implemented by the executor;
* optional unsupported actions are visible, never silently treated as proof;
* scenario contract metadata is normalized into machine-readable proof and
  learning artifacts;
* simulation learning is explicitly non-authoritative until governed promotion.

Commands:
  preflight <scenario.yaml> <output-dir> [--probes <probes.sh>]
  finalize  <scenario.yaml> <output-dir> [--executor-exit N]
  audit     <scenario-or-directory> [--probes <probes.sh>]
"""

from __future__ import annotations

import argparse
import datetime as _dt
import json
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import Any

try:
    import yaml
except ImportError:
    print("ERROR: pyyaml required. Run: pip3 install pyyaml", file=sys.stderr)
    raise

PROOF_SCHEMA_VERSION = 1
LEARNING_SCHEMA_VERSION = 1

SUPPORTED_ACTIONS = {
    "wait",
    "chaos.stop_node",
    "chaos.start_node",
    "chaos.kill_service",
    "chaos.sigkill_service",
    "chaos.restart_service",
    "chaos.fill_disk",
    "chaos.clear_disk_fill",
    "chaos.block_network",
    "chaos.unblock_network",
    "chaos.inject_expired_cert",
    "chaos.restore_cert",
    # ── synced with the dispatcher, 2026-08-22 ──────────────────────────────
    # This set is the proof gate: an action missing here makes every scenario
    # using it UNSUPPORTED, which correctly refuses to certify. It was written
    # against a 54-scenario tree and fell behind — the 27 scenarios added since
    # use primitives the dispatcher implements but this set never learned, so
    # 13 scenarios audited UNSUPPORTED while their actions executed fine.
    #
    # Every entry was verified to reach a real branch in globular-scenario, not
    # a _mark_unsupported stub. Deliberately NOT added:
    #   - the seven aspirational names in KNOWN_BUT_UNIMPLEMENTED_ACTIONS; they
    #     dispatch to _mark_unsupported, and promoting them is exactly the
    #     skipped-behaviour-as-proof failure this contract prevents.
    #   - chaos.pause_service / chaos.resume_service; those belong to the
    #     semantic layer, which injects them at runtime via
    #     SUPPORTED_ACTIONS.update(SUPPORTED_SEMANTIC_ACTIONS). Listing them
    #     here would also break the base contract tests, which use
    #     pause_service as their canonical unknown-action fixture.
    "chaos.clear_etcd_volume_fill",
    "chaos.clone_node_state",
    "chaos.deflate_etcd",
    "chaos.detach_node_etcd",
    "chaos.fill_etcd_volume",
    "chaos.inflate_etcd",
    "chaos.restore_node_state",
    "chaos.resume_all_controllers",
    "chaos.snapshot_node_state",
    "chaos.start_all_nodes",
    "chaos.stop_all_nodes",
    "chaos.wipe_node_state",
    "ops.publish",
    "ops.remove_node",
    "ops.set_desired",
}

KNOWN_BUT_UNIMPLEMENTED_ACTIONS = {
    "publish.service_package",
    "repository.promote",
    "desired_state.upsert",
    "workflow.dispatch",
    "backup.create",
    "backup.restore",
    "node.recover.full_reseed",
}

CONTRACT_KINDS = {
    "repair",
    "regression",
    "feature",
    "exploration",
    "certification",
    "training",
    "architecture_evolution",
}

ORIGIN_TYPES = {
    "incident",
    "simulation",
    "feature",
    "manual",
    "regression",
    "architecture",
    "production",
}

LEARNING_CANDIDATE_TYPES = {
    "failure_mode",
    "invariant",
    "condition",
    "principle",
    "scenario",
    "forbidden_fix",
    "required_evidence",
}

RESULTS = {"PASS", "FAIL", "PARTIAL", "INFRA_ERROR", "UNSUPPORTED"}


def utc_now() -> str:
    return _dt.datetime.now(_dt.timezone.utc).isoformat().replace("+00:00", "Z")


def load_yaml(path: Path) -> dict[str, Any]:
    with path.open() as fh:
        data = yaml.safe_load(fh)
    if not isinstance(data, dict):
        raise ValueError("scenario root must be a mapping")
    return data


def repo_revision(path: Path) -> str:
    try:
        proc = subprocess.run(
            ["git", "-C", str(path.parent), "rev-parse", "HEAD"],
            capture_output=True, text=True, timeout=5
        )
        if proc.returncode == 0:
            return proc.stdout.strip()
    except Exception:
        pass
    return os.environ.get("GIT_COMMIT", "") or os.environ.get("SOURCE_REVISION", "")


def default_probes_path(scenario_path: Path) -> Path:
    here = scenario_path.resolve()
    for parent in [here.parent, *here.parents]:
        candidate = parent / "tests" / "harness" / "lib" / "probes.sh"
        if candidate.exists():
            return candidate
    return Path(__file__).with_name("probes.sh")


def load_probe_functions(path: Path) -> set[str]:
    if not path.exists():
        return set()
    names: set[str] = set()
    pattern = re.compile(r"^\s*probe_([A-Za-z0-9_]+)\s*\(\)\s*\{")
    for line in path.read_text(errors="replace").splitlines():
        match = pattern.match(line)
        if match:
            names.add(match.group(1))
    return names


def probe_supported(probe: str, probe_functions: set[str]) -> bool:
    return probe.replace(".", "_") in probe_functions


def normalize_contract(scenario: dict[str, Any]) -> dict[str, Any]:
    raw = scenario.get("contract")
    if raw is None:
        return {
            "declared": False,
            "version": 1,
            "kind": "certification",
            "proves": scenario.get("description", "").strip(),
            "origin": {"type": "manual", "ref": ""},
            "governing_contracts": [],
            "invariants": [],
            "known_failure_modes": [],
            "forbidden_outcomes": [],
            "determinism": {"replayable": False, "seed": None},
            "learning": {
                "enabled": bool((scenario.get("awareness") or {}).get("training")),
                "candidate_types": [],
            },
        }

    if not isinstance(raw, dict):
        raise ValueError("'contract' must be a mapping")

    allowed = {
        "version", "kind", "proves", "origin", "governing_contracts",
        "invariants", "known_failure_modes", "forbidden_outcomes",
        "determinism", "learning",
    }
    unknown = sorted(set(raw) - allowed)
    if unknown:
        raise ValueError(f"unknown contract keys: {unknown}")

    version = raw.get("version", 1)
    if version != 1:
        raise ValueError(f"unsupported contract version: {version}")

    kind = raw.get("kind", "certification")
    if kind not in CONTRACT_KINDS:
        raise ValueError(f"unknown contract kind: {kind}")

    proves = raw.get("proves", "")
    if not isinstance(proves, str):
        raise ValueError("contract.proves must be a string")

    origin = raw.get("origin") or {}
    if not isinstance(origin, dict):
        raise ValueError("contract.origin must be a mapping")
    unknown_origin = sorted(set(origin) - {"type", "ref"})
    if unknown_origin:
        raise ValueError(f"unknown contract.origin keys: {unknown_origin}")
    origin_type = origin.get("type", "manual")
    if origin_type not in ORIGIN_TYPES:
        raise ValueError(f"unknown contract.origin.type: {origin_type}")

    determinism = raw.get("determinism") or {}
    if not isinstance(determinism, dict):
        raise ValueError("contract.determinism must be a mapping")
    unknown_det = sorted(set(determinism) - {"replayable", "seed"})
    if unknown_det:
        raise ValueError(f"unknown contract.determinism keys: {unknown_det}")
    replayable = determinism.get("replayable", False)
    if not isinstance(replayable, bool):
        raise ValueError("contract.determinism.replayable must be boolean")
    seed = determinism.get("seed")
    if replayable and seed is None:
        raise ValueError(
            "contract.determinism.seed is required when replayable=true"
        )

    learning = raw.get("learning") or {}
    if not isinstance(learning, dict):
        raise ValueError("contract.learning must be a mapping")
    unknown_learning = sorted(set(learning) - {"enabled", "candidate_types"})
    if unknown_learning:
        raise ValueError(f"unknown contract.learning keys: {unknown_learning}")
    learning_enabled = learning.get("enabled", False)
    if not isinstance(learning_enabled, bool):
        raise ValueError("contract.learning.enabled must be boolean")
    candidate_types = learning.get("candidate_types") or []
    if not isinstance(candidate_types, list):
        raise ValueError("contract.learning.candidate_types must be a list")
    unknown_candidates = sorted(set(candidate_types) - LEARNING_CANDIDATE_TYPES)
    if unknown_candidates:
        raise ValueError(
            f"unknown contract.learning candidate types: {unknown_candidates}"
        )

    def str_list(key: str) -> list[str]:
        value = raw.get(key) or []
        if not isinstance(value, list) or not all(isinstance(x, str) for x in value):
            raise ValueError(f"contract.{key} must be a list of strings")
        return value

    return {
        "declared": True,
        "version": version,
        "kind": kind,
        "proves": proves.strip(),
        "origin": {"type": origin_type, "ref": str(origin.get("ref", ""))},
        "governing_contracts": str_list("governing_contracts"),
        "invariants": str_list("invariants"),
        "known_failure_modes": str_list("known_failure_modes"),
        "forbidden_outcomes": str_list("forbidden_outcomes"),
        "determinism": {"replayable": replayable, "seed": seed},
        "learning": {
            "enabled": learning_enabled,
            "candidate_types": candidate_types,
        },
    }


def validate_scenario(
    scenario_path: Path,
    probes_path: Path | None = None,
) -> dict[str, Any]:
    scenario = load_yaml(scenario_path)
    errors: list[str] = []
    warnings: list[str] = []
    unsupported_required: list[dict[str, str]] = []
    unsupported_optional: list[dict[str, str]] = []
    missing_probes: list[dict[str, str]] = []

    for field in ("version", "name", "suite"):
        if field not in scenario:
            errors.append(f"missing required field: {field}")
    if scenario.get("version") != 1:
        errors.append(f"unsupported scenario version: {scenario.get('version')!r}")

    try:
        contract = normalize_contract(scenario)
    except ValueError as exc:
        contract = {"declared": bool(scenario.get("contract"))}
        errors.append(str(exc))

    probes_path = probes_path or default_probes_path(scenario_path)
    probe_functions = load_probe_functions(probes_path)
    if not probe_functions:
        errors.append(f"could not enumerate probes from {probes_path}")

    def check_probe(section: str, item_id: str, probe: Any) -> None:
        if not probe:
            errors.append(f"{section}.{item_id}: missing probe")
            return
        if not isinstance(probe, str):
            errors.append(f"{section}.{item_id}: probe must be a string")
            return
        if probe_functions and not probe_supported(probe, probe_functions):
            missing_probes.append({
                "section": section,
                "id": item_id,
                "probe": probe,
            })

    for section in ("preconditions", "baseline", "assertions"):
        items = scenario.get(section) or []
        if not isinstance(items, list):
            errors.append(f"{section} must be a list")
            continue
        for idx, item in enumerate(items):
            if not isinstance(item, dict):
                errors.append(f"{section}[{idx}] must be a mapping")
                continue
            item_id = str(item.get("id") or f"item-{idx}")
            check_probe(section, item_id, item.get("probe"))

    for section in ("steps", "cleanup"):
        items = scenario.get(section) or []
        if not isinstance(items, list):
            errors.append(f"{section} must be a list")
            continue
        for idx, item in enumerate(items):
            if not isinstance(item, dict):
                errors.append(f"{section}[{idx}] must be a mapping")
                continue

            item_id = str(item.get("id") or f"item-{idx}")
            required = item.get("required", True)
            if not isinstance(required, bool):
                errors.append(f"{section}.{item_id}: required must be boolean")
                continue

            if item.get("probe"):
                check_probe(section, item_id, item.get("probe"))
                continue

            action = item.get("action")
            if not action:
                errors.append(f"{section}.{item_id}: missing action or probe")
                continue

            if action == "wait":
                until = (item.get("params") or {}).get("until") or {}
                if until:
                    if not isinstance(until, dict):
                        errors.append(f"{section}.{item_id}: wait.until must be a mapping")
                    else:
                        check_probe(
                            f"{section}.wait",
                            item_id,
                            until.get("probe"),
                        )
                continue

            if action in SUPPORTED_ACTIONS:
                continue

            reason = (
                "known action is declared by the executor but not implemented"
                if action in KNOWN_BUT_UNIMPLEMENTED_ACTIONS
                else "action is unknown to the proof boundary"
            )
            record = {
                "section": section,
                "id": item_id,
                "action": str(action),
                "reason": reason,
            }
            if required:
                unsupported_required.append(record)
            else:
                unsupported_optional.append(record)

    if missing_probes:
        for record in missing_probes:
            errors.append(
                f"{record['section']}.{record['id']}: "
                f"unknown probe {record['probe']}"
            )

    if unsupported_optional:
        warnings.append(
            f"{len(unsupported_optional)} optional unsupported action(s) will not "
            "contribute to proof"
        )

    status = "INVALID" if errors else (
        "UNSUPPORTED" if unsupported_required else "SUPPORTED"
    )
    return {
        "proof_schema_version": PROOF_SCHEMA_VERSION,
        "checked_at": utc_now(),
        "scenario_file": str(scenario_path),
        "scenario": scenario.get("name", scenario_path.stem),
        "suite": scenario.get("suite", "unknown"),
        "source_revision": repo_revision(scenario_path),
        "status": status,
        "proof_eligible": status == "SUPPORTED",
        "contract": contract,
        "capabilities": {
            "supported_actions": sorted(SUPPORTED_ACTIONS),
            "unsupported_required": unsupported_required,
            "unsupported_optional": unsupported_optional,
            "missing_probes": missing_probes,
            "probes_file": str(probes_path),
        },
        "errors": errors,
        "warnings": warnings,
        "production_authoritative": False,
        "promotion_required": True,
    }


def write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2) + "\n")


def write_unsupported_result(
    scenario: dict[str, Any],
    output_dir: Path,
    proof: dict[str, Any],
) -> None:
    evidence = {
        "schema_version": 1,
        "scenario": scenario.get("name", "unknown"),
        "suite": scenario.get("suite", "unknown"),
        "start_time": utc_now(),
        "end_time": utc_now(),
        "passed": False,
        "result": "UNSUPPORTED",
        "item_count": 0,
        "items": [],
        "proof_status": proof.get("status"),
        "unsupported_required": (
            proof.get("capabilities", {}).get("unsupported_required") or []
        ),
        "errors": proof.get("errors") or [],
    }
    write_json(output_dir / "evidence.json", evidence)

    reasons = evidence["unsupported_required"]
    lines = [
        f"# {evidence['scenario']}",
        "",
        f"**Suite**: {evidence['suite']}  ",
        "**Result**: UNSUPPORTED  ",
        "**Proof eligible**: no",
        "",
        "The scenario was not executed because its required proof surface is not "
        "implemented or its contract is invalid.",
        "",
    ]
    if reasons:
        lines += ["## Unsupported required actions", ""]
        for item in reasons:
            lines.append(
                f"- `{item['id']}`: `{item['action']}` — {item['reason']}"
            )
        lines.append("")
    if evidence["errors"]:
        lines += ["## Contract errors", ""]
        lines += [f"- {err}" for err in evidence["errors"]]
        lines.append("")
    lines += [
        "## Safety consequence",
        "",
        "UNSUPPORTED is not PASS and cannot satisfy certification, repair proof, "
        "feature proof, or promotion evidence.",
        "",
    ]
    (output_dir / "RESULT.md").write_text("\n".join(lines))


def learning_payload(
    scenario: dict[str, Any],
    proof: dict[str, Any],
    result: str,
    evidence: dict[str, Any] | None,
) -> dict[str, Any]:
    contract = proof.get("contract") or {}
    failed_items = []
    if evidence:
        failed_items = [
            {
                "section": item.get("section"),
                "id": item.get("id"),
                "probe_or_action": item.get("probe"),
                "result": item.get("result"),
            }
            for item in evidence.get("items", [])
            if not item.get("passed", False)
        ]
    return {
        "learning_schema_version": LEARNING_SCHEMA_VERSION,
        "created_at": utc_now(),
        "source": "globular-quickstart-simulation",
        # Taken from the proof this learning accompanies, not recomputed from
        # the scenario. The two used different fallbacks for a scenario with no
        # name — the proof used the file stem, this used "unknown" — so an
        # unnamed scenario produced a proof and a learning artifact that
        # disagreed about which scenario they described. A consumer binding one
        # to the other would reject a legitimate run. One occurrence, one name,
        # one place it is computed.
        "scenario": proof.get("scenario", scenario.get("name", "unknown")),
        "suite": scenario.get("suite", "unknown"),
        "result": result,
        "source_revision": proof.get("source_revision", ""),
        "proof": {
            "claim": contract.get("proves", ""),
            "kind": contract.get("kind", ""),
            "origin": contract.get("origin", {}),
            "governing_contracts": contract.get("governing_contracts", []),
            "invariants": contract.get("invariants", []),
            "known_failure_modes": contract.get("known_failure_modes", []),
            "forbidden_outcomes": contract.get("forbidden_outcomes", []),
            "determinism": contract.get("determinism", {}),
        },
        "observations": {
            "failed_items": failed_items,
            "unsupported_required": (
                proof.get("capabilities", {}).get("unsupported_required") or []
            ),
            "unsupported_optional": (
                proof.get("capabilities", {}).get("unsupported_optional") or []
            ),
        },
        "candidate_policy": {
            "learning_enabled": (
                (contract.get("learning") or {}).get("enabled", False)
            ),
            "candidate_types": (
                (contract.get("learning") or {}).get("candidate_types", [])
            ),
            "may_create_candidates": True,
            "may_promote": False,
        },
        "authority": {
            "production_authoritative": False,
            "promotion_required": True,
            "note": (
                "Simulation output is evidence/candidate knowledge only. "
                "Governed promotion is required before production may rely on it."
            ),
        },
        "evidence_ref": "evidence.json",
        "proof_ref": "scenario-proof.json",
    }


def cmd_preflight(args: argparse.Namespace) -> int:
    scenario_path = Path(args.scenario)
    output_dir = Path(args.output_dir)
    probes = Path(args.probes) if args.probes else None
    try:
        scenario = load_yaml(scenario_path)
        proof = validate_scenario(scenario_path, probes)
    except Exception as exc:
        print(f"ERROR: {scenario_path}: {exc}", file=sys.stderr)
        return 3

    output_dir.mkdir(parents=True, exist_ok=True)
    write_json(output_dir / "scenario-proof.json", proof)

    if proof["status"] == "SUPPORTED":
        print(f"  [proof] SUPPORTED: {proof['scenario']}")
        for warning in proof.get("warnings", []):
            print(f"  [proof] WARNING: {warning}")
        return 0

    write_unsupported_result(scenario, output_dir, proof)
    write_json(
        output_dir / "learning.json",
        learning_payload(scenario, proof, "UNSUPPORTED", None),
    )
    print(f"  [proof] {proof['status']}: {proof['scenario']}")
    for err in proof.get("errors", []):
        print(f"  [proof] ERROR: {err}")
    for item in proof.get("capabilities", {}).get("unsupported_required", []):
        print(
            f"  [proof] UNSUPPORTED: {item['id']} -> {item['action']} "
            f"({item['reason']})"
        )
    return 2


def cmd_finalize(args: argparse.Namespace) -> int:
    scenario_path = Path(args.scenario)
    output_dir = Path(args.output_dir)
    proof_path = output_dir / "scenario-proof.json"
    evidence_path = output_dir / "evidence.json"

    scenario = load_yaml(scenario_path)
    if proof_path.exists():
        proof = json.loads(proof_path.read_text())
    else:
        proof = validate_scenario(scenario_path)

    evidence: dict[str, Any] | None = None
    if evidence_path.exists():
        evidence = json.loads(evidence_path.read_text())
        result = str(evidence.get("result") or (
            "PASS" if evidence.get("passed") else "FAIL"
        ))
    else:
        result = "INFRA_ERROR" if args.executor_exit else "FAIL"

    if result not in RESULTS:
        result = "FAIL"

    proof["execution"] = {
        "finalized_at": utc_now(),
        "result": result,
        "executor_exit": args.executor_exit,
        "proof_eligible": result == "PASS" and proof.get("status") == "SUPPORTED",
    }
    write_json(proof_path, proof)
    write_json(
        output_dir / "learning.json",
        learning_payload(scenario, proof, result, evidence),
    )

    result_md = output_dir / "RESULT.md"
    if result_md.exists():
        with result_md.open("a") as fh:
            fh.write("\n## Proof Contract\n\n")
            fh.write(
                f"- Contract declared: "
                f"{'yes' if (proof.get('contract') or {}).get('declared') else 'no (legacy scenario)'}\n"
            )
            fh.write(f"- Proof status: {proof.get('status')}\n")
            fh.write(f"- Execution result: {result}\n")
            fh.write(
                "- Production authoritative: **no** — simulation output is "
                "candidate evidence until governed promotion.\n"
            )
            fh.write("- Machine artifacts: `scenario-proof.json`, `learning.json`\n")

    print(f"  [proof] result={result} proof={proof.get('status')}")
    return 0


def iter_scenarios(target: Path):
    if target.is_file():
        yield target
        return
    yield from sorted(target.rglob("*.yaml"))


def cmd_audit(args: argparse.Namespace) -> int:
    target = Path(args.target)
    probes = Path(args.probes) if args.probes else None
    total = supported = unsupported = invalid = 0
    for scenario_path in iter_scenarios(target):
        total += 1
        try:
            proof = validate_scenario(scenario_path, probes)
        except Exception as exc:
            print(f"INVALID {scenario_path}: {exc}")
            invalid += 1
            continue
        status = proof["status"]
        if status == "SUPPORTED":
            supported += 1
        elif status == "UNSUPPORTED":
            unsupported += 1
        else:
            invalid += 1
        print(f"{status:11} {scenario_path}")
        for err in proof.get("errors", []):
            print(f"  error: {err}")
        for item in proof.get("capabilities", {}).get("unsupported_required", []):
            print(f"  unsupported: {item['id']} -> {item['action']}")

    print(
        f"\nScenario proof audit: total={total} supported={supported} "
        f"unsupported={unsupported} invalid={invalid}"
    )
    return 0 if unsupported == 0 and invalid == 0 else 1


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="command", required=True)

    pre = sub.add_parser("preflight")
    pre.add_argument("scenario")
    pre.add_argument("output_dir")
    pre.add_argument("--probes")
    pre.set_defaults(func=cmd_preflight)

    fin = sub.add_parser("finalize")
    fin.add_argument("scenario")
    fin.add_argument("output_dir")
    fin.add_argument("--executor-exit", type=int, default=0)
    fin.set_defaults(func=cmd_finalize)

    audit = sub.add_parser("audit")
    audit.add_argument("target")
    audit.add_argument("--probes")
    audit.set_defaults(func=cmd_audit)
    return parser


def main() -> None:
    args = build_parser().parse_args()
    sys.exit(args.func(args))


if __name__ == "__main__":
    main()
