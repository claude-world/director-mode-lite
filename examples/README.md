# Director Mode Lite Examples

Real-world examples demonstrating Director Mode workflows.

## Table of Contents

| Example | Description | Difficulty |
|---------|-------------|------------|
| [Calculator](./01-calculator/) | Basic Auto-Loop demo | Beginner |
| [REST API](./02-rest-api/) | Building an API with TDD | Intermediate |

---

## Quick Start

Each example contains:
- `README.md` - Step-by-step instructions
- `CLAUDE.md` - Project-specific configuration
- Sample code to work with

```bash
# Try an example
cd examples/01-calculator
claude
# Then: /auto-loop "Implement the calculator"
```

---

## Example 1: Calculator (Auto-Loop Demo)

**Goal:** Create a calculator module using Auto-Loop

**Commands used:**
- `/auto-loop` - Main workflow

**Time:** ~5 minutes

```bash
/auto-loop "Create a calculator module

Acceptance Criteria:
- [ ] add(a, b) function
- [ ] subtract(a, b) function
- [ ] multiply(a, b) function
- [ ] divide(a, b) function with zero check
- [ ] Unit tests for all functions"
```

---

## Example 2: REST API (TDD Workflow)

**Goal:** Build a simple REST API with proper testing

**Commands used:**
- `/workflow` - Complete 5-step flow
- `/test-first` - TDD cycle
- `/smart-commit` - Commit changes

**Time:** ~15 minutes

---

## Creating Your Own Examples

Want to contribute an example? Follow this structure:

```
examples/
└── NN-example-name/
    ├── README.md       # Instructions
    ├── CLAUDE.md       # Project config
    ├── package.json    # (if Node.js)
    └── src/            # Sample code
```

Submit a PR to the [Director Mode Lite repo](https://github.com/claude-world/director-mode-lite).
