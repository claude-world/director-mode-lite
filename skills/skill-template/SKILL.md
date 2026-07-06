---
name: skill-template
description: Generate custom skill/command from template. Use when creating a new skill or slash command from scratch, or scaffolding a skill file with correct frontmatter.
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
| Agent-backed | Delegator | Runs in a forked subagent |

---

## Process

1. **Gather Requirements**
   - Skill name (lowercase, hyphenated)
   - Purpose
   - Arguments (if any — space-separated names)
   - Workflow steps
   - Context isolation (`context: fork`)?
   - Agent backing (`agent:`, only with `context: fork`)?
   - Tool restrictions?

2. **Select Template** based on purpose

3. **Generate File** at `.claude/skills/[name]/SKILL.md`

4. **Validate** with `/skill-check`

---

## Frontmatter Reference (official fields)

Only `description` is meaningfully required (`name` defaults to the directory
name). All other fields are optional.

```yaml
---
name: skill-name              # Optional: defaults to directory name; lowercase, hyphenated
description: What it does      # Recommended: shown in / menu and used for triggering
when_to_use: When to reach for it  # Optional: appended to description for triggering
                              #   (description + when_to_use truncated at 1,536 chars in listings)
user-invocable: true          # Optional: default true; false hides from / menu (Skill tool still works)
model: sonnet                 # Optional: fable, opus, sonnet, haiku, inherit, default, best,
                              #   sonnet[1m], opus[1m] (or a full model ID). NOT opusplan (session-only)
effort: medium                # Optional: low, medium, high, xhigh, max
allowed-tools:                # Optional: pre-approved tools. Accepts a comma-separated string
  - Read                      #   OR a YAML list — BOTH are official (list shown here as house style)
  - Write
  - Bash
disallowed-tools:             # Optional: explicitly blocked tools (string or YAML list)
  - WebFetch
context: fork                 # Optional: run the skill in a subagent
agent: agent-name             # Optional: subagent type when context: fork (default: general-purpose)
argument-hint: "[issue-number]"  # Optional: autocomplete hint shown after the skill name
arguments: target flags       # Optional: space-separated argument NAMES for $name substitution
                              #   (arguments "target flags" -> use $target and $flags in the body).
                              #   NOT a structured array of name/description/required objects.
disable-model-invocation: false  # Optional: bool; true also blocks scheduled-task invocation
paths:                        # Optional: glob patterns that limit where the skill activates
  - "src/**/*.ts"
shell: bash                   # Optional: bash or powershell for inline !`command` blocks
hooks:                        # Optional: skill-scoped lifecycle hooks (same schema as settings.json)
  PreToolUse:
    - matcher: Bash
      hooks:
        - type: command
          command: echo "Bash used"
  Stop:
    - hooks:
        - type: command
          command: ./scripts/verify.sh
          once: true
---
```

Non-official fields to avoid: `metadata`, `license`, `version` (not part of the
spec). `once` is valid only inside a `hooks[]` entry, never at the top level.

---

## Workflow Template Structure

```markdown
---
name: [name]
description: [What it does. Include when to use it.]
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Bash
  - Grep
  - Glob
context: fork
argument-hint: "<task-description>"
# when_to_use: Use when the user asks about X or mentions Y.  # Optional trigger hint
# arguments: target mode                                      # Optional: names for $target, $mode
---

# [Skill Name]

## Workflow
### Step 1: [Name]
### Step 2: [Name]
### Step 3: [Name]

## Arguments
Uses `$ARGUMENTS` for raw input (or `$name` per the `arguments` field)

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
