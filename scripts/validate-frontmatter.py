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
INTERNAL_SKILLS = {"code-reviewer", "debugger", "doc-writer", "test-runner"}

# Field lists and values follow the Claude Code 2.1.305 subagent and skill docs.
# Subagent `model`: an alias, a full model ID, or inherit. Skills also take
# every /model value.
AGENT_MODELS = {"inherit", "fable", "opus", "sonnet", "haiku", "opus[1m]", "sonnet[1m]"}
SKILL_MODELS = AGENT_MODELS | {"default", "best", "opusplan"}
FULL_MODEL_ID = re.compile(r"claude-[a-z0-9]+(?:-[a-z0-9]+)*(?:\[1m\])?")
VALID_COLORS = {"red", "blue", "green", "yellow", "purple", "orange", "pink", "cyan"}
VALID_MEMORY = {"user", "project", "local"}
VALID_EFFORT = {"low", "medium", "high", "xhigh", "max"}
VALID_PERMISSION_MODES = {"default", "acceptEdits", "auto", "dontAsk",
                          "bypassPermissions", "plan", "manual"}
AGENT_FIELDS = {"name", "description", "tools", "disallowedTools", "model",
                "permissionMode", "maxTurns", "autoCompactWindow", "skills",
                "mcpServers", "hooks", "memory", "background", "omitClaudeMd",
                "effort", "isolation", "color", "initialPrompt", "experimental"}
# Honored in .claude/agents/, ignored when the agent loads from a plugin.
PLUGIN_IGNORED_AGENT_FIELDS = {"hooks", "mcpServers", "permissionMode", "initialPrompt"}
SKILL_FIELDS = {"name", "description", "when_to_use", "argument-hint", "arguments",
                "disable-model-invocation", "user-invocable", "allowed-tools",
                "disallowed-tools", "model", "effort", "context", "agent",
                "background", "hooks", "paths", "shell", "metadata", "license",
                "compatibility"}
SKILL_LISTING_CAP = 1536  # description + when_to_use, truncated beyond this
BOOL_STRINGS = {"true", "false", "yes", "no", "on", "off", "1", "0"}
CLAUDE_DISPATCH_TOOLS = {"Agent", "Task"}
AGENT_DISPATCH_PATTERN = re.compile(
    r"\b(?P<tool>Agent|Task|spawn_agent)\s*\(\s*"
    r"(?:subagent_type|prompt|description|agent_type|task_name|message)\s*="
)
BROAD_SKILL_PREAPPROVAL = re.compile(
    r"^(?:Agent|Task|Bash|Edit|Skill|Write)(?:\(\*\))?$"
)
BROAD_GENERATED_PREAPPROVAL = re.compile(
    r"(?m)^\s*allowed-tools:\s*[^\n]*(?:Agent|Task|Bash|Edit|Skill|Write)\b"
)

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


def is_boolish(value):
    if isinstance(value, bool):
        return True
    return str(value).strip().lower() in BOOL_STRINGS


def valid_model(model, allowed):
    model = str(model)
    return model in allowed or FULL_MODEL_ID.fullmatch(model) is not None


def check_unknown_fields(path: Path, fm, known):
    for key in sorted(set(fm) - known):
        err(f"{path}: unknown frontmatter field '{key}' (Claude Code ignores it)")


def body(path: Path):
    text = path.read_text(encoding="utf-8")
    match = re.match(r"^---\n.*?\n---\n(?P<body>.*)$", text, re.DOTALL)
    return match.group("body") if match else ""


