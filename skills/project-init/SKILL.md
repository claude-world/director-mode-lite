---
name: project-init
description: "Set up concise, guidance-first Claude/Codex/Grok project context after inspecting the repository. Use on first setup, after cloning, or when the user runs /project-init."
user-invocable: true
---

# Project initialization

Create the smallest useful project context without adding permission gates,
blocking hooks, or mandatory process rules.

## 1. Inspect before writing

- Read existing `CLAUDE.md`, `AGENTS.md`, README, manifests, scripts, and CI.
- Detect the language, framework, build, test, lint, and development commands
  from repository evidence.
- Preserve existing user guidance and unrelated configuration.
- If the stack or desired workflow cannot be inferred safely, ask one focused
  question instead of inventing it.

## 2. Add concise shared context

Keep permanent guidance focused on facts useful in most sessions:

```markdown
# Project name

## Purpose
[What this repository delivers]

## Stack and structure
- [Language/framework]
- [Important entry points]

## Commands
- dev: [verified command]
- test: [verified command]
- build: [verified command]
- lint: [verified command]

## Local conventions
- [Only repository-specific conventions supported by evidence]
```

Use the Director managed block in both `CLAUDE.md` and `AGENTS.md` so all three
CLIs can find `.director-mode/GUIDANCE.md`. Put detailed, conditional procedures
in skills rather than expanding the permanent files.

## 3. Verify native assets

Check the selected CLI surfaces:

```text
Claude: .claude/skills/ and .claude/agents/
Codex:  .agents/skills/ and .codex/agents/
Grok:   shared Claude-compatible skills and .grok/agents/
Relay:  .director-mode/bin/director-relay
```

Run `scripts/verify-install.sh` when available. Do not require every optional
tool merely to declare setup complete.

## 4. Optional integrations

MCP servers, hooks, TDD, autonomous loops, and extra agents are choices, not
defaults. Suggest one only when it materially helps the current repository and
explain its effect. Install or register it only after the user requests it.

In particular, never register a Stop hook, deny rule, validator, security
guard, or background tracker as part of ordinary project initialization.

## 5. Report the result

Summarize detected facts, files created or updated, validation actually run,
and optional next steps. A useful default next step is `director-mode` or
`workflow`; use `session-relay` when another CLI should take over.
