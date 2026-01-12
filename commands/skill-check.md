---
description: Validate skill/command file format and structure
---

# Skill File Validator

Validate skill files in `.claude/commands/` or `.claude/skills/` for correct format.

## Validation Target

If argument provided: validate that specific file
Otherwise: validate all files in `.claude/commands/*.md` and `.claude/skills/*/SKILL.md`

## Validation Checklist

For each skill file, check:

### Frontmatter (Required)
```yaml
---
description: What this skill does   # Required: shown in / menu
user-invocable: true                # Optional: default true
allowed-tools: [Read, Write]        # Optional: restrict tools
context: fork                       # Optional: isolated context
agent: agent-name                   # Optional: run as agent
---
```

- [ ] Frontmatter exists (between `---` markers)
- [ ] `description` is present
- [ ] If `allowed-tools` specified, all tools are valid
- [ ] If `agent` specified, agent file exists

### Content (Required)
- [ ] Has clear instructions after frontmatter
- [ ] Uses `$ARGUMENTS` if expecting user input
- [ ] Has step-by-step process if complex

### Valid Frontmatter Options
| Field | Type | Default | Notes |
|-------|------|---------|-------|
| description | string | required | Shown in / menu |
| user-invocable | boolean | true | Show in menu |
| allowed-tools | array | all | Restrict tools |
| context | string | - | "fork" for isolated |
| agent | string | - | Run as specific agent |

## Output Format

```markdown
## Skill Validation Report

### Files Checked
| File | Status | Issues |
|------|--------|--------|
| workflow.md | ✅ | None |
| my-skill.md | ⚠️ | Missing description |

### Detailed Issues

#### my-skill.md
1. **Missing frontmatter field**: `description`
   - This is required for skills to appear in / menu
   - Add: `description: What this skill does`

2. **References non-existent agent**: `unknown-agent`
   - Either create the agent or remove the `agent` field

### Summary
- Total skills: [N]
- Valid: [N]
- Needs fixes: [N]
```

## Auto-Fix Option

Offer to fix common issues:
- Add missing description
- Remove invalid frontmatter fields
- Add `$ARGUMENTS` handling if skill takes input

## Reference

For skill design help, read `.claude/agents/skills-expert.md`
