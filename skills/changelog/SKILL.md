# Changelog Skill

Runtime observability changelog for tracking all changes during development sessions.

---

## Overview

This skill provides a structured changelog system that:
- Records all significant events during development
- Enables subagents to understand context from previous actions
- Supports session recovery and debugging
- Provides observability into the development process

---

## Changelog Location

```
.director-mode/changelog.jsonl
```

JSONL format (one JSON object per line) for efficient append and read operations.

---

## Event Schema

```json
{
  "id": "evt_001",
  "timestamp": "2025-01-13T10:30:00.000Z",
  "event_type": "file_modified",
  "agent": "auto-loop",
  "iteration": 3,
  "summary": "Updated login component with form validation",
  "details": {
    "action": "edit",
    "reason": "Implement email validation for AC #1"
  },
  "files": ["src/components/Login.tsx"],
  "tags": ["feature", "auth"]
}
```

### Event Types

| Type | Description | When Used |
|------|-------------|-----------|
| `session_start` | New development session begins | `/auto-loop` start |
| `session_end` | Session completes or stops | Loop completion |
| `iteration_start` | TDD iteration begins | Each RED phase start |
| `iteration_end` | TDD iteration completes | After COMMIT phase |
| `file_created` | New file created | Write tool |
| `file_modified` | File edited | Edit tool |
| `file_deleted` | File removed | Delete operation |
| `test_run` | Test execution | RED/GREEN/VALIDATE |
| `test_pass` | Tests passing | GREEN phase success |
| `test_fail` | Tests failing | RED phase expected |
| `commit` | Git commit made | COMMIT phase |
| `decision` | Choice point recorded | Architecture decisions |
| `ac_completed` | Acceptance criteria done | AC verification |
| `error` | Error occurred | Any error |
| `agent_invoked` | Subagent called | Delegating to agent |
| `user_input` | User provided input | User interaction |

---

## Operations

### 1. Initialize Changelog

When starting a new session:

```bash
mkdir -p .director-mode

# Write session start event
cat >> .director-mode/changelog.jsonl << 'EOF'
{"id":"evt_001","timestamp":"{{TIMESTAMP}}","event_type":"session_start","agent":"user","summary":"Started: {{REQUEST}}","details":{"request":"{{REQUEST}}","max_iterations":20}}
EOF
```

### 2. Log Event

Append a new event:

```bash
# Generate timestamp and ID
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
EVENT_ID="evt_$(date +%s)"

# Append event (single line JSON)
echo '{"id":"'$EVENT_ID'","timestamp":"'$TIMESTAMP'","event_type":"file_modified","agent":"auto-loop","iteration":3,"summary":"Updated Login.tsx","files":["src/Login.tsx"]}' >> .director-mode/changelog.jsonl
```

### 3. Read Recent Events

Get last N events:

```bash
# Last 10 events
tail -n 10 .director-mode/changelog.jsonl

# Last 5 events, formatted
tail -n 5 .director-mode/changelog.jsonl | jq -s '.'
```

### 4. Query Events

Filter by type or criteria:

```bash
# All test events
grep '"event_type":"test_' .director-mode/changelog.jsonl

# Events from iteration 3
grep '"iteration":3' .director-mode/changelog.jsonl

# All file changes
grep -E '"event_type":"file_(created|modified|deleted)"' .director-mode/changelog.jsonl
```

### 5. Generate Summary

Create a human-readable summary:

```bash
# Count events by type
cat .director-mode/changelog.jsonl | jq -s 'group_by(.event_type) | map({type: .[0].event_type, count: length})'

# List all changed files
cat .director-mode/changelog.jsonl | jq -s '[.[].files // []] | flatten | unique'
```

---

## Subagent Integration

When invoking a subagent, inject recent context:

```markdown
## Recent Context

The following events occurred before your invocation:

{{LAST_5_EVENTS}}

Use this context to understand what has been done and what remains.
```

### Reading Changelog in Agent Prompts

Before invoking `code-reviewer`, `debugger`, or other agents:

1. Read last 5-10 relevant events
2. Format as context block
3. Include in agent prompt

Example:

```
Recent activity:
- [10:30] file_modified: Updated Login.tsx (validation logic)
- [10:28] test_fail: LoginForm.test.tsx - expected validation error
- [10:25] iteration_start: Iteration #3 - AC: Error handling
```

---

## Integration Points

### With Auto-Loop

The auto-loop command should log at these points:

| Phase | Event Type | What to Log |
|-------|------------|-------------|
| Start | `session_start` | Request, AC list |
| RED | `iteration_start`, `test_fail` | Test name, expected failure |
| GREEN | `file_modified`, `test_pass` | Files changed, test results |
| REFACTOR | `file_modified` | Refactoring details |
| DEBUG | `agent_invoked`, `error` | Debugger findings |
| VALIDATE | `test_run` | Full test results |
| COMMIT | `commit` | Commit message, SHA |
| DECIDE | `ac_completed` or `iteration_end` | AC status |

### With Agents

Each agent should:

1. **Read** recent changelog before analysis
2. **Write** their findings/actions to changelog
3. **Reference** changelog entries in their output

---

## Best Practices

1. **Keep summaries concise** - One line, under 80 chars
2. **Include file paths** - Always list affected files
3. **Tag appropriately** - Use tags for filtering
4. **Log decisions** - Record why, not just what
5. **Don't over-log** - Focus on significant events

---

## Example Session

```jsonl
{"id":"evt_001","timestamp":"2025-01-13T10:00:00.000Z","event_type":"session_start","agent":"user","summary":"Started: Implement user login","details":{"request":"Implement user login with email/password","ac":["Login form","Validation","JWT token"]}}
{"id":"evt_002","timestamp":"2025-01-13T10:01:00.000Z","event_type":"iteration_start","agent":"auto-loop","iteration":1,"summary":"RED: Login form test"}
{"id":"evt_003","timestamp":"2025-01-13T10:02:00.000Z","event_type":"file_created","agent":"auto-loop","iteration":1,"summary":"Created Login.test.tsx","files":["src/components/Login.test.tsx"]}
{"id":"evt_004","timestamp":"2025-01-13T10:02:30.000Z","event_type":"test_fail","agent":"auto-loop","iteration":1,"summary":"Test fails as expected: Login component not found","details":{"test":"Login.test.tsx","status":"fail"}}
{"id":"evt_005","timestamp":"2025-01-13T10:05:00.000Z","event_type":"file_created","agent":"auto-loop","iteration":1,"summary":"Created Login.tsx","files":["src/components/Login.tsx"]}
{"id":"evt_006","timestamp":"2025-01-13T10:06:00.000Z","event_type":"test_pass","agent":"auto-loop","iteration":1,"summary":"All tests passing","details":{"passed":1,"failed":0}}
{"id":"evt_007","timestamp":"2025-01-13T10:07:00.000Z","event_type":"commit","agent":"auto-loop","iteration":1,"summary":"feat(auth): add Login component","details":{"sha":"abc1234"}}
{"id":"evt_008","timestamp":"2025-01-13T10:07:30.000Z","event_type":"ac_completed","agent":"auto-loop","iteration":1,"summary":"AC #1 complete: Login form","details":{"ac_id":1}}
```

---

## Clear Changelog

When starting fresh:

```bash
rm -f .director-mode/changelog.jsonl
```

Or archive:

```bash
mv .director-mode/changelog.jsonl .director-mode/changelog.$(date +%Y%m%d_%H%M%S).jsonl
```
