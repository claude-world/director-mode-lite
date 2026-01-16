# Claude Code Hooks Guide

> Reference documentation for hook implementation based on practical experience.

---

## 1. Official Format Specification

### Input Format (stdin JSON)

```json
{
  "tool_name": "Bash",
  "tool_input": {
    "command": "ls -la",
    "file_path": "/path/to/file"
  }
}
```

### Output Formats

| Scenario | Format |
|----------|--------|
| Allow operation | `exit 0` (no output) |
| Block operation | `exit 2` + stderr message |
| Add context | `{"hookSpecificOutput": {"hookEventName": "PreToolUse", "additionalContext": "message"}}` |
| Stop hook - prevent stop | `{"decision": "block", "reason": "reason"}` |

---

## 2. Common Mistakes

| Mistake | Cause | Solution |
|---------|-------|----------|
| hook error continuously | Using old format `{"decision": "allow"}` | Use `exit 0` |
| Path not loading | `$HOME` variable not expanded | Use absolute paths |
| Hooks overwriting each other | settings.local.json also has config | Clear hooks from all .local.json |

---

## 3. Design Pattern: Global Shared + Namespace

```
~/.claude/hooks/bootstrap-kit/
├── pre-tool-use/
│   ├── security-guard.sh    # Bash security checks
│   ├── git-context.sh       # Git status display
│   ├── file-guard.sh        # Sensitive file warnings
│   └── architecture-guard.sh # Architecture violation detection
├── log-bash-event.sh        # Test/commit logging
├── log-file-change.sh       # File change logging
├── session-start/
│   └── session-start.sh     # Session startup
└── auto/
    └── post_auto_check.sh   # Auto loop control
```

---

## 4. Script Templates

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
exit 0  # No output
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

---

## 5. Key Points

1. **Always consume stdin** - Even if not needed: `cat > /dev/null`
2. **Use jq for JSON** - Safer and more reliable
3. **stderr for block messages** - `echo "message" >&2`
4. **stdout for JSON output** - `hookSpecificOutput` structure
5. **Absolute paths** - Don't use `$HOME` in settings.json
6. **Testing** - Execute command directly and observe for hook errors

---

## 6. Director Mode Lite Hooks

| Script | Type | Purpose |
|--------|------|---------|
| `_lib-changelog.sh` | Library | Shared functions for logging |
| `pre-tool-validator.sh` | PreToolUse | Adds context for sensitive files |
| `log-file-change.sh` | PostToolUse | Logs Write/Edit operations |
| `log-bash-event.sh` | PostToolUse | Logs test results and commits |
| `auto-loop-stop.sh` | Stop | Controls auto-loop continuation |

---

## References

- Claude Code Hooks official documentation
- Director Mode Lite v1.4.1+ implementation
