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

| Purpose | Template | Tools |
|---------|----------|-------|
| Review/Audit | Reviewer | Read, Grep, Glob |
| Generate/Create | Generator | Read, Write, Grep, Glob |
| Fix/Modify | Fixer | Read, Write, Edit, Bash |
| Test/Validate | Tester | Read, Bash, Grep |
| Document | Documenter | Read, Write, Grep, Glob |

---

## Process

1. **Gather Requirements**
   - Agent name (lowercase, hyphenated)
   - Purpose
   - Tools needed

2. **Select Template** based on purpose

3. **Generate File** at `.claude/agents/[name].md`

4. **Validate** with `/agent-check`

---

## Reviewer Template Structure

```markdown
---
name: [name]
description: [brief purpose]
tools: Read, Grep, Glob
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
