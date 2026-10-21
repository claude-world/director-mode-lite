---
name: hooks-check
description: Validate hooks configuration and scripts. Use after adding or editing hooks in settings.json, before committing hook changes, or when a hook fails to fire.
user-invocable: true
---

# Hooks Validator

Validate hooks configuration in `.claude/settings.json` and hook scripts against
the official Claude Code spec.

---

## Validation Steps

### 1. Check settings.json
Verify the `hooks` section exists and is valid.

### 2. Validate Hook Event Names

Claude Code defines **33 hook events**. Accept any of them; flag unknown names
with a typo hint (e.g. `PrePromptSubmit` -> `UserPromptSubmit`,
`PostToolBatchFailure` -> `PostToolBatch`, `SubagentStarts` -> `SubagentStart`).

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

That is all 33 events. See the official hooks docs for each event's payload.

### 3. Validate Each Hook Entry
- [ ] `type` is present and one of: `command`, `prompt`, `http`, `mcp_tool`, `agent`
- [ ] If `type: command`: `command` path exists and script is executable; a
      shell-form path variable is quoted (`"$CLAUDE_PROJECT_DIR"/...`), or the
      hook uses exec form (`args`)
- [ ] If `type: prompt` or `agent`: `prompt` string is non-empty
- [ ] If `type: http`: `url` is set; if `type: mcp_tool`: `server` and `tool` are set
- [ ] `matcher` is a string if present (exact names joined by `|` or `,`, `*`,
      or a regex); warn when it sits on an event without matcher support
      (`UserPromptSubmit`, `Stop`, `PostToolBatch`, `TeammateIdle`,
      `TaskCreated`, `TaskCompleted`, `WorktreeCreate`, `WorktreeRemove`,
      `MessageDisplay`, `CwdChanged`), where it is silently ignored
- [ ] `timeout` is a positive integer if present (defaults: 600s command/http/mcp_tool, 30s prompt, 60s agent)
- [ ] `if` is a permission rule such as `Bash(git *)`, used only on tool events
- [ ] `onFailure` is `continue` or `block` (v2.1.295+); recommend `block` for security guards
- [ ] `once` appears only in skill frontmatter hooks; settings files ignore it
- [ ] `async` / `asyncRewake` appear only on command hooks
- [ ] `statusMessage` is a string if present
- [ ] `SessionEnd` matchers do not use `bypass_permissions_disabled` (removed in v2.1.234)

### 4. Validate Hook Scripts
- [ ] File exists and is executable
- [ ] Has an appropriate shebang
- [ ] **If** the script emits structured output on stdout, it is valid JSON.
      Silent / exit-code-only hooks are valid — no stdout is required
      (exit `0` = allow/continue, exit `2` = block for `PreToolUse`).

---

## Decision Output Schema

When a script does emit JSON, validate it against the event contract:

- **PreToolUse**: `hookSpecificOutput.permissionDecision` is `allow`, `deny`,
  `ask`, or `defer` (`-p` only). The legacy top-level
  `{"decision": "approve" | "block"}` is still accepted.
- **Prompt / agent hooks**: the model's verdict is `{"ok": true}` or
  `{"ok": false, "reason": "..."}`.
- **Stop / SubagentStop**: continuation uses
  `{"decision": "block", "reason": "<next prompt>"}` — the key is `reason`.
- Input JSON always carries the event under `hook_event_name` (not `hook_type`).

---

## Output Format

```markdown
## Hooks Validation Report

### Configuration Status: VALID / INVALID

### Configured Hooks
| Event | Matcher | Script | Status |
|-------|---------|--------|--------|
| Stop | * | auto-loop-stop.sh | OK |

### Script Validation
| Script | Exists | Executable | Output |
|--------|--------|------------|--------|
| auto-loop-stop.sh | OK | OK | JSON OK / silent |

### Issues Found
1. [Issue and fix]
```

---

## Auto-Fix

- Make scripts executable
- Add missing shebang
- Create missing hook scripts
- Correct a misspelled event name to the nearest valid event
- Normalize `hook_type` -> `hook_event_name` in emitted JSON
