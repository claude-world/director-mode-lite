#!/usr/bin/env python3
"""Remove or detect only Director Mode hook registrations and assets."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path, PurePosixPath
import re
import sys
import tempfile
from typing import Any


CONFIG_PATHS = (
    Path(".claude/settings.json"),
    Path(".claude/settings.local.json"),
    Path(".codex/hooks.json"),
)

OWNED_HOOK_PREFIXES = (
    ".director-mode/hooks/",
    ".claude/hooks/",
    ".self-evolving-loop/hooks/",
)

OWNERSHIP_MANIFEST = Path(".director-mode/install-ownership.json")
ADVISORY_ASSET = ".director-mode/hooks/advisory.sh"


class HookConfigError(RuntimeError):
    """A hook configuration cannot be inspected without risking user data."""


def arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    for name in ("prune", "check-none"):
        command = subparsers.add_parser(name)
        command.add_argument("--target", required=True)
    advisory = subparsers.add_parser("check-advisory")
    advisory.add_argument("--config", required=True)
    return parser.parse_args()


def read_object(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise HookConfigError(f"invalid JSON in {path}: {exc}") from exc
    if not isinstance(value, dict):
        raise HookConfigError(f"hook configuration is not an object: {path}")
    return value


def atomic_json_write(path: Path, value: dict[str, Any]) -> None:
    descriptor, temporary_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    temporary = Path(temporary_name)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            json.dump(value, handle, indent=2)
            handle.write("\n")
            handle.flush()
            os.fsync(handle.fileno())
        temporary.chmod(path.stat().st_mode)
        os.replace(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)


def references_asset(command: Any, relative: str) -> bool:
    if not isinstance(command, str):
        return False
    normalized = command.replace("\\", "/")
    pattern = rf"(?<![A-Za-z0-9._-]){re.escape(relative)}(?![A-Za-z0-9._/-])"
    return re.search(pattern, normalized) is not None


def is_director_command(command: Any, owned_assets: set[str]) -> bool:
    # The .director-mode namespace is product-specific and safe to match exactly.
    # Generic legacy .claude/hooks filenames count only when the ownership
    # manifest proves that this installation created them.
    candidates = owned_assets | {ADVISORY_ASSET}
    return any(references_asset(command, relative) for relative in candidates)


def prune_hook_data(data: dict[str, Any], path: Path, owned_assets: set[str]) -> int:
    """Remove Director commands while retaining custom commands in mixed entries."""

    hooks = data.get("hooks")
    if hooks is None:
        return 0
    if not isinstance(hooks, dict):
        raise HookConfigError(f"hooks is not an object in {path}")

    removed = 0
    for event in list(hooks):
        entries = hooks[event]
        if not isinstance(entries, list):
            raise HookConfigError(f"hooks.{event} is not a list in {path}")

        kept_entries: list[Any] = []
        for entry in entries:
            if not isinstance(entry, dict):
                kept_entries.append(entry)
                continue

            if is_director_command(entry.get("command"), owned_assets):
                removed += 1
                continue

            commands = entry.get("hooks")
            if commands is None:
                kept_entries.append(entry)
                continue
            if not isinstance(commands, list):
                raise HookConfigError(
                    f"hooks.{event} entry hooks is not a list in {path}"
                )

            kept_commands: list[Any] = []
            removed_from_entry = 0
            for command in commands:
                if isinstance(command, dict) and is_director_command(
                    command.get("command"), owned_assets
                ):
                    removed += 1
                    removed_from_entry += 1
                else:
                    kept_commands.append(command)

            if kept_commands:
                entry["hooks"] = kept_commands
                kept_entries.append(entry)
            elif removed_from_entry == 0:
                kept_entries.append(entry)

        if kept_entries:
            hooks[event] = kept_entries
        else:
            del hooks[event]

    if not hooks:
        data.pop("hooks", None)
    return removed


def prune_config(path: Path, owned_assets: set[str]) -> int:
    if not path.is_file():
        return 0
    data = read_object(path)
    removed = prune_hook_data(data, path, owned_assets)
    if removed == 0:
        return 0
    if data:
        atomic_json_write(path, data)
    else:
        path.unlink()
    return removed


def director_commands(value: Any, owned_assets: set[str]) -> list[str]:
    found: list[str] = []
    if isinstance(value, dict):
        command = value.get("command")
        if is_director_command(command, owned_assets):
            found.append(command)
        for nested in value.values():
            found.extend(director_commands(nested, owned_assets))
    elif isinstance(value, list):
        for nested in value:
            found.extend(director_commands(nested, owned_assets))
    return found


def owned_hook_assets(target: Path) -> set[str]:
    assets: set[str] = set()
    manifest_path = target / OWNERSHIP_MANIFEST
    if not manifest_path.is_file():
        return assets
    manifest = read_object(manifest_path)
    files = manifest.get("files", {})
    if not isinstance(files, dict):
        raise HookConfigError(f"files is not an object in {manifest_path}")
    for relative in files:
        pure = PurePosixPath(relative) if isinstance(relative, str) else None
        if (
            pure is not None
            and not pure.is_absolute()
            and ".." not in pure.parts
            and relative.startswith(OWNED_HOOK_PREFIXES)
            and (target / relative).exists()
        ):
            assets.add(relative)
    return assets


def config_paths(target: Path) -> list[Path]:
    paths = [relative for relative in CONFIG_PATHS if (target / relative).is_file()]
    grok_hooks = target / ".grok" / "hooks"
    if grok_hooks.is_dir():
        paths.extend(
            path.relative_to(target)
            for path in sorted(grok_hooks.glob("*.json"))
            if path.is_file()
        )
    grok_flat = Path(".grok/hooks.json")
    if (target / grok_flat).is_file():
        paths.append(grok_flat)
    return list(dict.fromkeys(paths))


def check_none(target: Path) -> list[str]:
    issues: list[str] = []
    assets = owned_hook_assets(target)
    for relative in config_paths(target):
        path = target / relative
        data = read_object(path)
        for command in director_commands(data, assets):
            issues.append(f"{relative}: {command}")
    for relative in sorted(assets):
        issues.append(f"owned hook asset remains: {relative}")
    return issues


def has_advisory(path: Path) -> bool:
    return any(references_asset(command, ADVISORY_ASSET) for command in all_commands(read_object(path)))


def all_commands(value: Any) -> list[str]:
    found: list[str] = []
    if isinstance(value, dict):
        command = value.get("command")
        if isinstance(command, str):
            found.append(command)
        for nested in value.values():
            found.extend(all_commands(nested))
    elif isinstance(value, list):
        for nested in value:
            found.extend(all_commands(nested))
    return found


def main() -> int:
    args = arguments()
    if args.command == "check-advisory":
        path = Path(args.config).expanduser().resolve()
        if not path.is_file():
            print(f"advisory configuration not found: {path}", file=sys.stderr)
            return 1
        if has_advisory(path):
            print("exact Director advisory registration found")
            return 0
        print(f"exact Director advisory registration not found: {path}", file=sys.stderr)
        return 1

    target = Path(args.target).expanduser().resolve()
    if not target.is_dir():
        raise HookConfigError(f"target directory does not exist: {target}")

    if args.command == "prune":
        assets = owned_hook_assets(target)
        removed = sum(
            prune_config(target / relative, assets) for relative in config_paths(target)
        )
        print(f"  Director hook registrations removed: {removed}")
        return 0

    issues = check_none(target)
    if issues:
        for issue in issues:
            print(f"  {issue}", file=sys.stderr)
        return 1
    print("no Director Mode hook registrations or owned hook assets")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, HookConfigError) as exc:
        print(f"director-hooks: {exc}", file=sys.stderr)
        raise SystemExit(1)
