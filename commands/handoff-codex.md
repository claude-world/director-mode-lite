---
description: Delegate tasks to Codex CLI to save Claude context
---

# Handoff to Codex CLI

> **Director Mode Lite** - Delegate tasks to OpenAI Codex CLI to save Claude context

---

## Overview

Hand off specific tasks to Codex CLI when you want to:
- Save Claude context for complex conversations
- Use Codex's strengths (fast edits, large file handling)
- Compare outputs from different AI models

## Prerequisites

Codex CLI must be installed:
```bash
npm install -g @openai/codex
```

## When to Use Codex

| Use Codex For | Keep in Claude |
|---------------|----------------|
| Simple file edits | Complex reasoning |
| Bulk refactoring | Architecture decisions |
| Code generation from clear specs | Problem analysis |
| Documentation updates | Multi-step workflows |

## Handoff Process

### Step 1: Prepare Context

Summarize the task for Codex:
```markdown
## Task for Codex

**Goal**: [What needs to be done]
**Files**: [Which files to modify]
**Details**: [Specific requirements]
```

### Step 2: Generate Codex Command

Create a command the user can run:

```bash
# Single file edit
codex "Update the login function in src/auth.ts to add rate limiting"

# Multiple files
codex "Refactor all console.log statements to use the logger in src/**/*.ts"

# With context file
codex -c context.md "Implement the changes described in context.md"
```

### Step 3: Provide Instructions

Tell the user:
```markdown
## Codex Handoff

I've prepared this task for Codex. Run the following command:

\`\`\`bash
codex "[task description]"
\`\`\`

**Why Codex?**
- This is a straightforward edit task
- Saves Claude context for your complex questions
- Codex handles bulk edits efficiently

**After Codex completes:**
- Review the changes
- Run tests
- Return here for next steps
```

## Example Handoff

```markdown
## Task: Update All Import Statements

This is a good candidate for Codex because it's a bulk edit operation.

**Command to run:**
\`\`\`bash
codex "Update all imports from 'lodash' to 'lodash-es' in src/**/*.ts"
\`\`\`

**Expected changes:**
- ~15 files will be modified
- Each import statement will be updated

**After completion:**
1. Run `npm test` to verify
2. Come back here if issues arise
```

## Benefits

- **Token Savings**: Simple tasks don't consume Claude's context
- **Speed**: Codex can be faster for straightforward edits
- **Context Preservation**: Keep Claude fresh for complex reasoning
