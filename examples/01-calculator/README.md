# Example: Calculator with Auto-Loop

A beginner-friendly demonstration of Auto-Loop's TDD workflow.

## What You'll Learn

- How Auto-Loop automatically iterates through Red-Green-Refactor
- How acceptance criteria drive development
- How to stop and resume Auto-Loop

## Prerequisites

- Claude Code v2.1.4+
- Director Mode Lite installed
- Node.js (for running tests)

## Setup

```bash
# From the director-mode-lite directory
cd examples/01-calculator

# Start Claude Code
claude
```

## Step 1: Run Auto-Loop

In Claude Code, run:

```
/auto-loop "Create a calculator module

Acceptance Criteria:
- [ ] add(a, b) function
- [ ] subtract(a, b) function
- [ ] multiply(a, b) function
- [ ] divide(a, b) function with zero check
- [ ] Unit tests for all functions"
```

## Step 2: Watch the Magic

Auto-Loop will:

1. **RED** - Write a failing test for `add()`
2. **GREEN** - Implement `add()` to pass the test
3. **REFACTOR** - Clean up code
4. **VALIDATE** - Run full test suite
5. **COMMIT** - Save progress
6. **DECIDE** - Check completion, continue to next AC

Repeat for each acceptance criterion.

## Step 3: Review Results

When complete, you'll have:

```
01-calculator/
├── calculator.js      # Implementation
├── calculator.test.js # Tests
├── package.json       # Updated with test script
└── .auto-loop/        # Checkpoint data
    └── checkpoint.json
```

## Expected Output

```
╔═══════════════════════════════════════════════════════╗
║               Auto-Loop Complete!                      ║
╠═══════════════════════════════════════════════════════╣
║  Iterations: 8                                         ║
║  Status: completed                                     ║
╠═══════════════════════════════════════════════════════╣
║  Acceptance Criteria:                                  ║
║  [x] add(a, b) function                               ║
║  [x] subtract(a, b) function                          ║
║  [x] multiply(a, b) function                          ║
║  [x] divide(a, b) function with zero check            ║
║  [x] Unit tests for all functions                     ║
╚═══════════════════════════════════════════════════════╝
```

## Try These Variations

### Stop and Resume

```bash
# In another terminal, create stop signal
touch .auto-loop/stop

# Auto-Loop will stop after current iteration
# Resume later with:
/auto-loop --resume
```

### Check Status

```
/auto-loop --status
```

### Reset and Start Over

```bash
rm -rf .auto-loop
/auto-loop "New calculator with power function..."
```

## Key Concepts Demonstrated

| Concept | Description |
|---------|-------------|
| **TDD Cycle** | Red → Green → Refactor |
| **Acceptance Criteria** | Clear completion conditions |
| **Autonomous Loop** | No manual intervention needed |
| **Checkpoint** | Progress saved, can resume |
| **Stop Hook** | Graceful interruption |

## Next Steps

Try [Example 2: REST API](../02-rest-api/) for a more complex workflow.

---

Questions? Join [Claude World](https://claude-world.com).
