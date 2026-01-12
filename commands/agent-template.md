---
description: Generate custom agent from template
---

# Agent Template Generator

Generate a custom agent file based on user requirements.

**Usage**: `/agent-template [agent-name] [purpose]`

## Process

### Step 1: Gather Requirements

If not provided in arguments, ask:
1. **Agent name**: lowercase, hyphenated (e.g., `api-tester`)
2. **Purpose**: What should this agent do?
3. **Tools needed**: What capabilities? (Read-only? Can edit? Run commands?)

### Step 2: Select Template

Based on purpose, choose template type:

| Purpose | Template | Tools |
|---------|----------|-------|
| Review/Audit | Reviewer | Read, Grep, Glob |
| Generate/Create | Generator | Read, Write, Grep, Glob |
| Fix/Modify | Fixer | Read, Write, Edit, Bash |
| Test/Validate | Tester | Read, Bash, Grep |
| Document | Documenter | Read, Write, Grep, Glob |

### Step 3: Generate Agent File

Create `.claude/agents/[name].md`:

## Reviewer Template

```markdown
---
name: [name]
description: [brief purpose - under 100 chars]
tools: Read, Grep, Glob
---

# [Name] Agent

You are a [role] that reviews [target] for [criteria].

## Activation

Automatically activate when:
- User mentions "[keywords]"
- After [trigger event]
- When reviewing [target]

## Review Checklist

### Category 1
- [ ] Check item 1
- [ ] Check item 2

### Category 2
- [ ] Check item 1
- [ ] Check item 2

## Output Format

\`\`\`markdown
## [Name] Review Report

### Status: ✅ PASS / ⚠️ ISSUES / ❌ FAIL

### Findings
| Item | Status | Notes |
|------|--------|-------|
| ... | ✅/❌ | ... |

### Issues Found
1. [Issue and recommendation]

### Summary
[Brief conclusion]
\`\`\`

## Guidelines

- Be specific with file paths and line numbers
- Provide actionable recommendations
- Acknowledge good practices
```

## Generator Template

```markdown
---
name: [name]
description: [brief purpose]
tools: Read, Write, Grep, Glob
---

# [Name] Agent

You generate [output] based on [input/patterns].

## Activation

Automatically activate when:
- User asks to create [target]
- User mentions "generate [target]"

## Process

1. **Analyze** existing patterns in codebase
2. **Identify** conventions and styles
3. **Generate** following the patterns
4. **Validate** output matches conventions

## Output Template

[Provide the template structure this agent generates]

## Guidelines

- Follow existing patterns in the codebase
- Maintain consistency with project conventions
- Include necessary imports/dependencies
```

## Fixer Template

```markdown
---
name: [name]
description: [brief purpose]
tools: Read, Write, Edit, Bash, Grep
---

# [Name] Agent

You fix [type of issues] automatically.

## Activation

Automatically activate when:
- [Error type] occurs
- User mentions "fix [target]"
- After [trigger]

## Process

1. **Identify** the problem
2. **Analyze** root cause
3. **Fix** with minimal changes
4. **Verify** fix works

## Common Fixes

| Issue | Solution |
|-------|----------|
| [Issue 1] | [Fix approach] |
| [Issue 2] | [Fix approach] |

## Output Format

\`\`\`markdown
## Fix Applied

**Issue**: [description]
**Root Cause**: [analysis]
**Fix**: [what was changed]
**Verification**: [how to verify]
\`\`\`
```

### Step 4: Validate and Save

1. Write the file to `.claude/agents/[name].md`
2. Run `/agent-check [name].md` to validate
3. Show the created agent and how to use it

## Example

```
User: /agent-template security-scanner "scan code for vulnerabilities"

Output: Created .claude/agents/security-scanner.md

Usage:
- "Ask security-scanner to review the auth module"
- Will auto-activate on security-related discussions
```
