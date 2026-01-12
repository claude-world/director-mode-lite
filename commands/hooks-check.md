---
description: Validate hooks configuration and scripts
---

# Hooks Validator

Validate hooks configuration in `.claude/settings.json` and hook scripts.

## Validation Steps

### Step 1: Check settings.json

```bash
cat .claude/settings.json
```

Verify `hooks` section exists and is valid.

### Step 2: Validate Hook Structure

```json
{
  "hooks": {
    "PreToolUse": [...],
    "PostToolUse": [...],
    "Stop": [...],
    "Notification": [...]
  }
}
```

- [ ] Valid JSON format
- [ ] Hook types are valid (PreToolUse, PostToolUse, Stop, Notification)
- [ ] Each hook has required fields

### Step 3: Validate Each Hook Entry

```json
{
  "matcher": "Edit",        // Optional: tool name or pattern
  "hooks": [{
    "type": "command",      // Required: "command"
    "command": "./script.sh" // Required: path to script
  }]
}
```

- [ ] `type` is "command"
- [ ] `command` path exists
- [ ] Script is executable (`chmod +x`)

### Step 4: Validate Hook Scripts

For each script in `.claude/hooks/`:

- [ ] File exists and is executable
- [ ] Outputs valid JSON: `{"decision": "allow"}` or `{"decision": "block", ...}`
- [ ] Handles stdin (receives hook input)
- [ ] Has appropriate shebang (`#!/bin/bash`)

### Step 5: Test Hook Output

Run each hook with test input:
```bash
echo '{"hook_type":"Stop"}' | .claude/hooks/auto-loop-stop.sh
```

Verify output is valid JSON.

## Output Format

```markdown
## Hooks Validation Report

### Configuration Status: ✅ VALID / ❌ INVALID

### Configured Hooks
| Type | Matcher | Script | Status |
|------|---------|--------|--------|
| Stop | * | auto-loop-stop.sh | ✅ |
| PreToolUse | Edit | protect-files.sh | ⚠️ Not executable |

### Script Validation
| Script | Exists | Executable | Valid Output |
|--------|--------|------------|--------------|
| auto-loop-stop.sh | ✅ | ✅ | ✅ |
| protect-files.sh | ✅ | ❌ | - |

### Issues Found
1. **Script not executable**: `protect-files.sh`
   - Fix: `chmod +x .claude/hooks/protect-files.sh`

2. **Invalid JSON output**: `my-hook.sh`
   - Output must be: `{"decision": "allow"}` or `{"decision": "block", "reason": "..."}`

### Missing Recommended Hooks
- [ ] Auto-Loop stop hook (for /auto-loop to work)
```

## Auto-Fix Option

Offer to fix:
- Make scripts executable
- Add missing shebang
- Create missing hook scripts from templates

## Reference

For hooks design help, read `.claude/agents/hooks-expert.md`
