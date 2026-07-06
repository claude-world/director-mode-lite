#!/usr/bin/env python3
"""Deep frontmatter validation for Director Mode Lite.

Enforces the rules that the grep-based CI jobs cannot: real YAML parsing,
user-invocable arithmetic (commands + internal = skills), advertised-count
consistency against plugin.json / marketplace.json, and agent cross-references.

Exit 1 on any ERROR; WARNs never fail the build.
Run locally:  python3 scripts/validate-frontmatter.py
"""
import json
import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("ERROR: PyYAML required (pip install pyyaml)")
    sys.exit(1)

ROOT = Path(__file__).resolve().parent.parent

# Skills that are knowledge bases / auto-triggered, not slash commands
INTERNAL_SKILLS = {"code-reviewer", "debugger", "doc-writer", "test-runner", "interop-router"}

VALID_MODELS = {"inherit", "default", "best", "fable", "opus", "sonnet", "haiku",
                "opus[1m]", "sonnet[1m]"}
VALID_COLORS = {"yellow", "red", "green", "blue", "magenta", "cyan"}
VALID_MEMORY = {"user", "project", "local"}
AGENT_UNSUPPORTED = {"hooks", "mcpServers", "permissionMode", "forkContext"}

errors, warnings = [], []


def err(msg): errors.append(msg)
def warn(msg): warnings.append(msg)


def frontmatter(path: Path):
    text = path.read_text(encoding="utf-8")
    m = re.match(r"^---\n(.*?)\n---\n", text, re.DOTALL)
    if not m:
        err(f"{path}: no frontmatter block")
        return None
    try:
        fm = yaml.safe_load(m.group(1))
    except yaml.YAMLError as e:
        err(f"{path}: YAML parse error: {e}")
        return None
    if not isinstance(fm, dict):
        err(f"{path}: frontmatter is not a mapping")
        return None
    return fm


def check_skills():
    invocable = []
    skill_names = set()
    for d in sorted((ROOT / "skills").iterdir()):
        if not d.is_dir():
            continue
        f = d / "SKILL.md"
        if not f.exists():
            err(f"{d}: missing SKILL.md")
            continue
        fm = frontmatter(f)
        if fm is None:
            continue
        name = fm.get("name")
        skill_names.add(d.name)
        if name != d.name:
            err(f"{f}: name '{name}' != directory '{d.name}'")
        if name and not re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", str(name)):
            err(f"{f}: invalid name format '{name}'")
        desc = fm.get("description")
        if not desc:
            err(f"{f}: missing description")
        elif not (20 <= len(str(desc)) <= 1024):
            err(f"{f}: description length {len(str(desc))} outside 20-1024")
        ui = fm.get("user-invocable")
        if not isinstance(ui, bool):
            err(f"{f}: user-invocable must be explicitly true or false "
                f"(count integrity depends on it), got: {ui!r}")
        else:
            expected = d.name not in INTERNAL_SKILLS
            if ui is not expected:
                err(f"{f}: user-invocable is {ui} but {d.name} is "
                    f"{'not ' if expected else ''}an internal skill")
            if ui:
                invocable.append(d.name)
        tools = fm.get("allowed-tools")
        if tools is not None and not (
            isinstance(tools, str)
            or (isinstance(tools, list) and all(isinstance(t, str) for t in tools))
        ):
            err(f"{f}: allowed-tools must be a string or list of strings")
        model = fm.get("model")
        if model is not None and str(model) not in VALID_MODELS:
            err(f"{f}: invalid model '{model}'")
        lines = f.read_text().count("\n") + 1
        if lines > 500:
            warn(f"{f}: {lines} lines (recommend <500)")
    return skill_names, invocable


def check_agents(skill_names):
    count = 0
    for f in sorted((ROOT / "agents").glob("*.md")):
        count += 1
        fm = frontmatter(f)
        if fm is None:
            continue
        if fm.get("name") != f.stem:
            err(f"{f}: name '{fm.get('name')}' != filename '{f.stem}'")
        desc = str(fm.get("description") or "")
        if not desc:
            err(f"{f}: missing description")
        elif not (10 <= len(desc) <= 5000):
            err(f"{f}: description length {len(desc)} outside 10-5000")
        elif "use " not in desc.lower():
            warn(f"{f}: description has no 'Use ...' trigger clause")
        if fm.get("color") not in VALID_COLORS:
            err(f"{f}: invalid color '{fm.get('color')}'")
        if str(fm.get("model")) not in VALID_MODELS:
            err(f"{f}: invalid model '{fm.get('model')}'")
        tools = fm.get("tools")
        if not (isinstance(tools, list) and all(isinstance(t, str) for t in tools)):
            err(f"{f}: tools must be a YAML list of strings (house convention)")
        mem = fm.get("memory")
        if mem is not None and not (
            isinstance(mem, list) and set(mem) <= VALID_MEMORY
        ):
            err(f"{f}: memory must be a list from {sorted(VALID_MEMORY)}")
        mt = fm.get("maxTurns")
        if mt is not None and not (isinstance(mt, int) and mt > 0):
            err(f"{f}: maxTurns must be a positive integer")
        for s in fm.get("skills") or []:
            if s not in skill_names:
                err(f"{f}: skills references '{s}' but skills/{s}/ does not exist")
        for bad in AGENT_UNSUPPORTED & fm.keys():
            warn(f"{f}: '{bad}' is not supported in filesystem/plugin agent "
                 f"frontmatter — remove it")
    return count


def check_advertised_counts(n_commands, n_agents, n_skills):
    pattern = re.compile(r"(\d+)\s+commands?,\s*(\d+)\s+agents?,\s*(\d+)\s+skills?", re.I)
    for rel in (".claude-plugin/plugin.json", ".claude-plugin/marketplace.json"):
        p = ROOT / rel
        data = json.loads(p.read_text())
        blobs = [data.get("description", "")]
        blobs += [pl.get("description", "") for pl in data.get("plugins", [])]
        for blob in blobs:
            m = pattern.search(blob)
            if not m:
                continue
            claimed = tuple(int(x) for x in m.groups())
            actual = (n_commands, n_agents, n_skills)
            if claimed != actual:
                err(f"{rel}: advertises {claimed[0]} commands / {claimed[1]} agents / "
                    f"{claimed[2]} skills but reality is {actual[0]} / {actual[1]} / {actual[2]}")


def main():
    skill_names, invocable = check_skills()
    n_agents = check_agents(skill_names)
    n_skills = len(skill_names)
    n_commands = len(invocable)
    n_internal = n_skills - n_commands
    check_advertised_counts(n_commands, n_agents, n_skills)

    print(f"Computed: {n_commands} commands + {n_internal} internal = "
          f"{n_skills} skills · {n_agents} agents")
    for w in warnings:
        print(f"  WARN: {w}")
    if errors:
        for e in errors:
            print(f"  ERROR: {e}")
        print(f"\nFAIL: {len(errors)} error(s), {len(warnings)} warning(s)")
        return 1
    print(f"PASS: 0 errors, {len(warnings)} warning(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
