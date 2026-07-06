---
name: handoff-codex
description: Delegate bulk mechanical tasks (mass refactors, template generation, simple batch edits) to OpenAI Codex CLI via non-interactive `codex exec`, preserving Claude context. Use when the user says 'use codex'/'hand off to codex' or a task is 10+ files of mechanical changes.
user-invocable: true
---

# Handoff to Codex CLI

Delegate tasks to OpenAI Codex CLI to save Claude context.

---

## When to Use Codex

| Use Codex For | Keep in Claude |
|---------------|----------------|
| Simple file edits | Complex reasoning |
| Bulk refactoring | Architecture decisions |
| Code generation from specs | Problem analysis |
| Documentation updates | Multi-step workflows |

---

## Prerequisites

```bash
npm install -g @openai/codex
```

---

## Handoff Process

### 1. Prepare Context
```markdown
## Task for Codex
**Goal**: [What needs to be done]
**Files**: [Which files to modify]
**Details**: [Specific requirements]
```

### 2. Generate Command

Always use `codex exec`. Bare `codex` opens the interactive TUI; `codex exec "..."` runs the task non-interactively and exits, which is required when Claude delegates via Bash.

```bash
# Single file
codex exec "Update login function in src/auth.ts to add rate limiting"

# Multiple files
codex exec "Refactor console.log to logger in src/**/*.ts"
```

### 3. Provide Instructions
- Why Codex is suitable
- Expected changes
- After completion steps

---

## Example

```markdown
## Task: Update All Import Statements

**Command:**
codex exec "Update all imports from 'lodash' to 'lodash-es' in src/**/*.ts"

**Expected:**
- ~15 files modified
- Each import updated

**After:**
1. Run `npm test`
2. Return if issues arise
```

---

## Benefits

- **Token Savings**: Simple tasks don't consume Claude context
- **Speed**: Fast for straightforward edits
- **Context Preservation**: Keep Claude fresh for complex reasoning
