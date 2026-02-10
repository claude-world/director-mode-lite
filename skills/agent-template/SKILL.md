---
name: agent-template
description: Generate custom agent from template
user-invocable: true
---

# Agent Template Generator

Generate a custom agent file based on requirements.

**Usage**: `/agent-template [agent-name] [purpose]`

---

## Templates

| Purpose | Template | Tools | Color | Model |
|---------|----------|-------|-------|-------|
| Review/Audit | Reviewer | Read, Grep, Glob, Bash | yellow | sonnet |
| Generate/Create | Generator | Read, Write, Grep, Glob | cyan | sonnet |
| Fix/Modify | Fixer | Read, Write, Edit, Bash, Grep | red | sonnet |
| Test/Validate | Tester | Read, Bash, Grep, Glob | green | sonnet |
| Document | Documenter | Read, Write, Grep, Glob | cyan | sonnet |
| Orchestrate | Orchestrator | Read, Write, Bash, Grep, Glob, Task | cyan | haiku |

---

## Process

1. **Gather Requirements**
   - Agent name (lowercase, hyphenated)
   - Purpose
   - Tools needed
   - Model (haiku/sonnet/opus)
   - Linked skill (if any)

2. **Select Template** based on purpose

3. **Generate File** at `.claude/agents/[name].md`

4. **Validate** with `/agent-check`

---

## Frontmatter Reference

```yaml
---
name: agent-name            # Required: lowercase, hyphenated
description: Brief desc     # Required: under 100 chars
color: cyan                 # Optional: yellow, red, green, blue, magenta, cyan
tools:                      # Required: YAML list format
  - Read
  - Write
  - Edit
  - Bash
  - Grep
  - Glob
  - Task
  - WebFetch
  - WebSearch
  - TodoWrite
  - NotebookEdit
model: sonnet               # Optional: haiku, sonnet, opus (default: sonnet)
skills: linked-skill        # Optional: name of linked skill
memory: user                # Optional: memory scope
maxTurns: 25                # Optional: max agentic turns
---
```

---

## Reviewer Template Structure

```markdown
---
name: [name]
description: [brief purpose]
color: yellow
tools:
  - Read
  - Grep
  - Glob
  - Bash
model: sonnet
skills: [linked-skill]
memory: user
---

# [Name] Agent

## Activation
When to trigger

## Review Checklist
- [ ] Check items

## Output Format
Report structure
```

---

## Example

```
/agent-template security-scanner "scan code for vulnerabilities"

Output: Created .claude/agents/security-scanner.md
```
