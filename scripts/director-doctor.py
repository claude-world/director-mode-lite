#!/usr/bin/env python3
"""Report Director Mode and three-CLI integration health without changing it."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
from typing import Any


CLIS = ("claude", "codex", "grok")
RUNTIME_ASSETS = (
    "GUIDANCE.md",
    "handoff.schema.json",
    "bin/director-relay",
    "bin/director-open",
    "bin/director-doctor",
)


def runtime_report(root: Path, claude_home: Path) -> dict[str, Any]:
    """Resolve the first usable runtime without treating plugin-only use as broken."""
    project = root / ".director-mode"
    project_assets = {name: project / name for name in RUNTIME_ASSETS}
    user_assets = {
        "GUIDANCE.md": claude_home / "portable" / "GUIDANCE.md",
        "handoff.schema.json": claude_home / "portable" / "handoff.schema.json",
        "bin/director-relay": claude_home / "bin" / "director-relay",
        "bin/director-open": claude_home / "bin" / "director-open",
        "bin/director-doctor": claude_home / "bin" / "director-doctor",
    }
    script = Path(__file__).resolve()
    skill_root = script.parent.parent
    skills_root = skill_root.parent
    plugin_assets = {
        "GUIDANCE.md": skill_root / "references" / "GUIDANCE.md",
        "bin/director-relay": skills_root / "session-relay" / "scripts" / "director-relay.py",
        "bin/director-doctor": script,
    }

    candidates = (
        ("project", project, project_assets),
        ("user", claude_home, user_assets),
        ("plugin", skill_root, plugin_assets),
    )
    source, base, paths = candidates[0]
    for candidate_source, candidate_base, candidate_paths in candidates:
        if all(path.is_file() for path in candidate_paths.values()):
            source, base, paths = candidate_source, candidate_base, candidate_paths
            break

    assets = {name: path.is_file() for name, path in paths.items()}
    issues: list[str] = []
    guidance = paths.get("GUIDANCE.md")
    if guidance is not None and guidance.is_file() and guidance.stat().st_size == 0:
        issues.append("GUIDANCE.md is empty")
    schema = paths.get("handoff.schema.json")
    if schema is not None and schema.is_file():
        try:
            schema_value = json.loads(schema.read_text(encoding="utf-8"))
            if not isinstance(schema_value, dict):
                issues.append("handoff.schema.json root is not an object")
        except (OSError, json.JSONDecodeError) as exc:
            issues.append(f"handoff.schema.json is invalid: {exc}")
    if os.name != "nt":
        for name, path in paths.items():
            if name.startswith("bin/") and path.is_file() and not os.access(path, os.X_OK):
                issues.append(f"{name} is not executable")
    return {
        "source": source,
        "path": str(base),
        "assets": assets,
        "missing": [name for name, present in assets.items() if not present],
        "issues": issues,
    }


def run_git(cwd: Path, *args: str) -> tuple[int, str]:
    try:
        result = subprocess.run(
            ["git", *args], cwd=cwd, check=False, capture_output=True, text=True, timeout=3
        )
    except (FileNotFoundError, OSError, subprocess.TimeoutExpired):
        return 1, ""
    return result.returncode, result.stdout.strip()


def project_root(cwd: Path) -> Path:
    code, value = run_git(cwd, "rev-parse", "--show-toplevel")
    if code == 0 and value:
        return Path(value).resolve()
    for candidate in (cwd, *cwd.parents):
        if (candidate / ".director-mode" / "GUIDANCE.md").is_file():
            return candidate
    return cwd


def working_directory(value: str | None) -> Path:
    selected = value if value is not None else os.environ.get("DIRECTOR_PROJECT_DIR", ".")
    return Path(selected).expanduser().resolve()


def hook_surface(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        return {"path": str(path), "valid": False, "registrations": 0, "error": str(exc)}
    if not isinstance(value, dict):
        return {
            "path": str(path),
            "valid": False,
            "registrations": 0,
            "error": "configuration root is not an object",
        }
    hooks = value.get("hooks", {})
    if not isinstance(hooks, dict):
        return {
            "path": str(path),
            "valid": False,
            "registrations": 0,
            "error": "hooks is not an object",
        }
    count = 0
    for event, entries in hooks.items():
        if not isinstance(entries, list):
            return {
                "path": str(path),
                "valid": False,
                "registrations": count,
                "error": f"hooks.{event} is not a list",
            }
        for entry in entries:
            if not isinstance(entry, dict):
                return {
                    "path": str(path),
                    "valid": False,
                    "registrations": count,
                    "error": f"hooks.{event} contains a non-object entry",
                }
            if isinstance(entry.get("command"), str):
                count += 1
            nested = entry.get("hooks")
            if nested is not None and not isinstance(nested, list):
                return {
                    "path": str(path),
                    "valid": False,
                    "registrations": count,
                    "error": f"hooks.{event} entry hooks is not a list",
                }
            if isinstance(nested, list):
                count += sum(
                    1
                    for hook in nested
                    if isinstance(hook, dict) and isinstance(hook.get("command"), str)
                )
    return {"path": str(path), "valid": True, "registrations": count, "error": None}


def version_for(binary: str, probe: bool) -> str | None:
    path = shutil.which(binary)
    if not path or not probe:
        return None
    try:
        result = subprocess.run(
            [binary, "--version"], check=False, capture_output=True, text=True, timeout=5
        )
    except (OSError, subprocess.TimeoutExpired):
        return "unavailable"
    value = (result.stdout or result.stderr).strip().splitlines()
    return value[0] if value else f"exit {result.returncode}"


def count_unique(paths: tuple[Path, ...], pattern: str, skill: bool = False) -> int:
    names: set[str] = set()
    for path in paths:
        if not path.is_dir():
            continue
        for item in path.glob(pattern):
            if item.is_file():
                names.add(item.parent.name if skill else item.stem)
    return len(names)


def build_report(cwd: Path, probe: bool) -> dict[str, Any]:
    root = project_root(cwd)
    user_home = Path.home()
    claude_home = Path(os.environ.get("CLAUDE_CONFIG_DIR", user_home / ".claude")).expanduser()
    codex_home = Path(os.environ.get("CODEX_HOME", user_home / ".codex")).expanduser()
    grok_home = Path(
        os.environ.get("GROK_HOME", os.environ.get("GROK_CONFIG_DIR", user_home / ".grok"))
    ).expanduser()
    shared_skill_home = user_home / ".agents" / "skills"

    cli_report: dict[str, Any] = {}
    for cli in CLIS:
        cli_report[cli] = {
            "path": shutil.which(cli),
            "version": version_for(cli, probe),
        }

    hook_surfaces = {
        "claude_global": claude_home / "settings.json",
        "claude_project": root / ".claude" / "settings.json",
        "claude_local": root / ".claude" / "settings.local.json",
        "codex_global": codex_home / "hooks.json",
        "codex_project": root / ".codex" / "hooks.json",
        "grok_global": grok_home / "hooks.json",
        "grok_project": root / ".grok" / "hooks.json",
        "grok_director_adapter": root / ".grok" / "hooks" / "director-mode.json",
    }
    for scope, directory in (
        ("grok_global_file", grok_home / "hooks"),
        ("grok_project_file", root / ".grok" / "hooks"),
    ):
        if directory.is_dir():
            for path in sorted(directory.glob("*.json")):
                hook_surfaces[f"{scope}:{path.name}"] = path
    hooks: dict[str, dict[str, Any]] = {}
    seen_paths: set[Path] = set()
    for name, path in hook_surfaces.items():
        if not path.is_file() or path in seen_paths:
            continue
        seen_paths.add(path)
        hooks[name] = hook_surface(path)
    total_hooks = sum(item["registrations"] for item in hooks.values())
    invalid_hooks = [name for name, item in hooks.items() if not item["valid"]]

    runtime = runtime_report(root, claude_home)
    missing = runtime["missing"]
    runtime_issues = runtime["issues"]
    recommendations: list[str] = []
    if missing or runtime_issues:
        recommendations.append(
            "The selected runtime is incomplete or invalid; review it or rerun the Director Mode installer with --hooks none."
        )
    if any(value["path"] is None for value in cli_report.values()):
        recommendations.append("Install only the CLIs you intend to use; missing CLIs do not block the others.")
    if total_hooks:
        recommendations.append(
            "Hook registrations were discovered. Review them if startup or tool use feels constrained."
        )
    if invalid_hooks:
        recommendations.append(
            "Some hook configurations could not be validated; inspect them before trusting a zero-hook result."
        )
    if not recommendations:
        recommendations.append("Three-CLI runtime is present and no hook registrations were found on known surfaces.")

    return {
        "mode": "read-only",
        "project_root": str(root),
        "runtime": runtime,
        "cli": cli_report,
        "assets": {
            "claude": {
                "skills": count_unique(
                    (root / ".claude" / "skills", claude_home / "skills"),
                    "*/SKILL.md",
                    skill=True,
                ),
                "agents": count_unique(
                    (root / ".claude" / "agents", claude_home / "agents"), "*.md"
                ),
            },
            "codex": {
                "skills": count_unique(
                    (root / ".agents" / "skills", shared_skill_home),
                    "*/SKILL.md",
                    skill=True,
                ),
                "agents": count_unique(
                    (root / ".codex" / "agents", codex_home / "agents"), "*.toml"
                ),
            },
            "grok": {
                "shared_skills": count_unique(
                    (root / ".claude" / "skills", claude_home / "skills"),
                    "*/SKILL.md",
                    skill=True,
                ),
                "agents": count_unique(
                    (root / ".grok" / "agents", grok_home / "agents"), "*.md"
                ),
            },
        },
        "hooks": {
            "known_registrations": total_hooks,
            "invalid_surfaces": invalid_hooks,
            "surfaces": hooks,
        },
        "recommendations": recommendations,
    }


def parser() -> argparse.ArgumentParser:
    value = argparse.ArgumentParser(description=__doc__)
    value.add_argument(
        "--cwd",
        default=None,
        help="project directory (default: DIRECTOR_PROJECT_DIR or current directory)",
    )
    value.add_argument("--json", action="store_true", help="emit machine-readable JSON")
    value.add_argument("--no-probe", action="store_true", help="do not invoke CLI --version commands")
    return value


def main() -> int:
    args = parser().parse_args()
    cwd = working_directory(args.cwd)
    if not cwd.is_dir():
        print(f"director-doctor: directory does not exist: {cwd}")
        return 2
    report = build_report(cwd, not args.no_probe)
    if args.json:
        print(json.dumps(report, indent=2, ensure_ascii=False))
        return 0

    print("Director Mode doctor (read-only)")
    print(f"project: {report['project_root']}")
    for cli, state in report["cli"].items():
        label = state["version"] or ("found" if state["path"] else "not found")
        print(f"{cli}: {label}")
    counts = report["assets"]
    print(
        "assets: "
        f"Claude {counts['claude']['skills']} skills/{counts['claude']['agents']} agents; "
        f"Codex {counts['codex']['skills']} skills/{counts['codex']['agents']} agents; "
        f"Grok {counts['grok']['shared_skills']} shared skills/{counts['grok']['agents']} agents"
    )
    missing = report["runtime"]["missing"]
    runtime_source = report["runtime"]["source"]
    runtime_label = (
        "complete"
        if not missing and not report["runtime"]["issues"]
        else ("missing " + ", ".join(missing) if missing else "present with issues")
    )
    print(
        f"runtime ({runtime_source}): "
        f"{runtime_label}"
    )
    if report["runtime"]["issues"]:
        print("runtime issues: " + ", ".join(report["runtime"]["issues"]))
    print(f"known hook registrations: {report['hooks']['known_registrations']}")
    if report["hooks"]["invalid_surfaces"]:
        print("invalid hook surfaces: " + ", ".join(report["hooks"]["invalid_surfaces"]))
    for advice in report["recommendations"]:
        print(f"guidance: {advice}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
