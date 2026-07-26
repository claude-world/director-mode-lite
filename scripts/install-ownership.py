#!/usr/bin/env python3
"""Track Director Mode files so uninstall never deletes pre-existing assets."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import sys
from typing import Any


MANIFEST = Path(".director-mode/install-ownership.json")
PENDING = Path(".director-mode/.install-ownership-pending.json")


def arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    begin = subparsers.add_parser("begin")
    begin.add_argument("--source", required=True)
    begin.add_argument("--target", required=True)
    begin.add_argument("--cli", choices=("all", "claude", "codex", "grok"), default="all")
    begin.add_argument("--hooks", choices=("none", "guide", "automation"), default="none")

    finalize = subparsers.add_parser("finalize")
    finalize.add_argument("--target", required=True)

    remove = subparsers.add_parser("remove")
    remove.add_argument("--target", required=True)
    remove.add_argument(
        "--hooks-only",
        action="store_true",
        help="remove only owned hook executables and retain the rest of the manifest",
    )
    return parser.parse_args()


def digest(path: Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            value.update(chunk)
    return value.hexdigest()


def read_object(path: Path) -> dict[str, Any]:
    if not path.is_file():
        return {}
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}
    return value if isinstance(value, dict) else {}


def selected(cli: str, name: str) -> bool:
    return cli == "all" or cli == name


def add_tree(candidates: set[str], source: Path, destination: PurePosixPath) -> None:
    if not source.is_dir():
        return
    for item in source.rglob("*"):
        if item.is_file():
            candidates.add(str(destination / PurePosixPath(item.relative_to(source).as_posix())))


def inventory(source: Path, cli: str, hooks: str) -> list[str]:
    candidates = {
        "CLAUDE.md",
        "AGENTS.md",
        ".director-mode/GUIDANCE.md",
        ".director-mode/handoff.schema.json",
        ".director-mode/bin/director-relay",
        ".director-mode/bin/director-open",
        ".director-mode/handoffs/.gitignore",
    }
    if hooks != "none":
        candidates.add(".director-mode/hooks/advisory.sh")

    add_tree(candidates, source / "agents", PurePosixPath(".claude/agents"))
    add_tree(candidates, source / "skills", PurePosixPath(".claude/skills"))

    if selected(cli, "codex"):
        add_tree(candidates, source / "skills", PurePosixPath(".agents/skills"))
        for agent in (source / "agents").glob("*.md"):
            candidates.add(f".codex/agents/{agent.stem}.toml")

    if selected(cli, "grok"):
        for agent in (source / "agents").glob("*.md"):
            candidates.add(f".grok/agents/{agent.name}")

    if hooks == "automation":
        for name in (
            "_lib-changelog.sh",
            "auto-loop-stop.sh",
            "log-bash-event.sh",
            "log-file-change.sh",
            "pre-tool-validator.sh",
        ):
            candidates.add(f".claude/hooks/{name}")
        add_tree(
            candidates,
            source / ".self-evolving-loop" / "hooks",
            PurePosixPath(".self-evolving-loop/hooks"),
        )
        add_tree(
            candidates,
            source / ".self-evolving-loop" / "templates",
            PurePosixPath(".self-evolving-loop/templates"),
        )

    return sorted(candidates)


def safe_relative(value: str) -> Path | None:
    pure = PurePosixPath(value)
    if pure.is_absolute() or not pure.parts or ".." in pure.parts:
        return None
    return Path(*pure.parts)


def begin(args: argparse.Namespace) -> None:
    source = Path(args.source).expanduser().resolve()
    target = Path(args.target).expanduser().resolve()
    manifest_path = target / MANIFEST
    prior = read_object(manifest_path).get("files", {})
    if not isinstance(prior, dict):
        prior = {}

    entries: dict[str, dict[str, bool]] = {}
    for relative in inventory(source, args.cli, args.hooks):
        path = target / relative
        entries[relative] = {
            "existed_before": path.is_file(),
            "owned_before": relative in prior,
        }

    pending_path = target / PENDING
    pending_path.parent.mkdir(parents=True, exist_ok=True)
    pending_path.write_text(
        json.dumps({"version": 1, "prior": prior, "candidates": entries}, indent=2) + "\n",
        encoding="utf-8",
    )


def finalize(args: argparse.Namespace) -> None:
    target = Path(args.target).expanduser().resolve()
    pending_path = target / PENDING
    pending = read_object(pending_path)
    candidates = pending.get("candidates")
    if not isinstance(candidates, dict):
        raise RuntimeError(f"ownership snapshot missing: {pending_path}")

    prior = pending.get("prior", {})
    files: dict[str, dict[str, str]] = {}
    if isinstance(prior, dict):
        for relative, metadata in prior.items():
            safe = safe_relative(relative)
            if safe is not None and isinstance(metadata, dict) and (target / safe).is_file():
                files[relative] = metadata

    for relative, state in candidates.items():
        safe = safe_relative(relative)
        if safe is None or not isinstance(state, dict):
            continue
        path = target / safe
        if not path.is_file():
            continue
        if state.get("owned_before") or not state.get("existed_before"):
            files[relative] = {"sha256": digest(path)}

    manifest_path = target / MANIFEST
    manifest_path.write_text(
        json.dumps({"version": 1, "files": dict(sorted(files.items()))}, indent=2) + "\n",
        encoding="utf-8",
    )
    pending_path.unlink(missing_ok=True)


def remove(args: argparse.Namespace) -> None:
    target = Path(args.target).expanduser().resolve()
    manifest_path = target / MANIFEST
    manifest = read_object(manifest_path)
    files = manifest.get("files", {})
    if not isinstance(files, dict):
        files = {}

    removed = 0
    preserved = 0
    parents: set[Path] = set()
    remaining = dict(files)
    for relative, metadata in sorted(files.items(), key=lambda item: item[0].count("/"), reverse=True):
        if args.hooks_only and not relative.startswith((".claude/hooks/", ".director-mode/hooks/")):
            continue
        safe = safe_relative(relative)
        if safe is None or not isinstance(metadata, dict):
            preserved += 1
            continue
        path = target / safe
        if not path.exists():
            continue
        expected = metadata.get("sha256")
        if path.is_file() and isinstance(expected, str) and digest(path) == expected:
            path.unlink()
            parents.add(path.parent)
            removed += 1
        else:
            print(f"  Preserved modified or non-regular asset: {relative}")
            preserved += 1
        remaining.pop(relative, None)

    if args.hooks_only:
        manifest_path.write_text(
            json.dumps({"version": 1, "files": dict(sorted(remaining.items()))}, indent=2) + "\n",
            encoding="utf-8",
        )
    else:
        manifest_path.unlink(missing_ok=True)
        pending_path = target / PENDING
        pending_path.unlink(missing_ok=True)
    for directory in sorted(parents, key=lambda value: len(value.parts), reverse=True):
        current = directory
        while current != target and current.exists():
            try:
                current.rmdir()
            except OSError:
                break
            current = current.parent
    print(f"  Ownership cleanup: removed {removed}, preserved {preserved}")


def main() -> None:
    args = arguments()
    if args.command == "begin":
        begin(args)
    elif args.command == "finalize":
        finalize(args)
    else:
        remove(args)


if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError) as exc:
        print(f"install-ownership: {exc}", file=sys.stderr)
        raise SystemExit(1)
