---
name: workflow
description: "Run the complete 5-step development workflow: focus problem → prevent over-development → test-first (TDD) → document → smart commit. Use when starting a new feature, or when the user runs /workflow or asks for the full development flow."
user-invocable: true
---

# Development Workflow

A structured approach to software development that emphasizes understanding, minimal implementation, testing, documentation, and clean commits.

---

## Overview

```
Step 1: Focus Problem    → Understand before coding
Step 2: Prevent Overdev  → Only build what's needed (YAGNI)
Step 3: Test First       → Red-Green-Refactor
Step 4: Document         → Keep it clear and current
Step 5: Smart Commit     → Conventional Commits
```

---

## Step 1: Focus Problem (`/focus-problem`)

**Goal:** Thoroughly understand the problem before writing code.

### Checklist
- [ ] What is the user need? (Who / What / Why)
- [ ] What defines success? (How to verify completion?)
- [ ] What are the boundaries? (What NOT to do?)
- [ ] What files/modules are affected?
- [ ] Is there existing similar functionality?

### Use Explore Agent

(Use the active provider's native dispatcher; Claude pseudo-code is shown
below.)

Before dispatch, preserve the bounded exploration request and expected result.
If Claude's Agent tool is unavailable or withheld, or Codex's `spawn_agent`
interface is unavailable or withheld, the maximum depth is reached, or a
concurrency limit rejects the call, do not retry or substitute assumptions.
Return an incomplete `dispatch_request` and do not advance the workflow.

Choose exactly one provider-native form:

- Claude Code: `Agent(subagent_type="Explore", model="haiku", prompt="<bounded prompt>")`
- Codex CLI: `spawn_agent(agent_type="explorer", task_name="workflow_explore", message="<bounded prompt>")`

```markdown
Agent(subagent_type="Explore", model="haiku", prompt="""
Explore the codebase for: [feature name] (thoroughness: medium)
Find related files, similar implementations, and test patterns.
""")
```

In Codex, send the same exploration request through `spawn_agent(...)`; do not
invoke the Claude example as a second dispatch.

---

## Step 2: Prevent Overdev

**Goal:** Ensure minimal viable implementation (YAGNI principle).

### Red Flags
```
"We might need this later..." → Don't build it now
"Just in case..." → YAGNI
"Let's make it generic..." → Solve current problem only
"We should create a framework..." → Write concrete implementation
```

### Checklist
- [ ] Is there immediate need for this?
- [ ] Is this over-abstracted?
- [ ] Can this be simpler?
- [ ] Are we adding unnecessary dependencies?

---

## Step 3: Test First (`/test-first`)

**Goal:** Strict TDD (Red-Green-Refactor).

### Red Phase (Write Failing Test)
- [ ] Write a test for expected behavior
- [ ] Run test, confirm it fails
- [ ] Failure message clearly indicates the issue

### Green Phase (Minimal Implementation)
- [ ] Write minimum code to pass test
- [ ] Don't optimize yet
- [ ] Run test, confirm it passes

### Refactor Phase
- [ ] Clean up code (keep tests passing)
- [ ] Remove duplication
- [ ] Improve naming
- [ ] Simplify logic

---

## Step 4: Document

**Goal:** Ensure code is understandable.

### Checklist
- [ ] README describes purpose and usage
- [ ] Public APIs have docstrings
- [ ] Complex logic has comments explaining "why"
- [ ] No obvious-comment clutter

---

## Step 5: Smart Commit (`/smart-commit`)

**Goal:** Clean version history with Conventional Commits.

### Format
```
<type>(<scope>): <description>
```

### Types
- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation
- `test` - Tests
- `refactor` - Code restructure

---

## Quick Start

```bash
# Run full workflow
/workflow

# Or individual steps
/focus-problem "implement user login"
/test-first
/smart-commit
```

---

## Related Skills

| Skill | Purpose |
|-------|---------|
| `/focus-problem` | Step 1: Problem analysis |
| `/test-first` | Step 3: TDD cycle |
| `/smart-commit` | Step 5: Create commit |
| `/plan` | Break down complex tasks |
