#!/usr/bin/env python3
"""Install Director Mode's shared guidance into native three-CLI surfaces."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import shutil
import stat
import sys
from typing import Any

from install_safety import UnsafeManagedPath, assert_safe_managed_files

MARKER_START = "<!-- director-mode-lite:start -->"
MARKER_END = "<!-- director-mode-lite:end -->"
ADVISORY_ASSET = ".director-mode/hooks/advisory.sh"
GUIDANCE_BLOCK = f"""{MARKER_START}
## Director Mode Lite (guidance)

For substantial work, read `.director-mode/GUIDANCE.md`. It offers a concise
brief, verification checklist, and portable Claude/Codex/Grok handoff format.
It never adds a permission gate, denial rule, or forced workflow. Use this
CLI's native permission mode and approvals according to the user's choice.
{MARKER_END}
"""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", required=True)
    parser.add_argument("--target", required=True)
    parser.add_argument("--cli", choices=("claude", "codex", "grok", "all"), default="all")
    parser.add_argument("--hooks", choices=("guide", "none", "automation"), default="none")
    parser.add_argument("--update", action="store_true")
    return parser.parse_args()


def copy_file(
    source: Path,
    target: Path,
    *,
    update: bool,
    executable: bool = False,
) -> None:
    if target.exists() and not update:
        return
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, target)
    if executable:
        target.chmod(target.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)


def copy_tree(source: Path, target: Path, *, update: bool) -> None:
    if target.exists() and not update:
        return
    target.mkdir(parents=True, exist_ok=True)
    for item in sorted(source.rglob("*")):
        if item.is_symlink():
            raise RuntimeError(f"source skill contains a symlink: {item}")
        destination = target / item.relative_to(source)
        if item.is_dir():
            destination.mkdir(parents=True, exist_ok=True)
        elif item.is_file():
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(item, destination)


def managed_guidance(path: Path) -> None:
    if path.exists():
        text = path.read_text(encoding="utf-8")
        if MARKER_START in text:
            updated = re.sub(
                re.escape(MARKER_START) + r".*?" + re.escape(MARKER_END),
                GUIDANCE_BLOCK.strip(),
                text,
                flags=re.DOTALL,
            )
        else:
            updated = text.rstrip() + "\n\n" + GUIDANCE_BLOCK
    else:
        title = "# Repository guidance\n\n"
        updated = title + GUIDANCE_BLOCK
    path.write_text(updated.rstrip() + "\n", encoding="utf-8")


def read_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"cannot merge invalid JSON file {path}: {exc}") from exc
    if not isinstance(data, dict):
        raise RuntimeError(f"cannot merge non-object JSON file {path}")
    return data


def references_advisory(command: Any) -> bool:
    if not isinstance(command, str):
        return False
    normalized = command.replace("\\", "/")
    pattern = rf"(?<![A-Za-z0-9._-]){re.escape(ADVISORY_ASSET)}(?![A-Za-z0-9._/-])"
    return re.search(pattern, normalized) is not None


def same_hook(entry: Any) -> bool:
    if not isinstance(entry, dict):
        return False
    if references_advisory(entry.get("command")):
        return True
    return any(
        references_advisory(hook.get("command"))
        for hook in entry.get("hooks", [])
        if isinstance(hook, dict)
    )


def merge_hook(path: Path, entry: dict[str, Any]) -> None:
    data = read_json(path)
    hooks = data.setdefault("hooks", {})
    session_start = hooks.setdefault("SessionStart", [])
    if not any(same_hook(item) for item in session_start):
        session_start.append(entry)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def quoted(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def frontmatter_value(frontmatter: str, key: str) -> str:
    direct = re.search(rf"(?m)^{re.escape(key)}:\s*([^|>\n].*)$", frontmatter)
    if direct:
        return direct.group(1).strip().strip('"\'')
    block = re.search(
        rf"(?ms)^{re.escape(key)}:\s*[|>][-+]?\s*\n(?P<body>(?:[ \t]+.*(?:\n|$))*)",
        frontmatter,
    )
    if not block:
        return ""
    lines = [line.strip() for line in block.group("body").splitlines()]
    return " ".join(line for line in lines if line)


def agent_parts(source: Path) -> tuple[str, str, str]:
    text = source.read_text(encoding="utf-8")
    match = re.match(r"^---\s*\n(?P<front>.*?)\n---\s*\n(?P<body>.*)$", text, flags=re.DOTALL)
    if not match:
        raise RuntimeError(f"agent has no valid frontmatter: {source}")
    front = match.group("front")
    name = frontmatter_value(front, "name") or source.stem
    description = frontmatter_value(front, "description") or f"Director Mode {name} agent"
    body = match.group("body").strip()
    return name, description, body


def convert_codex_agent(source: Path, target: Path) -> None:
    name, description, body = agent_parts(source)
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(
        f"name = {quoted(name)}\n"
        f"description = {quoted(description)}\n"
        f"developer_instructions = {quoted(body)}\n",
        encoding="utf-8",
    )


def convert_grok_agent(source: Path, target: Path) -> None:
    """Generate a minimal native Grok agent from the canonical Markdown body.

    Grok reads Claude agents, but Claude-only frontmatter such as model aliases,
    memory scopes, maxTurns, and tool names is not portable across every Grok
    release. A small native adapter preserves the role without importing those
    runtime controls.
    """
    name, description, body = agent_parts(source)
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(
        "---\n"
        f"name: {quoted(name)}\n"
        f"description: {quoted(description)}\n"
        "---\n\n"
        f"{body}\n",
        encoding="utf-8",
    )


def selected(cli: str, name: str) -> bool:
    return cli == "all" or cli == name


def portable_destinations(source: Path, cli: str, hooks: str) -> set[str]:
    paths = {
        "CLAUDE.md",
        "AGENTS.md",
        ".director-mode/GUIDANCE.md",
        ".director-mode/handoff.schema.json",
        ".director-mode/bin/director-relay",
        ".director-mode/bin/director-open",
        ".director-mode/bin/director-doctor",
        ".director-mode/handoffs/.gitignore",
    }
    if hooks != "none":
        paths.add(ADVISORY_ASSET)
    if hooks != "none" and selected(cli, "claude"):
        paths.add(".claude/settings.local.json")
    if hooks != "none" and selected(cli, "codex"):
        paths.add(".codex/hooks.json")

    if selected(cli, "codex"):
        for item in (source / "skills").rglob("*"):
            if item.is_file():
                relative = item.relative_to(source / "skills").as_posix()
                paths.add(f".agents/skills/{relative}")
        for agent in (source / "agents").glob("*.md"):
            paths.add(f".codex/agents/{agent.stem}.toml")

    if selected(cli, "grok"):
        for agent in (source / "agents").glob("*.md"):
            paths.add(f".grok/agents/{agent.name}")
    return paths


def install() -> None:
    args = parse_args()
    source = Path(args.source).expanduser().resolve()
    target = Path(args.target).expanduser().resolve()
    if not source.is_dir() or not target.is_dir():
        raise RuntimeError("source and target must be existing directories")
    assert_safe_managed_files(
        target, portable_destinations(source, args.cli, args.hooks)
    )

    runtime = target / ".director-mode"
    copy_file(source / "portable" / "GUIDANCE.md", runtime / "GUIDANCE.md", update=args.update)
    copy_file(
        source / "portable" / "handoff.schema.json",
        runtime / "handoff.schema.json",
        update=args.update,
    )
    copy_file(
        source / "scripts" / "director-relay.py",
        runtime / "bin" / "director-relay",
        update=args.update,
        executable=True,
    )
    copy_file(
        source / "scripts" / "director-open.sh",
        runtime / "bin" / "director-open",
        update=args.update,
        executable=True,
    )
    copy_file(
        source / "scripts" / "director-doctor.py",
        runtime / "bin" / "director-doctor",
        update=args.update,
        executable=True,
    )
    if args.hooks != "none":
        copy_file(
            source / "hooks" / "advisory.sh",
            runtime / "hooks" / "advisory.sh",
            update=args.update,
            executable=True,
        )
    handoffs = runtime / "handoffs"
    handoffs.mkdir(parents=True, exist_ok=True)
    handoff_ignore = handoffs / ".gitignore"
    if args.update or not handoff_ignore.exists():
        handoff_ignore.write_text("*\n!.gitignore\n", encoding="utf-8")

    managed_guidance(target / "CLAUDE.md")
    managed_guidance(target / "AGENTS.md")

    # Skills remain shared through native compatibility. Agents need small
    # adapters because Claude-only model/tool/memory frontmatter is not
    # portable across every Grok release.
    if selected(args.cli, "codex"):
        shared_skills = target / ".agents" / "skills"
        for skill in sorted((source / "skills").iterdir()):
            if skill.is_dir() and (skill / "SKILL.md").is_file():
                copy_tree(skill, shared_skills / skill.name, update=args.update)
        for agent in sorted((source / "agents").glob("*.md")):
            destination = target / ".codex" / "agents" / f"{agent.stem}.toml"
            if args.update or not destination.exists():
                convert_codex_agent(agent, destination)

    if selected(args.cli, "grok"):
        for agent in sorted((source / "agents").glob("*.md")):
            destination = target / ".grok" / "agents" / agent.name
            if args.update or not destination.exists():
                convert_grok_agent(agent, destination)

    if args.hooks != "none":
        if selected(args.cli, "claude"):
            merge_hook(
                target / ".claude" / "settings.local.json",
                {
                    "matcher": "startup|resume|clear|compact",
                    "hooks": [{
                        "type": "command",
                        "command": 'root="${CLAUDE_PROJECT_DIR:-}"; [ -n "$root" ] || root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"; bash "$root/.director-mode/hooks/advisory.sh" claude',
                    }],
                },
            )
        if selected(args.cli, "codex"):
            merge_hook(
                target / ".codex" / "hooks.json",
                {
                    "matcher": "startup|resume|clear|compact",
                    "hooks": [{
                        "type": "command",
                        "command": 'root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"; bash "$root/.director-mode/hooks/advisory.sh" codex',
                    }],
                },
            )
        # Grok ignores stdout from passive SessionStart hooks. Installing an
        # inert adapter would add latency without context, so Grok reads the
        # same guidance through AGENTS.md and receives no hook registration.

    print(f"  Shared guidance: {runtime / 'GUIDANCE.md'}")
    print(f"  Session relay:   {runtime / 'bin' / 'director-relay'}")
    print(f"  Open launcher:   {runtime / 'bin' / 'director-open'}")
    print(f"  Read-only doctor:{runtime / 'bin' / 'director-doctor'}")
    if selected(args.cli, "codex"):
        print("  Codex adapters:  .agents/skills + .codex/agents")
    if selected(args.cli, "grok"):
        print("  Grok adapters:   shared skills + native .grok/agents (no inert passive hook)")
    print(f"  Hook mode:       {args.hooks} (none by default; guide is non-blocking)")


if __name__ == "__main__":
    try:
        install()
    except (OSError, RuntimeError, UnsafeManagedPath) as exc:
        print(f"install-portable: {exc}", file=sys.stderr)
        raise SystemExit(1)
