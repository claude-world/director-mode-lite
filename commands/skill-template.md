---
description: Generate custom skill/command from template
---

# Skill Template Generator

Generate a custom skill (slash command) based on user requirements.

**Usage**: `/skill-template [skill-name] [purpose]`

## Process

### Step 1: Gather Requirements

If not provided in arguments, ask:
1. **Skill name**: lowercase, hyphenated (e.g., `deploy-staging`)
2. **Purpose**: What should this skill do?
3. **Arguments**: Does it take user input?
4. **Steps**: What's the workflow?

### Step 2: Select Template

| Purpose | Template | Features |
|---------|----------|----------|
| Workflow | Multi-step | Sequential steps |
| Generator | Creator | File creation |
| Checker | Validator | Validation rules |
| Automation | Runner | Command execution |
| Utility | Helper | Single action |

### Step 3: Generate Skill File

Create `.claude/commands/[name].md`:

## Workflow Template

```markdown
---
description: [What this skill does - shown in / menu]
---

# [Skill Name]

[Brief description of what this skill accomplishes]

## Workflow

### Step 1: [Name]
[Instructions for first step]

### Step 2: [Name]
[Instructions for second step]

### Step 3: [Name]
[Instructions for third step]

## Arguments

This skill accepts: `$ARGUMENTS`

- If no arguments: [default behavior]
- With arguments: [how to use them]

## Output

When complete, show:
\`\`\`markdown
## ✅ [Skill Name] Complete

[Summary of what was done]

### Next Steps
1. [Suggestion]
\`\`\`
```

## Generator Template

```markdown
---
description: Generate [what] from template
---

# [Name] Generator

Generate a new [target] based on project patterns.

## Usage

\`/[skill-name] [target-name]\`

## Process

1. **Check** if target already exists
2. **Analyze** existing patterns
3. **Generate** new [target]
4. **Validate** structure

## Template

\`\`\`[language]
[The template content to generate]
\`\`\`

## Output Location

- File: [where to create]
- Test: [corresponding test file]

## After Generation

1. Show created files
2. Suggest next steps
```

## Checker Template

```markdown
---
description: Check [what] for [criteria]
---

# [Name] Checker

Validate [target] against [standards/rules].

## Checks

### Required
- [ ] [Check 1]
- [ ] [Check 2]

### Recommended
- [ ] [Check 1]
- [ ] [Check 2]

## Output

\`\`\`markdown
## [Name] Check Results

### Status: ✅ PASS / ⚠️ WARNINGS / ❌ FAIL

| Check | Status | Notes |
|-------|--------|-------|
| ... | ... | ... |
\`\`\`

## Auto-Fix

If issues found, offer to fix automatically.
```

## Runner Template

```markdown
---
description: Run [what] automatically
---

# [Name] Runner

Execute [process] with proper handling.

## Commands

\`\`\`bash
[command 1]
[command 2]
\`\`\`

## Error Handling

If command fails:
1. Show error output
2. Suggest fix
3. Offer to retry

## Success Output

\`\`\`markdown
## ✅ [Name] Complete

[Results summary]
\`\`\`
```

### Step 4: Validate and Save

1. Write to `.claude/commands/[name].md`
2. Run `/skill-check [name].md` to validate
3. Show how to use: `/[skill-name] [args]`

## Examples

```
User: /skill-template deploy-staging "deploy to staging environment"

Output: Created .claude/commands/deploy-staging.md

Usage: /deploy-staging
```

```
User: /skill-template generate-api-route "create new API endpoint"

Output: Created .claude/commands/generate-api-route.md

Usage: /generate-api-route users
       /generate-api-route products
```
