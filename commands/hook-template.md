---
description: Generate hook script from template
---

# Hook Template Generator

Generate a hook script and configuration based on requirements.

**Usage**: `/hook-template [hook-type] [purpose]`

## Hook Types

| Type | When it Runs | Use Case |
|------|--------------|----------|
| `PreToolUse` | Before tool executes | Block, validate, modify |
| `PostToolUse` | After tool executes | Log, notify, react |
| `Stop` | When Claude stops | Continue loops |
| `Notification` | On notifications | External alerts |

## Process

### Step 1: Gather Requirements

1. **Hook type**: PreToolUse, PostToolUse, Stop, Notification
2. **Purpose**: What should this hook do?
3. **Matcher**: Which tool(s) to match? (for PreToolUse/PostToolUse)

### Step 2: Generate Script

Create `.claude/hooks/[name].sh`:

## PreToolUse Template (Blocker)

```bash
#!/bin/bash
# Hook: [name]
# Type: PreToolUse
# Purpose: [description]

# Read input from stdin
INPUT=$(cat)

# Parse tool info
TOOL=$(echo "$INPUT" | jq -r '.tool_name')
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Your logic here
# Example: Block edits to protected files
PROTECTED=(".env" ".env.local" "secrets.json")

for pattern in "${PROTECTED[@]}"; do
  if [[ "$FILE" == *"$pattern"* ]]; then
    echo "{\"decision\": \"block\", \"reason\": \"Protected file: $FILE\"}"
    exit 0
  fi
done

# Allow by default
echo '{"decision": "allow"}'
```

## PostToolUse Template (Logger)

```bash
#!/bin/bash
# Hook: [name]
# Type: PostToolUse
# Purpose: [description]

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name')
RESULT=$(echo "$INPUT" | jq -r '.tool_result // empty' | head -c 200)

# Log to file
echo "[$(date '+%Y-%m-%d %H:%M:%S')] $TOOL: $RESULT" >> .claude/hooks.log

# Always allow (post-execution)
echo '{"decision": "allow"}'
```

## Stop Template (Auto-Loop)

```bash
#!/bin/bash
# Hook: auto-loop-stop
# Type: Stop
# Purpose: Continue TDD loop until criteria met

CHECKPOINT=".auto-loop/checkpoint.json"

# No active loop
if [[ ! -f "$CHECKPOINT" ]]; then
  echo '{"decision": "allow"}'
  exit 0
fi

# User requested stop
if [[ -f ".auto-loop/stop" ]]; then
  echo '{"decision": "allow"}'
  exit 0
fi

# Read state
STATUS=$(jq -r '.status' "$CHECKPOINT" 2>/dev/null || echo "unknown")
ITERATION=$(jq -r '.current_iteration' "$CHECKPOINT" 2>/dev/null || echo "0")
MAX=$(jq -r '.max_iterations' "$CHECKPOINT" 2>/dev/null || echo "10")

# Check completion
if [[ "$STATUS" == "complete" ]] || [[ "$ITERATION" -ge "$MAX" ]]; then
  echo '{"decision": "allow"}'
  exit 0
fi

# Continue loop
NEXT=$((ITERATION + 1))
cat << EOF
{
  "decision": "block",
  "prompt": "Continue Auto-Loop iteration $NEXT/$MAX. Read .auto-loop/checkpoint.json for next acceptance criteria to implement using TDD."
}
EOF
```

## Notification Template (Slack)

```bash
#!/bin/bash
# Hook: [name]
# Type: Notification
# Purpose: Send notifications to Slack

INPUT=$(cat)
MESSAGE=$(echo "$INPUT" | jq -r '.message // "Notification from Claude"')

# Send to Slack (requires SLACK_WEBHOOK_URL env var)
if [[ -n "$SLACK_WEBHOOK_URL" ]]; then
  curl -s -X POST "$SLACK_WEBHOOK_URL" \
    -H 'Content-Type: application/json' \
    -d "{\"text\": \"🤖 Claude: $MESSAGE\"}" \
    > /dev/null
fi

echo '{"decision": "allow"}'
```

### Step 3: Update settings.json

Add hook configuration:

```json
{
  "hooks": {
    "[HookType]": [
      {
        "matcher": "[tool-pattern]",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/[name].sh"
          }
        ]
      }
    ]
  }
}
```

### Step 4: Make Executable

```bash
chmod +x .claude/hooks/[name].sh
```

### Step 5: Validate

Run `/hooks-check` to verify configuration.

## Examples

```
User: /hook-template PreToolUse "block edits to package-lock.json"

Creates:
- .claude/hooks/protect-lockfile.sh
- Updates .claude/settings.json

Test: Try to edit package-lock.json, should be blocked
```

```
User: /hook-template PostToolUse "log all bash commands"

Creates:
- .claude/hooks/log-bash.sh
- Updates .claude/settings.json

Test: Run a bash command, check .claude/hooks.log
```
