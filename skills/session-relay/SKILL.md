---
name: session-relay
description: Create or consume a portable handoff packet when work should move between Claude Code, Codex CLI, and Grok Build. Use when the user asks another CLI to continue the same task, when a session is near its context limit, or when switching vendors without losing decisions and verification state.
user-invocable: true
allowed-tools:
  - Read
  - Bash
  - Grep
  - Glob
---

# Cross-CLI Session Relay

Move work between Claude Code, Codex CLI, and Grok Build through a portable
handoff packet. A relay starts a new native session in the receiving CLI; it
does not pretend that vendor session IDs or private conversation histories are
interchangeable.

## Leave a packet

Summarize the current state from repository evidence, then run:

```bash
ROOT="${CLAUDE_PROJECT_DIR:-${GROK_WORKSPACE_ROOT:-}}"
[[ -n "$ROOT" ]] || ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
RELAY="$ROOT/.director-mode/bin/director-relay"
[[ -x "$RELAY" ]] || RELAY="$HOME/.claude/bin/director-relay"

"$RELAY" create \
  --from <claude|codex|grok> \
  --to <claude|codex|grok> \
  --goal "The outcome the user requested" \
  --summary "The concise current state" \
  --completed "One completed result" \
  --decision "One decision and why it was made" \
  --next "The first concrete next step" \
  --verification "A command and its actual result" \
  --blocker "A real blocker, if any"
```

Repeat list flags as needed. The tool captures branch, HEAD, `git status
--short`, and diff statistics. It deliberately does not copy file contents,
credentials, environment variables, or raw transcripts.

If a native session ID is available, add `--session-id`; it remains metadata
for the source CLI and is never sent to another vendor as a resume token.

## Receive a packet

1. Read `.director-mode/handoffs/latest.md`.
2. Inspect the live worktree because it may have changed after the packet.
3. Continue from the next steps while preserving recorded decisions that still
   match the code.
4. Run the listed verification and report new evidence.

Print the receiving command:

```bash
"$RELAY" continue --to <claude|codex|grok>
```

Add `--run` only when the user wants the target CLI launched now. Add
`--headless` for a one-shot continuation instead of an interactive session.

## Grok's native Claude import

Grok Build can import Claude Code sessions with `grok import`. That is a useful
Claude→Grok fast path, but still leave a Director packet when the workflow may
later move to Codex or back to Claude.

## Guidance boundary

Do not add auto-approve, permission-bypass, sandbox, or network flags to a relay
unless the user separately asks for them. The receiving CLI keeps its native
controls.
