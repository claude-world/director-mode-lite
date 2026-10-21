# Claude Code Hooks Guide

> Reference documentation for hook implementation aligned with Claude Code v2.1.305.

Director Mode Lite registers no hooks by default. A hook belongs in an active
configuration only when its benefit is measurable and it is intentionally
selected. Audit both exit status and stdout JSON: an outer wrapper can exit 0
while an inner hook returns `decision: "block"` or a deny permission decision.
Also inspect Grok with `grok inspect --json`, because Grok can discover enabled
Claude hooks even when `~/.grok/hooks/` is empty.

---

## 1. Hook Events

Claude Code currently defines **33 hook event types**. The ones you'll use most:

| Event | When it Fires | Use Case |
|-------|---------------|----------|
| `PreToolUse` | Before a tool runs | Block, validate, modify input, add context |
| `PostToolUse` | After a tool completes | Log, notify, react to results |
| `PostToolUseFailure` | After a tool call fails | Error handling, diagnostics |
| `UserPromptSubmit` | User submits a prompt | Context injection, input validation |
| `Stop` | Main agent stopping | Completeness check, continue loops |
| `SubagentStart` / `SubagentStop` | Subagent spawned / finishes | Setup, task validation |
| `SessionStart` | Session begins, resumes, clears, compacts, or forks | Context loading, env setup |
| `SessionEnd` | Session ends | Cleanup, logging, summary |
| `PreCompact` | Before context compaction | Preserve critical context |
| `PostCompact` | After compaction completes | Context recovery |
| `Notification` | User is notified | External alerts (Slack, etc.) |
| `PermissionRequest` | Permission dialog appears | Auto-approve policies |
| `Elicitation` | MCP server requests input | Override elicitation responses |
| `ElicitationResult` | Elicitation result available | Post-process elicitation |

<details>
<summary>Remaining events (less common)</summary>

`Setup`, `StopFailure`, `PostToolBatch`, `PermissionDenied`, `UserPromptExpansion`,
`TaskCreated`, `TaskCompleted`, `TeammateIdle`, `MessageDisplay`, `ConfigChange`,
`CwdChanged`, `DirectoryAdded`, `FileChanged`, `InstructionsLoaded`,
`WorktreeCreate`, `WorktreeRemove`, `PreModelSwitch`, `PostModelSwitch`

See the official hooks documentation for the full, current list.

</details>

> Hook entries support `type: "command"` (shell, used throughout this guide) plus
> `"prompt"` (LLM-evaluated), `"http"`, `"mcp_tool"`, and `"agent"`. Common optional
> fields: `timeout` (seconds; default 600 for command, http, and mcp_tool hooks, 30
> for prompt, 60 for agent), `if` (a permission-rule filter, tool events only), and
> `statusMessage`. Command hooks add `args` (exec form, no shell), `async`,
> `asyncRewake`, `shell`, and `onFailure` (v2.1.295+). `once` is honored only for
> hooks declared in skill frontmatter.

---

## 2. Input Format (stdin JSON)

All hooks receive JSON on stdin. Fields vary by event:

```json
{
  "session_id": "abc123",
  "transcript_path": "/path/to/transcript.jsonl",
  "cwd": "/current/working/dir",
  "permission_mode": "default",
  "hook_event_name": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": {
    "command": "ls -la"
  },
  "tool_use_id": "toolu_01ABC123"
}
```

| Field | Available In |
|-------|-------------|
| `session_id`, `transcript_path`, `cwd`, `hook_event_name` | All hooks |
| `permission_mode` | Most events: `default`, `plan`, `acceptEdits`, `auto`, `dontAsk`, or `bypassPermissions` |
| `tool_name`, `tool_input`, `tool_use_id` | PreToolUse, PostToolUse, PostToolUseFailure, PermissionRequest |
| `tool_response` | PostToolUse (Bash returns `{stdout, stderr, interrupted, isImage}`) |
| `prompt` | UserPromptSubmit |
| `stop_hook_active`, `last_assistant_message` | Stop, SubagentStop |
| `source` (`startup`, `resume`, `clear`, `compact`, `fork`) | SessionStart |
| `reason` | SessionEnd |
| `trigger`, `custom_instructions` | PreCompact |
| `agent_id`, `agent_type` | Hooks that fire inside a subagent or an `--agent` session |

### Output Formats

| Scenario | Format |
|----------|--------|
| Allow operation | `exit 0` (no output) |
| Block operation | `exit 2` + stderr message (on events that can block) |
| PreToolUse decision | `{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "why"}}` (`allow`, `deny`, `ask`, or `defer`) |
| Add context (PreToolUse) | `{"hookSpecificOutput": {"hookEventName": "PreToolUse", "additionalContext": "message"}}` |
| Stop hook - prevent stop | `{"decision": "block", "reason": "reason"}` |
| Warn the user | `{"systemMessage": "shown to the user"}` |
| Halt Claude entirely | `{"continue": false, "stopReason": "shown to the user"}` |

### Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success; JSON fields apply. Plain stdout becomes context only for `UserPromptSubmit`, `UserPromptExpansion`, `SessionStart`, and `PostModelSwitch`; other events write it to the debug log |
| `2` | Blocking error on events that can block (stderr is the reason) |
| Other | Non-blocking error; the action proceeds unless the hook sets `"onFailure": "block"` |

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
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/validate.sh",
            "timeout": 60
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Verify task completion: $ARGUMENTS. Respond {\"ok\": true} to allow stopping, or {\"ok\": false, \"reason\": \"what is missing\"} to continue.",
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
| `type` | String | Yes | - | `"command"`, `"http"`, `"mcp_tool"`, `"prompt"`, or `"agent"` |
| `command` | String | If type=command | - | Shell command, or the executable when `args` is set |
| `args` | Array | No | - | Exec form: spawn `command` directly with these arguments, no shell |
| `prompt` | String | If type=prompt/agent | - | Prompt for the model; `$ARGUMENTS` receives the hook input JSON |
| `timeout` | Integer | No | 600 (command/http/mcp_tool), 30 (prompt), 60 (agent) | Seconds |
| `if` | String | No | - | Permission-rule filter such as `"Bash(git *)"`; tool events only |
| `async` | Boolean | No | false | Command hooks: run in the background; cannot block |
| `onFailure` | String | No | continue | `"block"` blocks the action when the hook cannot run, times out, or exits unexpectedly (v2.1.295+) |
| `once` | Boolean | No | false | Remove the hook after its first successful run; honored only in skill frontmatter |
| `statusMessage` | String | No | - | Spinner text while the hook runs |

### Matcher Patterns

```
"Write"              → exact tool name
"Write|Edit"         → exact names separated by | or ,
"*", "" or omitted   → every occurrence of the event
"^Notebook"          → any other character makes it an unanchored JavaScript regex
"mcp__memory__.*"    → every tool from the memory MCP server
```

`UserPromptSubmit`, `Stop`, `PostToolBatch`, `TeammateIdle`, `TaskCreated`,
`TaskCompleted`, `WorktreeCreate`, `WorktreeRemove`, `MessageDisplay`, and
`CwdChanged` have no matcher support and silently ignore one.

---

## 4. Common Mistakes

| Mistake | Cause | Solution |
|---------|-------|----------|
| PreToolUse JSON has no effect | Top-level `{"decision": "allow"}` was never a valid value | Use `hookSpecificOutput.permissionDecision`, or plain `exit 0` |
| Path not loading | `$HOME` variable not expanded | Use `$CLAUDE_PROJECT_DIR` |
| Path breaks on spaces | Unquoted `$CLAUDE_PROJECT_DIR` in shell form | Quote it, or use exec form with `args` |
| Guard lets everything through | Missing or crashing script fails open | Add `"onFailure": "block"` to the guard |
| `once` has no effect | Set in `settings.json` | `once` works only in skill frontmatter |
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
# Bash results arrive as tool_response {stdout, stderr, interrupted, isImage}
OUTPUT=$(echo "$HOOK_INPUT" | jq -r '.tool_response.stdout // empty')
# Process and log...
exit 0  # No output needed
```

### Stop Hook

```bash
#!/bin/bash
HOOK_INPUT=$(cat)
# stop_hook_active is true once a Stop hook has already sent Claude back to work.
# Without an iteration cap of its own (as auto-loop-stop.sh has), stop here.
[[ "$(echo "$HOOK_INPUT" | jq -r '.stop_hook_active')" == "true" ]] && exit 0
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
# Plain stdout from a SessionStart hook is added to Claude's context
echo "Project context: run ./tests/run-tests.sh before committing."
exit 0
```

### Prompt Hook (in settings.json, no script needed)

```json
{
  "type": "prompt",
  "prompt": "Review the work so far: $ARGUMENTS. If all acceptance criteria are met, respond {\"ok\": true}. Otherwise respond {\"ok\": false, \"reason\": \"what is missing\"}.",
  "timeout": 30
}
```

---

## 6. Key Points

1. **Always consume stdin** - Even if not needed: `cat > /dev/null`
2. **Use jq for JSON** - Safer and more reliable
3. **stderr for block messages** - `echo "message" >&2`
4. **stdout for JSON output** - `hookSpecificOutput` structure
5. **Use `$CLAUDE_PROJECT_DIR`** - Quoted, for portable hook paths in settings.json
6. **Five hook types** - `command`, `http`, `mcp_tool`, `prompt` (`{"ok": ...}` verdict), and `agent`
7. **`once: true`** - Only in skill frontmatter; settings files ignore it
8. **Fail closed when it matters** - Security guards should set `"onFailure": "block"`
9. **Testing** - Execute command directly and observe for hook errors

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

- Claude Code Hooks official documentation (v2.1.305): https://code.claude.com/docs/en/hooks
- Director Mode Lite v2.3.0 implementation
