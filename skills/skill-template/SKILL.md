---
name: skill-template
description: Generate custom skill/command from template
user-invocable: true
---

# Skill Template Generator

Generate a custom skill (slash command) based on requirements.

**Usage**: `/skill-template [skill-name] [purpose]`

---

## Templates

| Purpose | Template | Features |
|---------|----------|----------|
| Workflow | Multi-step | Sequential steps |
| Generator | Creator | File creation |
| Checker | Validator | Validation rules |
| Automation | Runner | Command execution |
| Utility | Helper | Single action |

---

## Process

1. **Gather Requirements**
   - Skill name (lowercase, hyphenated)
   - Purpose
   - Arguments (if any)
   - Workflow steps

2. **Select Template** based on purpose

3. **Generate File** at `.claude/skills/[name]/SKILL.md`

4. **Validate** with `/skill-check`

---

## Workflow Template Structure

```markdown
---
name: [name]
description: [What it does]
user-invocable: true
---

# [Skill Name]

## Workflow
### Step 1: [Name]
### Step 2: [Name]
### Step 3: [Name]

## Arguments
Uses `$ARGUMENTS` for input

## Output
Summary when complete
```

---

## Example

```
/skill-template deploy-staging "deploy to staging"

Output: Created .claude/skills/deploy-staging/SKILL.md

Usage: /deploy-staging
```
