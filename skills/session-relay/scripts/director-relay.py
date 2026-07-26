#!/usr/bin/env python3
"""Create and continue portable handoffs between Claude Code, Codex, and Grok."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from typing import Any
from uuid import uuid4

PROTOCOL = "director-handoff/v2"
SUPPORTED_PROTOCOLS = ("director-handoff/v1", PROTOCOL)
CLIS = ("claude", "codex", "grok")
MAX_GIT_LINES = 200


class RelayError(RuntimeError):
    """A user-facing relay error."""


def run_git(cwd: Path, *args: str) -> tuple[int, str]:
    try:
        result = subprocess.run(
            ["git", *args],
            cwd=cwd,
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
        )
    except (FileNotFoundError, OSError):
        return 1, ""
    return result.returncode, result.stdout.strip()


def limited_lines(value: str) -> tuple[list[str], bool]:
    lines = [line for line in value.splitlines() if line.strip()]
    return lines[:MAX_GIT_LINES], len(lines) > MAX_GIT_LINES


def workspace_snapshot(cwd: Path) -> dict[str, Any]:
    code, root_value = run_git(cwd, "rev-parse", "--show-toplevel")
    if code != 0:
        return {
            "path": str(cwd),
            "git_root": None,
            "branch": None,
            "head": None,
            "status": [],
            "diff_stat": [],
            "status_truncated": False,
        }

    root = Path(root_value).resolve()
    _, branch = run_git(root, "branch", "--show-current")
    _, head = run_git(root, "rev-parse", "HEAD")
    _, status_value = run_git(root, "status", "--short", "--untracked-files=normal")
    _, diff_value = run_git(root, "diff", "--stat", "HEAD")
    status, truncated_status = limited_lines(status_value)
    diff_stat, truncated_diff = limited_lines(diff_value)
    return {
        "path": str(cwd),
        "git_root": str(root),
        "branch": branch or None,
        "head": head or None,
        "status": status,
        "diff_stat": diff_stat,
        "status_truncated": truncated_status or truncated_diff,
    }


def project_root(cwd: Path) -> Path:
    code, git_root = run_git(cwd, "rev-parse", "--show-toplevel")
    if code == 0 and git_root:
        return Path(git_root).resolve()
    for candidate in (cwd, *cwd.parents):
        if (candidate / ".director-mode" / "GUIDANCE.md").is_file():
            return candidate
    return cwd


def working_directory(value: str | None) -> Path:
    selected = value if value is not None else os.environ.get("DIRECTOR_PROJECT_DIR", ".")
    return Path(selected).expanduser().resolve()


def handoff_dir(cwd: Path) -> Path:
    return project_root(cwd) / ".director-mode" / "handoffs"


def resolve_packet(value: str | None, cwd: Path) -> Path:
    candidate = Path(value).expanduser() if value else handoff_dir(cwd) / "latest.json"
    if not candidate.is_absolute():
        candidate = cwd / candidate
    candidate = candidate.resolve()
    if not candidate.is_file():
        raise RelayError(f"handoff packet not found: {candidate}")
    return candidate


def load_packet(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise RelayError(f"cannot read handoff packet {path}: {exc}") from exc
    validate_packet(data)
    return data


def atomic_write(path: Path, value: str) -> None:
    """Replace one text file without exposing a partially written packet."""
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    temporary_path = Path(temporary_name)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            handle.write(value)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary_path, path)
    finally:
        temporary_path.unlink(missing_ok=True)


def string_list(value: Any, field: str) -> None:
    if not isinstance(value, list) or any(not isinstance(item, str) or not item.strip() for item in value):
        raise RelayError(f"task.{field} must be a list of non-empty strings")


def exact_keys(value: dict[str, Any], required: set[str], label: str) -> None:
    missing = required - value.keys()
    extra = value.keys() - required
    if missing:
        raise RelayError(f"{label} is missing: {', '.join(sorted(missing))}")
    if extra:
        raise RelayError(f"{label} has unsupported fields: {', '.join(sorted(extra))}")


def validate_packet(data: Any) -> None:
    if not isinstance(data, dict):
        raise RelayError("packet root must be an object")
    protocol = data.get("protocol")
    if protocol not in SUPPORTED_PROTOCOLS:
        raise RelayError(f"unsupported protocol: {data.get('protocol')!r}")
    packet_fields = {
        "protocol", "id", "created_at", "privacy", "source", "target", "workspace", "task",
    }
    if protocol == PROTOCOL:
        packet_fields.add("lineage")
    exact_keys(data, packet_fields, "packet")
    if not isinstance(data.get("id"), str) or not data["id"].strip():
        raise RelayError("id must be a non-empty string")
    if not isinstance(data.get("created_at"), str) or not data["created_at"].strip():
        raise RelayError("created_at must be a non-empty string")
    try:
        created_at = datetime.fromisoformat(data["created_at"].replace("Z", "+00:00"))
    except ValueError as exc:
        raise RelayError("created_at must be an ISO 8601 date-time") from exc
    if created_at.tzinfo is None:
        raise RelayError("created_at must include a timezone")
    if protocol == PROTOCOL:
        lineage = data.get("lineage")
        if not isinstance(lineage, dict):
            raise RelayError("lineage must be an object")
        exact_keys(lineage, {"root_id", "parent_id", "hop", "route"}, "lineage")
        if not isinstance(lineage.get("root_id"), str) or not lineage["root_id"].strip():
            raise RelayError("lineage.root_id must be a non-empty string")
        if lineage.get("parent_id") is not None and (
            not isinstance(lineage["parent_id"], str) or not lineage["parent_id"].strip()
        ):
            raise RelayError("lineage.parent_id must be a non-empty string or null")
        if not isinstance(lineage.get("hop"), int) or isinstance(lineage["hop"], bool) or lineage["hop"] < 0:
            raise RelayError("lineage.hop must be a non-negative integer")
        route = lineage.get("route")
        if not isinstance(route, list) or len(route) < 2 or any(cli not in CLIS for cli in route):
            raise RelayError(f"lineage.route must contain at least two values from: {', '.join(CLIS)}")
    privacy = data.get("privacy")
    if not isinstance(privacy, dict):
        raise RelayError("privacy must be an object")
    exact_keys(
        privacy,
        {"capture_mode", "raw_transcript_included", "file_contents_included", "review_status"},
        "privacy",
    )
    if privacy.get("capture_mode") != "git-metadata-only":
        raise RelayError("privacy.capture_mode must be git-metadata-only")
    if privacy.get("raw_transcript_included") is not False:
        raise RelayError("privacy.raw_transcript_included must be false")
    if privacy.get("file_contents_included") is not False:
        raise RelayError("privacy.file_contents_included must be false")
    if privacy.get("review_status") not in ("unreviewed", "reviewed"):
        raise RelayError("privacy.review_status must be unreviewed or reviewed")
    for endpoint in ("source", "target"):
        value = data.get(endpoint)
        if not isinstance(value, dict) or value.get("cli") not in CLIS:
            raise RelayError(f"{endpoint}.cli must be one of: {', '.join(CLIS)}")
        exact_keys(value, {"cli", "session_id"}, endpoint)
        if value["session_id"] is not None and not isinstance(value["session_id"], str):
            raise RelayError(f"{endpoint}.session_id must be a string or null")
    if protocol == PROTOCOL:
        lineage = data["lineage"]
        if lineage["hop"] == 0 and (
            lineage["root_id"] != data["id"] or lineage["parent_id"] is not None
        ):
            raise RelayError("initial lineage must use the packet id as root_id and a null parent_id")
        if lineage["hop"] > 0 and lineage["parent_id"] is None:
            raise RelayError("continued lineage must identify its parent packet")
        if lineage["route"][-2:] != [data["source"]["cli"], data["target"]["cli"]]:
            raise RelayError("lineage.route must end with the source and target CLIs")
    task = data.get("task")
    if not isinstance(task, dict):
        raise RelayError("task must be an object")
    task_fields = {
        "goal", "summary", "in_scope", "out_of_scope", "constraints",
        "completed", "decisions", "next_steps", "verification", "blockers", "notes",
    }
    exact_keys(task, task_fields, "task")
    for field in ("goal", "summary"):
        if not isinstance(task.get(field), str) or not task[field].strip():
            raise RelayError(f"task.{field} must be a non-empty string")
    for field in (
        "in_scope",
        "out_of_scope",
        "constraints",
        "completed",
        "decisions",
        "next_steps",
        "verification",
        "blockers",
        "notes",
    ):
        string_list(task.get(field), field)
    workspace = data.get("workspace")
    if not isinstance(workspace, dict):
        raise RelayError("workspace must be an object")
    exact_keys(
        workspace,
        {"path", "git_root", "branch", "head", "status", "diff_stat", "status_truncated"},
        "workspace",
    )
    if not isinstance(workspace.get("path"), str):
        raise RelayError("workspace.path must be a string")
    for field in ("git_root", "branch", "head"):
        if workspace[field] is not None and not isinstance(workspace[field], str):
            raise RelayError(f"workspace.{field} must be a string or null")
    for field in ("status", "diff_stat"):
        if not isinstance(workspace[field], list) or any(not isinstance(item, str) for item in workspace[field]):
            raise RelayError(f"workspace.{field} must be a list of strings")
    if not isinstance(workspace["status_truncated"], bool):
        raise RelayError("workspace.status_truncated must be a boolean")


def markdown_list(items: list[str], empty: str = "None recorded.") -> str:
    return "\n".join(f"- {item}" for item in items) if items else f"- {empty}"


def render_markdown(data: dict[str, Any]) -> str:
    source = data["source"]
    target = data["target"]
    workspace = data["workspace"]
    task = data["task"]
    status = workspace["status"]
    diff_stat = workspace["diff_stat"]
    session = source.get("session_id") or "not supplied"
    branch = workspace.get("branch") or "not a git repository"
    head = workspace.get("head") or "n/a"
    lineage = data.get("lineage") or {
        "root_id": data["id"],
        "parent_id": None,
        "hop": 0,
        "route": [source["cli"], target["cli"]],
    }
    route = " → ".join(lineage["route"])
    parent = lineage.get("parent_id") or "first packet"
    return f"""# Director handoff: {source['cli']} → {target['cli']}

