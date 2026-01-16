---
name: skill-check
description: Validate skill/command file format and structure
user-invocable: true
---

# Skill File Validator

Validate skill files for correct format.

---

## Validation Target

- With argument: validate specific file
- Without: validate all `.claude/skills/*/SKILL.md`

---

## Required Frontmatter

```yaml
---
name: skill-name              # Required
description: What it does     # Required: shown in / menu
user-invocable: true          # Optional: default true
allowed-tools: [Read, Write]  # Optional: restrict tools
context: fork                 # Optional: isolated context
agent: agent-name             # Optional: run as agent
---
```

---

## Validation Checklist

### Frontmatter
- [ ] Exists between `---` markers
- [ ] `description` is present
- [ ] `allowed-tools` are valid (if specified)
- [ ] `agent` file exists (if specified)

### Content
- [ ] Clear instructions
- [ ] Uses `$ARGUMENTS` if expecting input
- [ ] Step-by-step process if complex

---

## Output Format

```markdown
## Skill Validation Report

### Files Checked
| File | Status | Issues |
|------|--------|--------|
| workflow.md | OK | None |
| my-skill.md | WARN | Missing description |

### Summary
- Total: [N]
- Valid: [N]
- Needs fixes: [N]
```

---

## Auto-Fix

- Add missing description
- Remove invalid frontmatter
- Add `$ARGUMENTS` handling