def check_dispatch_contract(path: Path, document_body: str, tools=None):
    dispatch_tools = {
        match.group("tool") for match in AGENT_DISPATCH_PATTERN.finditer(document_body)
    }
    if not dispatch_tools:
        return

    if tools is not None:
        configured = set(tools) if isinstance(tools, list) else set()
        for dispatch_tool in sorted(dispatch_tools & CLAUDE_DISPATCH_TOOLS):
            if dispatch_tool not in configured:
                err(f"{path}: calls {dispatch_tool} but tools does not include it")

    claude_dispatch = dispatch_tools & CLAUDE_DISPATCH_TOOLS
    if claude_dispatch and "spawn_agent" not in dispatch_tools:
        err(f"{path}: Claude dispatch has no Codex spawn_agent mapping")
    if "spawn_agent" in dispatch_tools and not claude_dispatch:
        err(f"{path}: Codex spawn_agent dispatch has no Claude Agent/Task mapping")

    normalized = re.sub(r"\s+", " ", document_body.lower())
    checks = {
        "provider dispatch unavailable/withheld handling": any(
            marker in normalized
            for marker in (
                "agent tool is unavailable",
                "agent tool is not available",
                "agent is unavailable",
                "agent is withheld",
                "dispatch interface is unavailable",
                "spawn_agent is unavailable",
                "tool unavailable",
            )
        ),
        "nesting-depth handling": "depth" in normalized and any(
            marker in normalized
            for marker in ("depth limit", "depth is reached", "maximum depth")
        ),
        "concurrency-limit no-retry handling": "concurr" in normalized and any(
            marker in normalized
            for marker in ("do not retry", "must not retry", "without retry", "no retry")
        ),
        "an incomplete dispatch_request/dispatch_plan result": any(
            marker in normalized
            for marker in ("dispatch_request", "dispatch request", "dispatch_plan")
        ) and any(
            marker in normalized
            for marker in ("incomplete", "not complete", "do not advance", "must not advance")
        ),
    }
    missing = [label for label, present in checks.items() if not present]
    if missing:
        err(f"{path}: dispatch contract missing: {'; '.join(missing)}")