> Protocol: `{data['protocol']}`<br>
> Packet: `{data['id']}`<br>
> Relay chain: `{route}` (hop {lineage['hop']}, parent: `{parent}`)<br>
> Created: `{data['created_at']}`<br>
> Source native session: `{session}`<br>
> Metadata review: `{data['privacy']['review_status']}`

This packet continues work in a **new native {target['cli']} session**. It does
not transfer vendor conversation history, permissions, approvals, or sandbox
state. It contains user-supplied text, paths, and Git filenames, so review it
before sharing outside the workspace. Inspect the current worktree before
making changes.

## Goal

{task['goal']}

## Current state

{task['summary']}

## Scope and constraints

### In scope

{markdown_list(task['in_scope'], 'Use the stated goal as the current scope.')}

### Out of scope

{markdown_list(task['out_of_scope'])}

### Constraints and preferences

{markdown_list(task['constraints'])}

## Completed

{markdown_list(task['completed'])}

## Decisions

{markdown_list(task['decisions'])}

## Next steps

{markdown_list(task['next_steps'], 'Choose the next step after inspecting the worktree.')}

## Verification

{markdown_list(task['verification'])}

## Blockers

{markdown_list(task['blockers'])}

## Notes

{markdown_list(task['notes'])}

## Workspace evidence

