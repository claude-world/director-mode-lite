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
name: agent-name          # Required: lowercase, hyphenated
description: Brief desc   # Required: under 100 chars
color: cyan               # Recommended: yellow, red, green, blue, magenta, cyan
tools:                    # Required: YAML list format
  - Read
  - Write
  - Grep
model: sonnet             # Recommended: haiku, sonnet, opus
skills: linked-skill      # Optional: name of linked skill
memory: user              # Optional: memory scope
maxTurns: 25              # Optional: max agentic turns
---
```

### Valid Tools
```
Read, Write, Edit, Bash, Grep, Glob, Task,
WebFetch, WebSearch, TodoWrite, NotebookEdit
```

### Valid Colors
```
yellow, red, green, blue, magenta, cyan
```

### Valid Models
```
haiku, sonnet, opus
```

---

## Validation Checklist

### Required Fields
- [ ] `name` exists (lowercase, hyphenated)
- [ ] `description` exists (under 100 chars)
- [ ] `tools` exists (YAML list format, not bracket array)

### Recommended Fields
- [ ] `color` is set (valid color name)
- [ ] `model` is set (haiku/sonnet/opus)

### Optional Fields
- [ ] `skills` references existing skill (if set)
- [ ] `memory` is valid scope (if set)
- [ ] `maxTurns` is positive number (if set)

### Content Structure
- [ ] `# Agent Name` heading
- [ ] `## Activation` section
- [ ] Process/workflow description
- [ ] Output format definition

### Format Rules
- [ ] `tools` uses YAML list format (not `[Read, Write]` bracket array)
- [ ] No duplicate tools in list
- [ ] All tools are valid tool names

---

## Output Format

```markdown
## Agent Validation Report

### Files Checked
| File | Status | Issues |
|------|--------|--------|
| code-reviewer.md | OK | None |
| my-agent.md | WARN | Missing color, model |

### Summary
- Total: [N]
- Valid: [N]
- Needs fixes: [N]
```

---

## Auto-Fix

- Convert bracket array tools to YAML list format
- Add missing `color` field (default: cyan)
- Add missing `model` field (default: sonnet)
- Remove invalid tools
- Add recommended sections
