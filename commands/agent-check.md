---
description: Validate custom agent file format and structure
---

# Agent File Validator

Validate agent files in `.claude/agents/` for correct format.

## Validation Target

If argument provided: validate that specific file
Otherwise: validate all files in `.claude/agents/*.md`

## Validation Checklist

For each agent file, check:

### Frontmatter (Required)
```yaml
---
name: agent-name          # Required: lowercase, hyphenated
description: Brief desc   # Required: under 100 chars
tools: Read, Write, ...   # Required: comma-separated tool list
model: sonnet             # Optional: haiku, sonnet, opus
---
```

- [ ] Frontmatter exists (between `---` markers)
- [ ] `name` is present and valid (lowercase, no spaces)
- [ ] `description` is present and concise
- [ ] `tools` lists valid tools

### Valid Tools
```
Read, Write, Edit, Bash, Grep, Glob, Task,
WebFetch, WebSearch, TodoWrite, NotebookEdit
```

### Content (Recommended)
- [ ] Has `# Agent Name` heading
- [ ] Has `## Activation` section (when to trigger)
- [ ] Has process/workflow description
- [ ] Has output format definition

## Output Format

```markdown
## Agent Validation Report

### Files Checked
| File | Status | Issues |
|------|--------|--------|
| code-reviewer.md | ✅ | None |
| my-agent.md | ⚠️ | Missing description |

### Detailed Issues

#### my-agent.md
1. **Missing frontmatter field**: `description`
   - Add: `description: What this agent does`

2. **Invalid tool**: `InvalidTool`
   - Valid tools: Read, Write, Edit, Bash, Grep, Glob, Task, WebFetch, WebSearch, TodoWrite

### Summary
- Total agents: [N]
- Valid: [N]
- Needs fixes: [N]
```

## Auto-Fix Option

Offer to fix common issues:
- Add missing frontmatter fields with placeholders
- Remove invalid tools
- Add recommended sections

## Reference

For agent design help, read `.claude/agents/agents-expert.md`
