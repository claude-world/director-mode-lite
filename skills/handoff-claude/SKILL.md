---
name: handoff-claude
description: Continue a task in Claude Code through a portable Director handoff packet. Use when work started in Codex CLI or Grok Build should move to Claude, or when a fresh Claude session needs the current decisions and verification evidence.
user-invocable: true
allowed-tools:
  - Read
  - Bash
  - Grep
  - Glob
---

# Handoff to Claude Code

Use the shared `session-relay` workflow. Claude starts a new native session and
reads the same vendor-neutral packet used by Codex and Grok.

```bash
ROOT="${CLAUDE_PROJECT_DIR:-${GROK_WORKSPACE_ROOT:-}}"
[[ -n "$ROOT" ]] || ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
RELAY="$ROOT/.director-mode/bin/director-relay"
[[ -x "$RELAY" ]] || RELAY="$HOME/.claude/bin/director-relay"

"$RELAY" create \
  --from <codex|grok> --to claude \
  --goal "..." --summary "..." --next "..."

"$RELAY" continue --to claude
```

The second command only prints the interactive command. Add `--run` when the
user explicitly wants to launch it, or `--headless` for a one-shot `claude -p`
continuation.

Claude Code's own `--continue` and `--resume` remain the right tools for
resuming a Claude-native history. Use a Director packet when the source is
another CLI, when a concise checkpoint is preferable, or when the workflow may
later move again.

Profiles created with `CLAUDE_CONFIG_DIR` can still isolate authorized Claude
accounts, but profile credentials, permissions, plugins, MCP configuration, and
session histories are not copied into the packet.
