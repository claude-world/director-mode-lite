---
name: handoff-codex
description: Continue a task in OpenAI Codex CLI through a portable Director handoff packet. Use when the user asks Codex to take over, wants an independent Codex implementation or review, or needs to preserve decisions and verification while changing CLIs.
user-invocable: true
---

# Handoff to Codex CLI

Use the shared `session-relay` workflow. Codex starts its own native session and
reads a packet containing the goal, current state, decisions, Git evidence,
verification, and next steps.

```bash
ROOT="${CLAUDE_PROJECT_DIR:-${GROK_WORKSPACE_ROOT:-}}"
[[ -n "$ROOT" ]] || ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
RELAY="$ROOT/.director-mode/bin/director-relay"
[[ -x "$RELAY" ]] || RELAY="$HOME/.claude/bin/director-relay"

"$RELAY" create \
  --from <claude|grok> --to codex \
  --goal "..." --summary "..." --next "..."

"$RELAY" continue --to codex
```

The second command prints the interactive `codex` invocation. Add `--run` only
when the user wants it launched now. Use `--headless` when a one-shot `codex
exec` continuation is appropriate.

Codex reads the repository's `AGENTS.md`, reusable skills from
`.agents/skills/`, and generated agents from `.codex/agents/`. Confirm those
surfaces with the installed CLI when debugging discovery.

Do not add bypass, approval, sandbox, or network flags as part of the handoff.
Those controls belong to the Codex session and remain at their current native
settings.