def check_generated_skill_policy():
    paths = [
        ROOT / ".self-evolving-loop" / "templates" / "executor-template.md",
        ROOT / ".self-evolving-loop" / "templates" / "validator-template.md",
        ROOT / ".self-evolving-loop" / "templates" / "fixer-template.md",
        ROOT / "agents" / "skill-synthesizer.md",
        ROOT / "agents" / "skill-evolver.md",
    ]
    for path in paths:
        if not path.is_file():
            err(f"{path}: generated-skill policy source is missing")
            continue
        if BROAD_GENERATED_PREAPPROVAL.search(path.read_text(encoding="utf-8")):
            err(f"{path}: generated skill template broadly pre-approves mutation or delegation")


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
        check_unknown_fields(f, fm, SKILL_FIELDS)
        desc = fm.get("description")
        if not desc:
            err(f"{f}: missing description")
        elif not (20 <= len(str(desc)) <= 1024):
            err(f"{f}: description length {len(str(desc))} outside 20-1024")
        listing = len(str(desc or "")) + len(str(fm.get("when_to_use") or ""))
        if listing > SKILL_LISTING_CAP:
            err(f"{f}: description + when_to_use is {listing} chars; the skill "
                f"listing truncates at {SKILL_LISTING_CAP}")
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
        tool_items = (
            tools
            if isinstance(tools, list)
            else re.split(r"[\s,]+", tools.strip()) if isinstance(tools, str) else []
        )
        broad = sorted(item for item in tool_items if BROAD_SKILL_PREAPPROVAL.fullmatch(item))
        if broad:
            err(f"{f}: allowed-tools broadly pre-approves: {', '.join(broad)}")
        check_dispatch_contract(f, body(f))
        model = fm.get("model")
        if model is not None and not valid_model(model, SKILL_MODELS):
            err(f"{f}: invalid model '{model}'")
        effort = fm.get("effort")
        if effort is not None and str(effort) not in VALID_EFFORT:
            err(f"{f}: effort must be one of {sorted(VALID_EFFORT)}, got '{effort}'")
        if fm.get("context") is not None and fm.get("context") != "fork":
            err(f"{f}: context must be 'fork' when set, got '{fm.get('context')}'")
        if "background" in fm:
            if not is_boolish(fm["background"]):
                err(f"{f}: background must be a boolean")
            if fm.get("context") != "fork":
                warn(f"{f}: background only applies with context: fork")
        if fm.get("agent") is not None and fm.get("context") != "fork":
            warn(f"{f}: agent only applies with context: fork")
        if fm.get("shell") is not None and fm.get("shell") not in {"bash", "powershell"}:
            err(f"{f}: shell must be 'bash' or 'powershell'")
        if "disable-model-invocation" in fm and not is_boolish(fm["disable-model-invocation"]):
            err(f"{f}: disable-model-invocation must be a boolean")
        if len(str(fm.get("compatibility") or "")) > 500:
            err(f"{f}: compatibility exceeds 500 characters")
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
        check_unknown_fields(f, fm, AGENT_FIELDS)
        name = str(fm.get("name") or "")
        if name != f.stem:
            err(f"{f}: name '{fm.get('name')}' != filename '{f.stem}'")
        if ":" in name or name.startswith("-") or len(name) > 256:
            err(f"{f}: name must be at most 256 chars, without ':' or a leading '-'")
        desc = str(fm.get("description") or "")
        if not desc:
            err(f"{f}: missing description")
        elif not (10 <= len(desc) <= 5000):
            err(f"{f}: description length {len(desc)} outside 10-5000")
        elif "use " not in desc.lower():
            warn(f"{f}: description has no 'Use ...' trigger clause")
        if fm.get("color") not in VALID_COLORS:
            err(f"{f}: invalid color '{fm.get('color')}'")
        if not valid_model(fm.get("model"), AGENT_MODELS):
            err(f"{f}: invalid model '{fm.get('model')}'")
        effort = fm.get("effort")
        if effort is not None and str(effort) not in VALID_EFFORT:
            err(f"{f}: effort must be one of {sorted(VALID_EFFORT)}, got '{effort}'")
        if fm.get("isolation") is not None and fm.get("isolation") != "worktree":
            err(f"{f}: isolation must be 'worktree' when set")
        for flag in ("background", "omitClaudeMd"):
            if flag in fm and not is_boolish(fm[flag]):
                err(f"{f}: {flag} must be a boolean")
        window = fm.get("autoCompactWindow")
        if window is not None and not (
            isinstance(window, int) and 100000 <= window <= 1000000
        ):
            err(f"{f}: autoCompactWindow must be an integer from 100000 to 1000000")
        mode = fm.get("permissionMode")
        if mode is not None and mode not in VALID_PERMISSION_MODES:
            err(f"{f}: invalid permissionMode '{mode}'")
        experimental = fm.get("experimental")
        if experimental is not None and not (
            isinstance(experimental, dict)
            and set(experimental) <= {"cacheTtl"}
            and experimental.get("cacheTtl", "5m") in {"5m", "1h"}
        ):
            err(f"{f}: experimental only supports cacheTtl: 5m | 1h")
        tools = fm.get("tools")
        if not (isinstance(tools, list) and all(isinstance(t, str) for t in tools)):
            err(f"{f}: tools must be a YAML list of strings (house convention)")
        mem = fm.get("memory")
        if mem is not None and not (
            isinstance(mem, str) and mem in VALID_MEMORY
        ):
            err(f"{f}: memory must be one scalar from {sorted(VALID_MEMORY)}")
        mt = fm.get("maxTurns")
        if mt is not None and not (isinstance(mt, int) and mt > 0):
            err(f"{f}: maxTurns must be a positive integer")
        preloaded_skills = fm.get("skills") or []
        if preloaded_skills:
            err(f"{f}: portable agents must be self-contained; provider adapters "
                "do not preserve Claude-only skills preloading")
        for s in preloaded_skills:
            if s not in skill_names:
                err(f"{f}: skills references '{s}' but skills/{s}/ does not exist")
        for ignored in sorted(PLUGIN_IGNORED_AGENT_FIELDS & fm.keys()):
            warn(f"{f}: '{ignored}' is ignored for plugin subagents, and this "
                 f"catalog also ships as a plugin — remove it")
        check_dispatch_contract(f, body(f), fm.get("tools"))
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
    check_generated_skill_policy()
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
