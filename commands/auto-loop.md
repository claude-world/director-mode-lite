---
description: TDD-based autonomous development loop with checkpoint recovery and observability changelog
---

# Auto-Loop

Execute a TDD-based autonomous development loop with full observability.

---

## Execution

When user runs `/auto-loop "<request>"`:

### 1. Initialize

```bash
# Create state directories
mkdir -p .auto-loop
mkdir -p .director-mode

# Initialize checkpoint
cat > .auto-loop/checkpoint.json << 'EOF'
{
  "request": "$ARGUMENTS",
  "current_iteration": 0,
  "max_iterations": 20,
  "status": "in_progress",
  "acceptance_criteria": [],
  "last_test_result": null,
  "files_changed": []
}
EOF

echo "0" > .auto-loop/iteration.txt

# Log session start to changelog
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
echo '{"id":"evt_'$(date +%s)'","timestamp":"'$TIMESTAMP'","event_type":"session_start","agent":"auto-loop","summary":"Started: '$ARGUMENTS'","details":{"request":"'$ARGUMENTS'","max_iterations":20}}' >> .director-mode/changelog.jsonl
```

### 2. Parse Acceptance Criteria

Extract from request and update checkpoint:

```
Input:
  "Implement authentication

  Acceptance Criteria:
  - [ ] Login form (email + password)
  - [ ] JWT token generation
  - [ ] Error handling
  - [ ] Tests > 80% coverage
  "

Parsed checkpoint.json:
{
  "request": "Implement authentication",
  "acceptance_criteria": [
    { "id": 1, "description": "Login form (email + password)", "done": false },
    { "id": 2, "description": "JWT token generation", "done": false },
    { "id": 3, "description": "Error handling", "done": false },
    { "id": 4, "description": "Tests > 80% coverage", "done": false }
  ]
}
```

**Parsing rules:**
- Look for `Acceptance Criteria:` or `AC:` section
- Parse `- [ ]` as pending, `- [x]` as done
- Also accept numbered lists: `1.`, `2.`
- Extract `--max-iterations N` flag

### 3. Execute TDD Cycle

Each iteration uses the included agents and skills:

```
┌───────────────────────────────────────────────────────────────┐
│                      TDD Iteration                            │
├───────────┬───────────────────────────────────────────────────┤
│  RED      │ 1. Write failing test for next AC                 │
│           │ 2. Run test → confirm it FAILS                    │
│           │ → Use test-runner skill                           │
│           │ → Log: iteration_start, file_created, test_fail   │
├───────────┼───────────────────────────────────────────────────┤
│  GREEN    │ 1. Write implementation code                      │
│           │ 2. Run test → confirm it PASSES                   │
│           │ → Use test-runner skill                           │
│           │ → Log: file_created/modified, test_pass           │
├───────────┼───────────────────────────────────────────────────┤
│  REFACTOR │ 1. Improve code quality (no behavior change)      │
│           │ 2. Run tests → confirm still passing              │
│           │ → Use code-reviewer agent for suggestions         │
│           │ → Log: agent_invoked, file_modified               │
├───────────┼───────────────────────────────────────────────────┤
│  DEBUG    │ (Only if tests fail unexpectedly)                 │
│           │ → Use debugger agent to analyze root cause        │
│           │ → Log: agent_invoked, error, decision             │
├───────────┼───────────────────────────────────────────────────┤
│  VALIDATE │ 1. Run full test suite                            │
│           │ 2. Run linter                                     │
│           │ → Use test-runner skill                           │
│           │ → Log: test_run                                   │
├───────────┼───────────────────────────────────────────────────┤
│  COMMIT   │ Commit changes with descriptive message           │
│           │ → Use /smart-commit command                       │
│           │ → Log: commit                                     │
├───────────┼───────────────────────────────────────────────────┤
│  DECIDE   │ Check AC completion status                        │
│           │ → Update checkpoint.json, loop or complete        │
│           │ → Log: ac_completed, iteration_end                │
└───────────┴───────────────────────────────────────────────────┘
```

**Agents & Skills Used:**

