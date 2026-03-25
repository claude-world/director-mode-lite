# Claude Code Hooks Guide

> Reference documentation for hook implementation aligned with Claude Code v2.1.76.

---

## 1. Hook Types (Complete List)

| Event | When it Fires | Use Case |
|-------|---------------|----------|
| `PreToolUse` | Before a tool runs | Block, validate, modify input, add context |
| `PostToolUse` | After a tool completes | Log, notify, react to results |
| `UserPromptSubmit` | User submits a prompt | Context injection, input validation |
| `Stop` | Main agent stopping | Completeness check, continue loops |
| `SubagentStop` | Subagent finishes | Task validation |
| `SessionStart` | Session begins | Context loading, env setup |
| `SessionEnd` | Session ends | Cleanup, logging, summary |
| `PreCompact` | Before context compaction | Preserve critical context |
| `PostCompact` | After compaction completes | Context recovery |
| `Notification` | User is notified | External alerts (Slack, etc.) |

---

## 2. Input Format (stdin JSON)

All hooks receive JSON on stdin. Fields vary by hook type:

```json
{
  "session_id": "abc123",
  "transcript_path": "/path/to/transcript.txt",
  "cwd": "/current/working/dir",
  "permission_mode": "ask",
  "hook_event_name": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": {
    "command": "ls -la",
    "file_path": "/path/to/file"
  },
  "tool_result": "...",
  "user_prompt": "...",
  "reason": "..."
}
```

| Field | Available In |
|-------|-------------|
| `session_id` | All hooks |
| `transcript_path` | All hooks |
| `cwd` | All hooks |
| `hook_event_name` | All hooks |
| `tool_name`, `tool_input` | PreToolUse, PostToolUse |
| `tool_result` | PostToolUse only |
| `user_prompt` | UserPromptSubmit only |
| `reason` | Stop, SubagentStop only |

### Output Formats

| Scenario | Format |
|----------|--------|
| Allow operation | `exit 0` (no output) |
| Block operation | `exit 2` + stderr message |
| Add context (PreToolUse) | `{"hookSpecificOutput": {"hookEventName": "PreToolUse", "additionalContext": "message"}}` |
| Stop hook - prevent stop | `{"decision": "block", "reason": "reason"}` |
| General output | `{"continue": true, "systemMessage": "info for Claude"}` |

### Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success (stdout shown in transcript) |
| `2` | Blocking error (stderr fed back to Claude as system message) |
| Other | Non-blocking error |

---

## 3. Hook Configuration

### settings.json Format

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/validate.sh",
            "timeout": 60
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Verify task completion. Return 'approve' or 'block' with reason.",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

### Hook Object Fields

| Field | Type | Required | Default | Notes |
|-------|------|----------|---------|-------|
| `type` | String | Yes | - | `"command"` or `"prompt"` |
| `command` | String | If type=command | - | Shell command to execute |
| `prompt` | String | If type=prompt | - | Natural language prompt for LLM |
| `timeout` | Integer | No | 60s (command), 30s (prompt) | Seconds |
| `once` | Boolean | No | false | Run hook only once per session |

### Matcher Patterns

```
"Write"              → exact tool name
"Write|Edit"         → multiple tools (regex OR)
"*"                  → all tools
"mcp__.*"            → all MCP tools
"mcp__.*__delete.*"  → specific MCP operation
```

---

## 4. Common Mistakes

| Mistake | Cause | Solution |
|---------|-------|----------|
| hook error continuously | Using old format `{"decision": "allow"}` | Use `exit 0` |
| Path not loading | `$HOME` variable not expanded | Use `$CLAUDE_PROJECT_DIR` |
| Hooks overwriting each other | settings.local.json also has config | Clear hooks from all .local.json |
| Hook not firing | Wrong matcher pattern | Check tool name matches exactly |

---

## 5. Script Templates

### PreToolUse (Blocking)

```bash
#!/bin/bash
HOOK_INPUT=$(cat)
COMMAND=$(echo "$HOOK_INPUT" | jq -r '.tool_input.command // empty')
[[ -z "$COMMAND" ]] && exit 0

if echo "$COMMAND" | grep -qE 'dangerous_pattern'; then
    echo "BLOCKED: reason" >&2
    exit 2
fi
exit 0
```

### PreToolUse (Context Adding)

```bash
#!/bin/bash
cat > /dev/null  # Consume stdin
INFO="collected information"
jq -n --arg ctx "$INFO" '{
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "additionalContext": $ctx
    }
}'
exit 0
```

### PostToolUse (Logging)

```bash
#!/bin/bash
HOOK_INPUT=$(cat)
# Process and log...
exit 0  # No output needed
```

### Stop Hook

```bash
#!/bin/bash
if need_to_continue; then
    jq -n --arg reason "reason" '{"decision": "block", "reason": $reason}'
    exit 0
fi
exit 0  # Allow stop
```

### SessionStart (Context Load)

```bash
#!/bin/bash
cat > /dev/null
# Load project context, set environment
echo "Project context loaded" >&2
exit 0
```

### Prompt Hook (in settings.json, no script needed)

```json
{
  "type": "prompt",
  "prompt": "Review the work done so far. If all acceptance criteria are met, return 'approve'. Otherwise return 'block' with what's missing.",
  "timeout": 30,
  "once": true
}
```

---

## 6. Key Points

1. **Always consume stdin** - Even if not needed: `cat > /dev/null`
2. **Use jq for JSON** - Safer and more reliable
3. **stderr for block messages** - `echo "message" >&2`
4. **stdout for JSON output** - `hookSpecificOutput` structure
5. **Use `$CLAUDE_PROJECT_DIR`** - For portable hook paths in settings.json
6. **Two hook types** - `type: "command"` (bash script) and `type: "prompt"` (LLM-based)
7. **`once: true`** - Use for one-time setup hooks (e.g., SessionStart)
8. **Testing** - Execute command directly and observe for hook errors

---

## 7. Director Mode Lite Hooks

| Script | Type | Purpose |
|--------|------|---------|
| `_lib-changelog.sh` | Library | Shared functions for logging |
| `pre-tool-validator.sh` | PreToolUse | Adds context for sensitive files |
| `log-file-change.sh` | PostToolUse | Logs Write/Edit operations |
| `log-bash-event.sh` | PostToolUse | Logs test results and commits |
| `auto-loop-stop.sh` | Stop | Controls auto-loop continuation |

---

## References

- Claude Code Hooks official documentation (v2.1.76)
- Director Mode Lite v1.7.1 implementation
