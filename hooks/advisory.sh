#!/usr/bin/env bash
# Guidance-only hook shared by Claude Code, Codex CLI, and Grok Build.
# Claude and Codex consume its SessionStart context. Current Grok releases
# ignore passive-hook stdout and instead read the same guidance from AGENTS.md.
# The script consumes stdin, never denies an action, and always exits zero.

set +e
CLI_NAME="${1:-cli}"
payload="$(cat 2>/dev/null || true)"
: "$payload"

project_dir="${CLAUDE_PROJECT_DIR:-${GROK_WORKSPACE_ROOT:-}}"
if [[ -z "$project_dir" ]]; then
    project_dir="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi
latest="$project_dir/.director-mode/handoffs/latest.md"
message="Director Mode is guidance-only. For substantial work, read .director-mode/GUIDANCE.md and keep outcome, context, constraints, and evidence visible."
if [[ -f "$latest" ]]; then
    message="$message A portable handoff is available at .director-mode/handoffs/latest.md; verify the worktree before continuing."
fi

case "$CLI_NAME" in
    claude|grok)
        if command -v python3 >/dev/null 2>&1; then
            DML_MESSAGE="$message" DML_CLI="$CLI_NAME" python3 - <<'PY'
import json
import os

print(json.dumps({
    "systemMessage": os.environ["DML_MESSAGE"],
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": os.environ["DML_MESSAGE"],
    },
}))
PY
        else
            printf '%s\n' "$message"
        fi
        ;;
    codex)
        if command -v python3 >/dev/null 2>&1; then
            DML_MESSAGE="$message" python3 - <<'PY'
import json
import os

print(json.dumps({
    "systemMessage": os.environ["DML_MESSAGE"],
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": os.environ["DML_MESSAGE"],
    },
}))
PY
        else
            printf '%s\n' "$message"
        fi
        ;;
    *)
        printf '%s\n' "$message"
        ;;
esac

exit 0
