---
description: Delegate tasks to Gemini CLI to save Claude context
---

# Handoff to Gemini CLI

> **Director Mode Lite** - Delegate tasks to Google Gemini CLI to save Claude context

---

## Overview

Hand off specific tasks to Gemini CLI when you want to:
- Save Claude context for complex conversations
- Use Gemini's strengths (long context, multimodal)
- Compare outputs from different AI models

## Prerequisites

Gemini CLI must be installed:
```bash
npm install -g @anthropic/gemini-cli  # or official Gemini CLI
```

## When to Use Gemini

| Use Gemini For | Keep in Claude |
|----------------|----------------|
| Long document analysis | Complex coding |
| Multimodal tasks (images) | Architecture decisions |
| Research and summarization | Multi-step workflows |
| Large file comprehension | Problem analysis |

## Handoff Process

### Step 1: Prepare Context

Summarize the task for Gemini:
```markdown
## Task for Gemini

**Goal**: [What needs to be done]
**Files**: [Which files to read/analyze]
**Output**: [What format to return]
```

### Step 2: Generate Gemini Command

Create a command the user can run:

```bash
# Analyze a large file
gemini "Summarize the main components in this large codebase" -f src/**/*.ts

# Research task
gemini "Research best practices for [topic] and provide a summary"

# Document analysis
gemini "Analyze this document and extract key points" -f docs/spec.md
```

### Step 3: Provide Instructions

Tell the user:
```markdown
## Gemini Handoff

I've prepared this task for Gemini. Run the following command:

\`\`\`bash
gemini "[task description]"
\`\`\`

**Why Gemini?**
- This is a long-context task
- Saves Claude context for your coding questions
- Gemini handles large documents well

**After Gemini completes:**
- Copy the relevant output
- Paste it here if you need Claude to act on it
- Continue with your development workflow
```

## Example Handoffs

### Research Task
```markdown
## Task: Research API Best Practices

This is a good candidate for Gemini because it's research-focused.

**Command to run:**
\`\`\`bash
gemini "Research REST API versioning strategies. Summarize pros/cons of: URL versioning, header versioning, and query parameter versioning. Provide recommendation."
\`\`\`

**After completion:**
- Review Gemini's research
- Share relevant findings here
- We'll implement the chosen strategy together
```

### Large File Analysis
```markdown
## Task: Analyze Legacy Codebase

This is a good candidate for Gemini due to large file size.

**Command to run:**
\`\`\`bash
gemini "Analyze this legacy code and identify: 1) Main components, 2) Dependencies, 3) Potential issues" -f src/legacy/**/*.js
\`\`\`

**After completion:**
- Gemini will provide a summary
- Share the key findings here
- We'll plan the refactoring together
```

## Benefits

- **Token Savings**: Research tasks don't consume Claude's context
- **Long Context**: Gemini can handle very large documents
- **Specialization**: Use each AI's strengths
- **Context Preservation**: Keep Claude fresh for coding tasks
