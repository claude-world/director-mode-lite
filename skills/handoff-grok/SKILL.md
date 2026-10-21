---
name: handoff-grok
description: Continue a task in xAI Grok Build using the shared Director handoff packet. Use when the user says to use Grok, requests a Grok review, or wants Grok Build to take over work started in Claude Code or Codex CLI.
user-invocable: true
---

# Handoff to Grok Build

Use the `session-relay` workflow so Grok receives the goal, decisions, Git
state, verification, and next steps without relying on another vendor's native
session ID.

```bash
ROOT="${CLAUDE_PROJECT_DIR:-${GROK_WORKSPACE_ROOT:-}}"
[[ -n "$ROOT" ]] || ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
RELAY="$ROOT/.director-mode/bin/director-relay"
[[ -x "$RELAY" ]] || RELAY="$HOME/.claude/bin/director-relay"

"$RELAY" create \
  --from <claude|codex> --to grok \
  --goal "..." --summary "..." --next "..."

"$RELAY" continue --to grok
```

The second command prints an interactive Grok command. Add `--run` only when
the user wants it launched immediately, or `--headless` for `grok -p`.

Grok automatically reads Claude-compatible project assets (skills, rules,
`CLAUDE.md`, MCP servers, and hooks), and its `/import-claude` command copies
`~/.claude` settings. Neither carries a conversation: Grok Build 1.0.62 has no
`grok import` command, so the portable packet is the session format.

Grok's approvals, permission rules, sandbox, network access, and hook trust stay
under Grok's native configuration. This skill does not change them.
