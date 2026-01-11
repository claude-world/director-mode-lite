---
description: TDD-based autonomous development loop with checkpoint recovery
---

# Auto-Loop

Execute a TDD-based autonomous development loop.

---

## Execution

When user runs `/auto-loop "<request>"`:

### 1. Initialize

```bash
# Create state directory
mkdir -p .auto-loop

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
├───────────┼───────────────────────────────────────────────────┤
│  GREEN    │ 1. Write implementation code                      │
│           │ 2. Run test → confirm it PASSES                   │
│           │ → Use test-runner skill                           │
├───────────┼───────────────────────────────────────────────────┤
│  REFACTOR │ 1. Improve code quality (no behavior change)      │
│           │ 2. Run tests → confirm still passing              │
│           │ → Use code-reviewer agent for suggestions         │
├───────────┼───────────────────────────────────────────────────┤
│  DEBUG    │ (Only if tests fail unexpectedly)                 │
│           │ → Use debugger agent to analyze root cause        │
├───────────┼───────────────────────────────────────────────────┤
│  VALIDATE │ 1. Run full test suite                            │
│           │ 2. Run linter                                     │
│           │ → Use test-runner skill                           │
├───────────┼───────────────────────────────────────────────────┤
│  COMMIT   │ Commit changes with descriptive message           │
│           │ → Use /smart-commit command                       │
├───────────┼───────────────────────────────────────────────────┤
│  DECIDE   │ Check AC completion status                        │
│           │ → Update checkpoint.json, loop or complete        │
└───────────┴───────────────────────────────────────────────────┘
```

**Agents & Skills Used:**

| Stage | Tool | Purpose |
|-------|------|---------|
| RED | `test-runner` skill | Write test, verify it fails |
| GREEN | `test-runner` skill | Write code, verify test passes |
| REFACTOR | `code-reviewer` agent | Suggest improvements |
| DEBUG | `debugger` agent | Root cause analysis |
| VALIDATE | `test-runner` skill | Full test suite + lint |
| COMMIT | `/smart-commit` | Conventional commit messages |

### 4. Update Checkpoint

After each iteration:
- Increment `current_iteration`
- Update `acceptance_criteria` status
- Record `files_changed`
- Save `last_test_result`

### 5. DECIDE: Completion Check

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

# Resume
/auto-loop --resume
```

---

## Reset

```bash
rm -rf .auto-loop
/auto-loop "New task"
```

---

## Community

Questions? Join [Claude World](https://claude-world.com).
