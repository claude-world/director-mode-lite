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
from datetime import datetime, timezone
from typing import Any
from uuid import uuid4

PROTOCOL = "director-handoff/v1"
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
    configured = os.environ.get("DIRECTOR_PROJECT_DIR")
    if configured:
        candidate = Path(configured).expanduser().resolve()
        if candidate.is_dir():
            return candidate
    for candidate in (cwd, *cwd.parents):
        if (candidate / ".director-mode" / "GUIDANCE.md").is_file():
            return candidate
    code, git_root = run_git(cwd, "rev-parse", "--show-toplevel")
    return Path(git_root).resolve() if code == 0 and git_root else cwd


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
    exact_keys(
        data,
        {"protocol", "id", "created_at", "privacy", "source", "target", "workspace", "task"},
        "packet",
    )
    if data.get("protocol") != PROTOCOL:
        raise RelayError(f"unsupported protocol: {data.get('protocol')!r}")
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
    return f"""# Director handoff: {source['cli']} → {target['cli']}

> Protocol: `{data['protocol']}`<br>
> Packet: `{data['id']}`<br>
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


def create_packet(args: argparse.Namespace) -> int:
    cwd = Path(args.cwd).expanduser().resolve()
    if not cwd.is_dir():
        raise RelayError(f"working directory does not exist: {cwd}")
    created_at = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
    data = {
        "protocol": PROTOCOL,
        "id": str(uuid4()),
        "created_at": created_at,
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
    destination = Path(args.output).expanduser() if args.output else handoff_dir(cwd)
    if destination.suffix.lower() == ".json":
        json_path = destination if destination.is_absolute() else cwd / destination
        out_dir = json_path.parent
        stem = json_path.stem
    else:
        out_dir = destination if destination.is_absolute() else cwd / destination
        stamp = created_at.replace(":", "").replace("-", "")
        stem = f"{stamp}-{args.source_cli}-to-{args.target_cli}"
        json_path = out_dir / f"{stem}.json"
    out_dir.mkdir(parents=True, exist_ok=True)
    markdown_path = out_dir / f"{stem}.md"
    json_text = json.dumps(data, indent=2, ensure_ascii=False) + "\n"
    markdown_text = render_markdown(data)
    json_path.write_text(json_text, encoding="utf-8")
    markdown_path.write_text(markdown_text, encoding="utf-8")
    (out_dir / "latest.json").write_text(json_text, encoding="utf-8")
    (out_dir / "latest.md").write_text(markdown_text, encoding="utf-8")
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
    cwd = Path(args.cwd).expanduser().resolve()
    packet_path = resolve_packet(args.packet, cwd)
    data = load_packet(packet_path)
    cli = args.target_cli or data["target"]["cli"]
    command = command_for(cli, prompt_for(packet_path), args.headless)
    print(shlex.join(command))
    if not args.run:
        return 0
    if shutil.which(command[0]) is None:
        raise RelayError(f"target CLI is not installed or not on PATH: {command[0]}")
    workspace = Path(data["workspace"]["path"])
    run_cwd = workspace if workspace.is_dir() else cwd
    return subprocess.run(command, cwd=run_cwd, check=False).returncode


def show_packet(args: argparse.Namespace) -> int:
    cwd = Path(args.cwd).expanduser().resolve()
    path = resolve_packet(args.packet, cwd)
    data = load_packet(path)
    if args.json:
        print(json.dumps(data, indent=2, ensure_ascii=False))
    else:
        print(render_markdown(data), end="")
    return 0


def validate_command(args: argparse.Namespace) -> int:
    path = resolve_packet(args.packet, Path(args.cwd).expanduser().resolve())
    load_packet(path)
    print(f"valid {PROTOCOL}: {path}")
    return 0


def list_packets(args: argparse.Namespace) -> int:
    directory = handoff_dir(Path(args.cwd).expanduser().resolve())
    if not directory.is_dir():
        return 0
    for path in sorted(directory.glob("*.json"), reverse=True):
        if path.name != "latest.json":
            print(path)
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cwd", default=".", help="project directory (default: current directory)")
    subparsers = parser.add_subparsers(dest="command", required=True)

    create = subparsers.add_parser("create", help="create JSON and Markdown handoff packets")
    create.add_argument("--from", dest="source_cli", choices=CLIS, required=True)
    create.add_argument("--to", dest="target_cli", choices=CLIS, required=True)
    create.add_argument("--session-id")
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
