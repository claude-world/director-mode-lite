---
description: TDD-based autonomous development loop with checkpoint recovery and observability changelog
---

# Auto-Loop

Execute a TDD-based autonomous development loop with full observability.

---

## Usage

```bash
# Start new task
/auto-loop "Implement user login"

# With acceptance criteria
/auto-loop "Implement authentication

Acceptance Criteria:
- [ ] Login form (email + password)
- [ ] JWT token generation
- [ ] Error handling
"

# Resume interrupted session
/auto-loop --resume

# Force restart (clear old state)
/auto-loop --force "New task"

# Check status
/auto-loop --status

# With iteration limit
/auto-loop "Task" --max-iterations 15
```

---

## Execution

When user runs `/auto-loop "<request>"`:

### 1. State Detection (Conflict Prevention)

**Before starting, check for existing state:**

```bash
STATE_DIR=".auto-loop"
CHECKPOINT="$STATE_DIR/checkpoint.json"

# Check for existing in-progress session
if [ -f "$CHECKPOINT" ]; then
    status=$(jq -r '.status // "unknown"' "$CHECKPOINT" 2>/dev/null || echo "unknown")
    iteration=$(jq -r '.current_iteration // 0' "$CHECKPOINT" 2>/dev/null || echo "0")
    request=$(jq -r '.request // ""' "$CHECKPOINT" 2>/dev/null || echo "")
    
    if [ "$status" == "in_progress" ]; then
        echo "⚠️  Found interrupted session at iteration #$iteration"
        echo "   Task: $request"
        echo ""
        echo "Options:"
        echo "  /auto-loop --resume        → Continue from iteration #$iteration"
        echo "  /auto-loop --force \"...\"  → Clear old state, start fresh"
        echo ""
        echo "Choose an option to proceed."
        exit 1
    fi
fi
```

**Behavior Matrix:**

| Existing State | Command | Action |
|----------------|---------|--------|
| None | `/auto-loop "task"` | Start new |
| `completed` | `/auto-loop "task"` | Archive & start new |
| `in_progress` | `/auto-loop "task"` | **Block** - prompt user |
| `in_progress` | `/auto-loop --resume` | Continue |
| `in_progress` | `/auto-loop --force "task"` | Archive & start new |
| Any | `/auto-loop --status` | Show status |

### 2. Initialize (with Changelog Rotation)

```bash
# Archive old changelog if exists and > 100 lines
CHANGELOG_DIR=".director-mode"
CHANGELOG="$CHANGELOG_DIR/changelog.jsonl"

if [ -f "$CHANGELOG" ]; then
    line_count=$(wc -l < "$CHANGELOG" | tr -d ' ')
    if [ "$line_count" -gt 100 ]; then
        archive_name="changelog.$(date +%Y%m%d_%H%M%S).jsonl"
        mv "$CHANGELOG" "$CHANGELOG_DIR/$archive_name"
        echo "Archived old changelog to $archive_name"
    fi
fi

# Create state directories
mkdir -p "$STATE_DIR"
mkdir -p "$CHANGELOG_DIR"

# Initialize checkpoint
cat > "$CHECKPOINT" << 'EOF'
{
  "request": "$ARGUMENTS",
  "current_iteration": 0,
  "max_iterations": 20,
  "status": "in_progress",
  "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "acceptance_criteria": [],
  "last_test_result": null,
  "files_changed": []
}
EOF

echo "0" > "$STATE_DIR/iteration.txt"

# Log session start (this will be automatic via hooks for other events)
source .claude/hooks/changelog-logger.sh 2>/dev/null && \
    log_event "session_start" "Started: $ARGUMENTS" "auto-loop" "[]"
```

### 3. Parse Acceptance Criteria

Extract from request and update checkpoint:

```
Input:
  "Implement authentication

  Acceptance Criteria:
  - [ ] Login form (email + password)
  - [ ] JWT token generation
  - [ ] Error handling
  "

Parsed checkpoint.json:
{
  "request": "Implement authentication",
  "acceptance_criteria": [
    { "id": 1, "description": "Login form (email + password)", "done": false },
    { "id": 2, "description": "JWT token generation", "done": false },
    { "id": 3, "description": "Error handling", "done": false }
  ]
}
```

**Parsing rules:**
- Look for `Acceptance Criteria:` or `AC:` section
- Parse `- [ ]` as pending, `- [x]` as done
- Also accept numbered lists: `1.`, `2.`
- Extract `--max-iterations N` flag

### 4. Execute TDD Cycle

Each iteration uses the included agents and skills:

