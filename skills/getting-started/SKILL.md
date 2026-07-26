---
name: getting-started
description: Guided five-minute onboarding for Director Mode Lite across Claude Code, Codex CLI, and Grok Build. Use after installation or when choosing a first workflow.
user-invocable: true
---

# Getting started

Director Mode is a set of adaptable workflows, not a permission or policy
layer. Keep the user's preferred CLI controls and choose only the skills useful
for the current task.

## 1. Verify the portable surfaces

```bash
./scripts/verify-install.sh /path/to/project
```

A full three-CLI install currently provides 35 skills, 14 canonical Claude
agents, 14 Codex adapters, 14 Grok adapters, shared guidance, and the session
relay. Python 3 is required for installation and relay packets. `jq` is only a
legacy automation dependency; a normal zero-hook install does not need it.

Active hooks are optional. The default install deliberately registers none.
Use `--hooks guide` only when a short non-blocking Claude/Codex SessionStart
context is useful. Grok reads the same guidance from `AGENTS.md` without an
inert passive hook.

## 2. Choose a starting point

- `director-mode`: define outcome, context, constraints, evidence, and the next
  decision for substantial work.
- `workflow`: use the full research → plan → implement → verify → review flow.
- `focus-problem`: understand an unfamiliar bug or codebase area.
- `session-relay`: leave portable state for Claude, Codex, or Grok to continue.
- `smart-commit`: review and prepare a conventional commit when requested.

Testing and TDD skills are available when they fit the repository or the user
asks for them; they are not imposed on every task.

## 3. Let another CLI continue

```bash
.director-mode/bin/director-relay create \
  --from claude --to codex \
  --goal "Finish the current feature" \
  --summary "Implementation is partly complete" \
  --next "Inspect the worktree and continue"

.director-mode/bin/director-relay continue --to codex
```

The second command prints a copyable native command. It launches nothing until
the user explicitly adds `--run`.

## Help

- `agents`: list available agent roles.
- `skills`: browse the skill catalog.
- `docs/FAQ.md`: installation and relay questions.
- <https://claude-world.com>: tutorials and updates.