- Working directory: `{workspace['path']}`
- Git root: `{workspace.get('git_root') or 'n/a'}`
- Branch: `{branch}`
- HEAD: `{head}`
- Evidence truncated: `{str(bool(workspace.get('status_truncated'))).lower()}`

### `git status --short`

```text
{os.linesep.join(status) if status else '(clean or unavailable)'}
```

### `git diff --stat HEAD`

```text
{os.linesep.join(diff_stat) if diff_stat else '(no tracked diff or unavailable)'}
```

## Receiving guidance

1. Read `.director-mode/GUIDANCE.md` if present.
2. Confirm the worktree still matches this snapshot.
3. Continue from the listed next steps; revise them if repository evidence differs.
4. Run relevant verification and leave another packet if a different CLI takes over.
"""


def lineage_for(parent: dict[str, Any] | None, packet_id: str, source: str, target: str) -> dict[str, Any]:
    if parent is None:
        return {
            "root_id": packet_id,
            "parent_id": None,
            "hop": 0,
            "route": [source, target],
        }
    inherited = parent.get("lineage") or {
        "root_id": parent["id"],
        "hop": 0,
        "route": [parent["source"]["cli"], parent["target"]["cli"]],
    }
    route = list(inherited["route"])
    if route[-1] != source:
        route.append(source)
    route.append(target)
    return {
        "root_id": inherited["root_id"],
        "parent_id": parent["id"],
        "hop": int(inherited["hop"]) + 1,
        "route": route,
    }


def create_packet(args: argparse.Namespace) -> int:
    cwd = working_directory(args.cwd)
    if not cwd.is_dir():
        raise RelayError(f"working directory does not exist: {cwd}")
    created_at = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
    parent_value = None if args.parent == "__latest__" else args.parent
    parent = load_packet(resolve_packet(parent_value, cwd)) if args.parent else None
    packet_id = str(uuid4())
    destination = Path(args.output).expanduser() if args.output else handoff_dir(cwd)
    if destination.suffix.lower() == ".json":
        json_path = destination if destination.is_absolute() else cwd / destination
        out_dir = json_path.parent
        stem = json_path.stem
    else:
        out_dir = destination if destination.is_absolute() else cwd / destination
        stamp = created_at.replace(":", "").replace("-", "")
        stem = f"{stamp}-{packet_id[:8]}-{args.source_cli}-to-{args.target_cli}"
        json_path = out_dir / f"{stem}.json"
    out_dir.mkdir(parents=True, exist_ok=True)
    if out_dir.resolve() == handoff_dir(cwd).resolve():
        ignore_path = out_dir / ".gitignore"
        if not ignore_path.exists():
            atomic_write(ignore_path, "*\n!.gitignore\n")
    data = {
        "protocol": PROTOCOL,
        "id": packet_id,
        "created_at": created_at,
        "lineage": lineage_for(parent, packet_id, args.source_cli, args.target_cli),
        "privacy": {
            "capture_mode": "git-metadata-only",
            "raw_transcript_included": False,
            "file_contents_included": False,
            "review_status": "reviewed" if args.reviewed else "unreviewed",
        },
        "source": {"cli": args.source_cli, "session_id": args.session_id},
        "target": {"cli": args.target_cli, "session_id": None},
        "workspace": workspace_snapshot(cwd),
        "task": {
            "goal": args.goal.strip(),
            "summary": args.summary.strip(),
            "in_scope": args.in_scope,
            "out_of_scope": args.out_of_scope,
            "constraints": args.constraint,
            "completed": args.completed,
            "decisions": args.decision,
            "next_steps": args.next_steps,
            "verification": args.verification,
            "blockers": args.blocker,
            "notes": args.note,
        },
    }
    validate_packet(data)
    markdown_path = out_dir / f"{stem}.md"
    json_text = json.dumps(data, indent=2, ensure_ascii=False) + "\n"
    markdown_text = render_markdown(data)
    atomic_write(json_path, json_text)
    atomic_write(markdown_path, markdown_text)
    atomic_write(out_dir / "latest.json", json_text)
    atomic_write(out_dir / "latest.md", markdown_text)
    print(json_path)
    print(markdown_path)
    return 0


def prompt_for(packet_path: Path) -> str:
    display = str(packet_path.resolve())
    return (
        f"Continue the existing task from the Director Mode handoff packet at {display}. "
        "Read it first, inspect the current worktree, preserve recorded decisions unless repository evidence conflicts, "
        "then complete the next steps and run the listed verification. Keep this CLI's native approval and sandbox settings."
    )


def command_for(cli: str, prompt: str, headless: bool) -> list[str]:
    if headless:
        return {
            "claude": ["claude", "-p", prompt],
            "codex": ["codex", "exec", prompt],
            "grok": ["grok", "--no-auto-update", "-p", prompt],
        }[cli]
    return {
        "claude": ["claude", prompt],
        "codex": ["codex", prompt],
        "grok": ["grok", prompt],
    }[cli]


def continue_packet(args: argparse.Namespace) -> int:
    cwd = working_directory(args.cwd)
    packet_path = resolve_packet(args.packet, cwd)
    data = load_packet(packet_path)
    cli = args.target_cli or data["target"]["cli"]
    command = command_for(cli, prompt_for(packet_path), args.headless)
    print(shlex.join(command))
    if not args.run:
        return 0
    if shutil.which(command[0]) is None:
        raise RelayError(f"target CLI is not installed or not on PATH: {command[0]}")
    # Packet paths are evidence from another session or machine, not trusted
    # launch instructions. Continue in the caller's live project instead.
    run_cwd = project_root(cwd)
    return subprocess.run(command, cwd=run_cwd, check=False).returncode


def status_packet(args: argparse.Namespace) -> int:
    cwd = working_directory(args.cwd)
    path = resolve_packet(args.packet, cwd)
    data = load_packet(path)
    captured = data["workspace"]
    live = workspace_snapshot(project_root(cwd))

    def matches(field: str) -> bool | None:
        before, after = captured.get(field), live.get(field)
        return None if before is None or after is None else before == after

    report = {
        "protocol": data["protocol"],
        "packet": str(path),
        "source": data["source"]["cli"],
        "target": data["target"]["cli"],
        "review_status": data["privacy"]["review_status"],
        "target_cli_available": shutil.which(data["target"]["cli"]) is not None,
        "drift": {
            "branch_matches": matches("branch"),
            "head_matches": matches("head"),
            "status_matches": captured.get("status") == live.get("status"),
            "diff_stat_matches": captured.get("diff_stat") == live.get("diff_stat"),
        },
        "captured": captured,
        "live": live,
    }
    if args.json:
        print(json.dumps(report, indent=2, ensure_ascii=False))
    else:
        drift = report["drift"]
        print(f"packet: {path}")
        print(f"route: {report['source']} -> {report['target']}")
        print(f"review: {report['review_status']}")
        print(f"target CLI available: {str(report['target_cli_available']).lower()}")
        print(f"branch matches: {drift['branch_matches']}")
        print(f"HEAD matches: {drift['head_matches']}")
        print(f"worktree status matches: {drift['status_matches']}")
        print(f"diff stat matches: {drift['diff_stat_matches']}")
    return 0


def show_packet(args: argparse.Namespace) -> int:
    cwd = working_directory(args.cwd)
    path = resolve_packet(args.packet, cwd)
    data = load_packet(path)
    if args.json:
        print(json.dumps(data, indent=2, ensure_ascii=False))
    else:
        print(render_markdown(data), end="")
    return 0


def validate_command(args: argparse.Namespace) -> int:
    path = resolve_packet(args.packet, working_directory(args.cwd))
    data = load_packet(path)
    print(f"valid {data['protocol']}: {path}")
    return 0


def list_packets(args: argparse.Namespace) -> int:
    directory = handoff_dir(working_directory(args.cwd))
    if not directory.is_dir():
        return 0
    for path in sorted(directory.glob("*.json"), reverse=True):
        if path.name != "latest.json":
            print(path)
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--cwd",
        default=None,
        help="project directory (default: DIRECTOR_PROJECT_DIR or current directory)",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    create = subparsers.add_parser("create", help="create JSON and Markdown handoff packets")
    create.add_argument("--from", dest="source_cli", choices=CLIS, required=True)
    create.add_argument("--to", dest="target_cli", choices=CLIS, required=True)
    create.add_argument("--session-id")
    create.add_argument(
        "--parent",
        nargs="?",
        const="__latest__",
        help="link this packet to a prior relay packet (defaults to latest when flag is present)",
    )
    create.add_argument("--goal", required=True)
    create.add_argument("--summary", required=True)
    create.add_argument("--in-scope", action="append", default=[])
    create.add_argument("--out-of-scope", action="append", default=[])
    create.add_argument("--constraint", action="append", default=[])
    create.add_argument("--completed", action="append", default=[])
    create.add_argument("--decision", action="append", default=[])
    create.add_argument("--next", dest="next_steps", action="append", default=[])
    create.add_argument("--verification", action="append", default=[])
    create.add_argument("--blocker", action="append", default=[])
    create.add_argument("--note", action="append", default=[])
    create.add_argument(
        "--reviewed",
        action="store_true",
        help="record that the user-supplied text and captured path metadata were reviewed before sharing",
    )
    create.add_argument("--output", help="output directory or explicit .json path")
    create.set_defaults(handler=create_packet)

    for name in ("continue", "command"):
        command = subparsers.add_parser(name, help="print or launch the receiving CLI command")
        command.add_argument("packet", nargs="?")
        command.add_argument("--to", dest="target_cli", choices=CLIS)
        command.add_argument("--headless", action="store_true")
        command.add_argument("--run", action="store_true")
        command.set_defaults(handler=continue_packet)

    show = subparsers.add_parser("show", help="render a packet")
    show.add_argument("packet", nargs="?")
    show.add_argument("--json", action="store_true")
    show.set_defaults(handler=show_packet)

    validate = subparsers.add_parser("validate", help="validate a packet")
    validate.add_argument("packet", nargs="?")
    validate.set_defaults(handler=validate_command)

    status = subparsers.add_parser("status", help="compare a packet with the live worktree")
    status.add_argument("packet", nargs="?")
    status.add_argument("--json", action="store_true")
    status.set_defaults(handler=status_packet)

    listing = subparsers.add_parser("list", help="list local packets")
    listing.set_defaults(handler=list_packets)
    return parser


def main() -> int:
    try:
        args = build_parser().parse_args()
        return args.handler(args)
    except RelayError as exc:
        print(f"director-relay: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