| Stage | Tool | Purpose | Changelog Event |
|-------|------|---------|-----------------|
| RED | `test-runner` skill | Write test, verify it fails | `iteration_start`, `test_fail` |
| GREEN | `test-runner` skill | Write code, verify test passes | `file_modified`, `test_pass` |
| REFACTOR | `code-reviewer` agent | Suggest improvements | `agent_invoked` |
| DEBUG | `debugger` agent | Root cause analysis | `agent_invoked`, `error` |
| VALIDATE | `test-runner` skill | Full test suite + lint | `test_run` |
| COMMIT | `/smart-commit` | Conventional commit messages | `commit` |
| DECIDE | - | Check completion | `ac_completed`, `iteration_end` |

### 4. Changelog Integration

**Log events at each phase:**

```bash
# Helper function to log events
log_event() {
  local event_type="$1"
  local summary="$2"
  local iteration=$(cat .auto-loop/iteration.txt)
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
  local event_id="evt_$(date +%s)_$RANDOM"
  
  echo '{"id":"'$event_id'","timestamp":"'$timestamp'","event_type":"'$event_type'","agent":"auto-loop","iteration":'$iteration',"summary":"'$summary'"}' >> .director-mode/changelog.jsonl
}

# Example logging at each phase:
# RED phase start
log_event "iteration_start" "Starting iteration #$iteration - $next_ac"

# After creating test file
log_event "file_created" "Created $test_file"

# After test fails (expected)
log_event "test_fail" "Test fails as expected: $test_name"

# GREEN phase - file created/modified
log_event "file_modified" "Updated $impl_file"

# After test passes
log_event "test_pass" "All tests passing"

# Invoking agent
log_event "agent_invoked" "Invoking code-reviewer for refactoring suggestions"

# After commit
log_event "commit" "$commit_message"

# AC completed
log_event "ac_completed" "AC #$ac_id complete: $ac_description"

# Iteration end
log_event "iteration_end" "Completed iteration #$iteration"
```

**Provide context to subagents:**

When invoking `code-reviewer` or `debugger`, include recent changelog:

```markdown
## Recent Context (from changelog)

$(tail -n 5 .director-mode/changelog.jsonl | jq -r '"[\(.timestamp | split("T")[1] | split(".")[0])] #\(.iteration) \(.event_type): \(.summary)"')

Use this context to understand recent changes.
```

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
│  [ ] 4. Tests > 80% coverage              ← currently 65%   │
├─────────────────────────────────────────────────────────────┤
│  Decision: 2/4 complete → CONTINUE                          │
│  Next RED: Write test for error handling                    │
└─────────────────────────────────────────────────────────────┘
```

**Mark AC as done when:**
- Corresponding test exists AND passes
- For coverage: actual coverage >= target

**Complete when:**
- All AC marked `done: true`
- All tests passing
- Update `status: "completed"`
- Log `session_end` event

**Stop when:**
- `max_iterations` reached → `status: "max_iterations_reached"`
- `.auto-loop/stop` file exists → `status: "stopped"`

---

## Usage

```bash
# Basic
/auto-loop "Implement user login"

# With iteration limit
/auto-loop "Implement login" --max-iterations 15

# With acceptance criteria
/auto-loop "Implement authentication

Acceptance Criteria:
- [ ] Login form (email + password)
- [ ] JWT token generation
- [ ] Error handling
- [ ] Tests > 80% coverage
"

# Resume from checkpoint
/auto-loop --resume

# Check status
/auto-loop --status

# View changelog
/changelog
/changelog --summary
```

---

## Observability

Use `/changelog` to inspect the development session:

```bash
# View recent activity
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
# Remove stop signal
rm -f .auto-loop/stop

# Check changelog for context
/changelog --limit 10

# Resume
/auto-loop --resume
```

---

## Reset

```bash
# Archive changelog before reset (optional)
/changelog --export archived-$(date +%Y%m%d).json

# Clear state
rm -rf .auto-loop
/changelog --clear

# Start fresh
/auto-loop "New task"
```

---

## Community

Questions? Join [Claude World](https://claude-world.com).
