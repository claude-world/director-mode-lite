---
name: handoff-gemini
description: Delegate long-context analysis, research, and large-document summarization to Google Gemini CLI (1M-token context) via non-interactive `gemini -p`, preserving Claude context. Use when the user says 'use gemini'/'hand off to gemini' or a task needs 100K+ tokens of context.
user-invocable: true
---

# Handoff to Gemini CLI

Delegate tasks to Google Gemini CLI to save Claude context.

---

## When to Use Gemini

| Use Gemini For | Keep in Claude |
|----------------|----------------|
| Long document analysis | Complex coding |
| Multimodal tasks | Architecture decisions |
| Research and summarization | Multi-step workflows |
| Large file comprehension | Problem analysis |

---

## Prerequisites

```bash
# Install Gemini CLI (Google)
npm install -g @google/gemini-cli
# Or via: https://github.com/google-gemini/gemini-cli
```

---

## Handoff Process

### 1. Prepare Context
```markdown
## Task for Gemini
**Goal**: [What needs to be done]
**Files**: [Which files to analyze]
**Output**: [What format to return]
```

### 2. Generate Command

Pass the prompt with `-p` (non-interactive). Reference files or directories inline with `@<path>`, or pipe content via stdin. There is no `-f` flag.

```bash
# Analyze a directory (@ reads it recursively)
gemini -p "Summarize the components in @src/"

# Research task (no file context)
gemini -p "Research best practices for [topic]"

# Document analysis (single file via @)
gemini -p "Extract key points from @docs/spec.md"

# Large or generated context via stdin
cat docs/spec.md | gemini -p "Extract key points"
```

> **Note**: A `src/**/*.ts`-style glob only expands if the shell has globstar enabled (`shopt -s globstar` in bash). Prefer a directory reference like `@src/`, which Gemini reads recursively without relying on shell globbing.

### 3. Provide Instructions
- Why Gemini is suitable
- Expected output
- How to continue workflow

---

## Example

```markdown
## Task: Research API Best Practices

**Command:**
gemini -p "Research REST API versioning strategies. Summarize pros/cons."

**After:**
- Review research
- Share relevant findings
- Implement chosen strategy
```

---

## Benefits

- **Token Savings**: Research tasks don't consume Claude context
- **Long Context**: Handles very large documents
- **Specialization**: Use each AI's strengths
