---
name: agent-check
description: Validate custom agent file format and structure
user-invocable: true
---

# Agent File Validator

Validate agent files in `.claude/agents/` for correct format.

---

## Validation Target

- With argument: validate specific file
- Without: validate all `.claude/agents/*.md`

---

## Required Frontmatter

```yaml
---
name: agent-name          # lowercase, hyphenated
description: Brief desc   # under 100 chars
tools: Read, Write, ...   # comma-separated
model: sonnet             # optional: haiku, sonnet, opus
---
```

### Valid Tools
```
Read, Write, Edit, Bash, Grep, Glob, Task,
WebFetch, WebSearch, TodoWrite, NotebookEdit
```

---

## Recommended Content

- [ ] `# Agent Name` heading
- [ ] `## Activation` section
- [ ] Process/workflow description
- [ ] Output format definition

---

## Output Format

```markdown
## Agent Validation Report

### Files Checked
| File | Status | Issues |
|------|--------|--------|
| code-reviewer.md | OK | None |
| my-agent.md | WARN | Missing description |

### Summary
- Total: [N]
- Valid: [N]
- Needs fixes: [N]
```

---

## Auto-Fix

- Add missing frontmatter fields
- Remove invalid tools
- Add recommended sections