```
┌───────────────────────────────────────────────────────────────┐
│                      TDD Iteration                            │
├───────────┬───────────────────────────────────────────────────┤
│  RED      │ 1. Write failing test for next AC                 │
│           │ 2. Run test → confirm it FAILS                    │
│           │ → Use test-runner skill                           │
│           │ → Auto-logged: file_created, test_fail            │
├───────────┼───────────────────────────────────────────────────┤
│  GREEN    │ 1. Write implementation code                      │
│           │ 2. Run test → confirm it PASSES                   │
│           │ → Use test-runner skill                           │
│           │ → Auto-logged: file_created/modified, test_pass   │
├───────────┼───────────────────────────────────────────────────┤
│  REFACTOR │ 1. Improve code quality (no behavior change)      │
│           │ 2. Run tests → confirm still passing              │
│           │ → Use code-reviewer agent for suggestions         │
│           │ → Auto-logged: file_modified                      │
├───────────┼───────────────────────────────────────────────────┤
│  DEBUG    │ (Only if tests fail unexpectedly)                 │
│           │ → Use debugger agent to analyze root cause        │
│           │ → Auto-logged: test_fail                          │
├───────────┼───────────────────────────────────────────────────┤
│  VALIDATE │ 1. Run full test suite                            │
│           │ 2. Run linter                                     │
│           │ → Use test-runner skill                           │
│           │ → Auto-logged: test_pass/fail                     │
├───────────┼───────────────────────────────────────────────────┤
│  COMMIT   │ Commit changes with descriptive message           │
│           │ → Use /smart-commit command                       │
│           │ → Auto-logged: commit                             │
├───────────┼───────────────────────────────────────────────────┤
│  DECIDE   │ Check AC completion status                        │
│           │ → Update checkpoint.json, loop or complete        │
└───────────┴───────────────────────────────────────────────────┘
```

**Automatic Logging via Hooks:**

All file changes, test results, and commits are automatically logged by PostToolUse hooks. No manual logging required.

| Event | Trigger | Hook |
|-------|---------|------|
| `file_created` | Write tool | `log-file-change.sh` |
| `file_modified` | Edit tool | `log-file-change.sh` |
| `test_pass/fail` | Bash (test commands) | `log-test-result.sh` |
| `commit` | Bash (git commit) | `log-commit.sh` |

### 5. Update Checkpoint

After each iteration:
- Increment `current_iteration`
- Update `acceptance_criteria` status
- Record `files_changed`
- Save `last_test_result`

### 6. DECIDE: Completion Check

At the end of each iteration, check AC status:

```
┌─────────────────────────────────────────────────────────────┐
│  DECIDE - Iteration #3                                      │
├─────────────────────────────────────────────────────────────┤
│  Acceptance Criteria:                                       │
│  [x] 1. Login form (email + password)     ← test passing    │
│  [x] 2. JWT token generation              ← test passing    │
│  [ ] 3. Error handling                    ← NO TEST YET     │
├─────────────────────────────────────────────────────────────┤
│  Decision: 2/3 complete → CONTINUE                          │
│  Next RED: Write test for error handling                    │
└─────────────────────────────────────────────────────────────┘
```

**Mark AC as done when:**
- Corresponding test exists AND passes

**Complete when:**
- All AC marked `done: true`
- All tests passing
- Update `status: "completed"`
- Log `session_end` event

**Stop when:**
- `max_iterations` reached → `status: "max_iterations_reached"`
- `.auto-loop/stop` file exists → `status: "stopped"`

---

## Flags

| Flag | Description |
|------|-------------|
| `--resume` | Continue interrupted session |
| `--force` | Clear old state, start fresh |
| `--status` | Show current session status |
| `--max-iterations N` | Set iteration limit (default: 20) |

---

## Observability

Use `/changelog` to inspect the development session:

```bash
# View recent activity (auto-logged by hooks)
/changelog

# Get summary statistics
/changelog --summary

# Filter by type
/changelog --type test
/changelog --type file

# Export for analysis
/changelog --export session-$(date +%Y%m%d).json
```

---

## Stop Hook

The plugin includes a Stop Hook that:
1. Intercepts exit attempts
2. Checks checkpoint status
3. Re-injects TDD prompt if not complete
4. Allows exit when done or max reached

**Files:** `hooks/hooks.json` + `hooks/auto-loop-stop.sh`

---

## Interrupt

```bash
# Create stop signal
touch .auto-loop/stop
```

Loop stops after current iteration completes.

---

## Resume

```bash
# Check what was interrupted
/auto-loop --status

# View changelog for context
/changelog --limit 10

# Resume
/auto-loop --resume
```

---

## Reset

```bash
# Force restart with new task
/auto-loop --force "New task"

# Or manually clear
rm -rf .auto-loop
/changelog --clear
```

---

## Concurrent Session Protection

**Only one auto-loop session per project.**

If you try to start a new session while one is in progress:

```
⚠️  Found interrupted session at iteration #3
   Task: Implement user login

Options:
  /auto-loop --resume        → Continue from iteration #3
  /auto-loop --force "..."   → Clear old state, start fresh

Choose an option to proceed.
```

This prevents:
- Checkpoint conflicts
- Changelog confusion
- File editing race conditions

---

## Community

Questions? Join [Claude World](https://claude-world.com).
