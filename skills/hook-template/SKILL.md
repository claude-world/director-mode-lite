---
name: hook-template
description: Generate hook script from template. Use when adding a new hook, wiring a PreToolUse/PostToolUse/Stop/Notification hook, or scaffolding hook config for settings.json.
user-invocable: true
---

# Hook Template Generator

Generate a hook script and configuration based on requirements.

**Usage**: `/hook-template [hook-event] [purpose]`

---

## Hook Events

Claude Code defines **33 hook events**. The common ones, grouped:

| Group | Events |
|-------|--------|
| Lifecycle | `SessionStart`, `SessionEnd`, `Setup` |
| Prompt | `UserPromptSubmit`, `UserPromptExpansion` |
| Tool | `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PostToolBatch` |
| Permission | `PermissionRequest`, `PermissionDenied` |
| Subagent | `SubagentStart`, `SubagentStop` |
| Stop | `Stop`, `StopFailure` |
| Task | `TaskCreated`, `TaskCompleted` |
| Compaction | `PreCompact`, `PostCompact` |
| Notification | `Notification`, `MessageDisplay` |
| MCP elicitation | `Elicitation`, `ElicitationResult` |
| Model | `PreModelSwitch`, `PostModelSwitch` |
| Environment | `ConfigChange`, `CwdChanged`, `DirectoryAdded`, `FileChanged`, `InstructionsLoaded`, `WorktreeCreate`, `WorktreeRemove`, `TeammateIdle` |

That is all 33 events. See the official Claude Code hooks docs for the full list
and each event's payload. The templates below cover the practical 90%.

---

## Hook Config Fields

| Field | Type | Required | Default | Notes |
|-------|------|----------|---------|-------|
| `type` | String | Yes | - | `command`, `prompt`, `http`, `mcp_tool`, or `agent` |
| `command` | String | If type=command | - | Shell command, or the executable when `args` is set |
| `args` | Array | No | - | Exec form: no shell, each element is one argument |
| `prompt` | String | If type=prompt/agent | - | Prompt for the model; `$ARGUMENTS` receives the input JSON |
| `matcher` | String | No | all | Exact names (`Edit\|Write`), `*`, or a regex; ignored by events without matcher support |
| `timeout` | Integer | No | 600 (command), 30 (prompt), 60 (agent) | Seconds, per hook |
| `if` | String | No | - | Permission-rule filter such as `Bash(git *)`; tool events only |
| `onFailure` | String | No | continue | `block` makes a hook that cannot run or times out block the action (v2.1.295+) |
| `async` | Boolean | No | false | Command hooks only: run in the background, cannot block |
| `once` | Boolean | No | false | Remove after the first successful run; honored only in skill frontmatter |
| `statusMessage` | String | No | - | Message shown while the hook runs |

`type: command` (default) and `type: prompt` (LLM-evaluated) cover most needs.
The `http`, `mcp_tool`, and `agent` entry types also exist for calling an
endpoint, invoking an MCP tool, or dispatching a subagent.

---

## Hook Input (stdin JSON)

All hooks receive JSON on stdin. The event name is in `hook_event_name`:

```json
{
  "session_id": "abc123",
  "transcript_path": "/path/to/transcript.jsonl",
  "cwd": "/current/working/dir",
  "permission_mode": "default",
  "hook_event_name": "PreToolUse",
  "tool_name": "Write",
  "tool_input": { "file_path": "/path/to/file" }
}
```

### Decision output cheatsheet

- **PreToolUse**: return `hookSpecificOutput.permissionDecision` of `allow`,
  `deny`, `ask`, or `defer` (`-p` only). Exit code 2 with a stderr message is
  the shorthand for `deny`. The legacy top-level `{"decision": "approve" | "block"}`
  is still accepted.
- **PostToolUse**: Bash output arrives as `tool_response` (`stdout`, `stderr`,
  `interrupted`, `isImage`).
- **Prompt / agent hooks**: the model answers `{"ok": true}` or
  `{"ok": false, "reason": "..."}`.
- **Stop / SubagentStop**: to continue the loop, return
  `{"decision": "block", "reason": "<next prompt>"}` — the key is `reason`.
- Silent success is exit `0` with no output.

---

## Process

1. **Gather Requirements**
   - Hook event
   - Purpose
   - Matcher (for tool events: tool name, regex, or `*`)

2. **Generate Script** at `.claude/hooks/[name].sh`

3. **Update settings.json** with hook config

4. **Make Executable**: `chmod +x`

5. **Validate** with `/hooks-check`

---

## Templates

### PreToolUse (Blocker, exit-code shorthand)
```bash
#!/bin/bash
INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name')
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Block edits to specific files
if [[ "$FILE" == *"package-lock.json"* ]]; then
    echo "BLOCKED: Do not edit lockfiles directly" >&2
    exit 2   # exit 2 = deny for PreToolUse
fi
exit 0  # Allow (no output needed)
```

### PreToolUse (Deny via JSON permissionDecision)
```bash
#!/bin/bash
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ "$FILE" == *"package-lock.json"* ]]; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": "Do not edit lockfiles directly"
      }
    }'
    exit 0
fi
# permissionDecision may be "allow", "deny", or "ask"
exit 0
```

### PreToolUse (Context Adding)
```bash
#!/bin/bash
cat > /dev/null  # Consume stdin
INFO="This file requires careful review"
jq -n --arg ctx "$INFO" '{
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "additionalContext": $ctx
    }
}'
exit 0
```

### PostToolUse (Logger)
```bash
#!/bin/bash
INPUT=$(cat)
# Process and log... (no stdout needed)
exit 0
```

### Stop (Auto-Loop)
```bash
#!/bin/bash
CHECKPOINT=".auto-loop/checkpoint.json"
if [[ ! -f "$CHECKPOINT" ]]; then
    exit 0  # Allow stop
fi
# Block stop to continue loop — key is "reason", used as the next prompt
jq -n --arg reason "Continuing iteration" \
    '{"decision": "block", "reason": $reason}'
exit 0
```

### SessionStart (Context Load)
```bash
#!/bin/bash
cat > /dev/null
# Plain stdout from SessionStart is added to Claude's context
echo "Project context: run the test suite before committing."
exit 0
```

### Prompt Hook (LLM-based)

Instead of a bash script, use `type: "prompt"` in settings.json:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Review the work done: $ARGUMENTS. Respond {\"ok\": true} if complete, or {\"ok\": false, \"reason\": \"what remains\"}.",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

---

## Settings.json Format

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/validate.sh",
            "timeout": 60
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "startup|resume|clear|compact|fork",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/load-context.sh"
          }
        ]
      }
    ]
  }
}
```

---

## Example

```
/hook-template PreToolUse "block edits to package-lock.json"

Creates:
- .claude/hooks/protect-lockfile.sh
- Updates .claude/settings.json
```
