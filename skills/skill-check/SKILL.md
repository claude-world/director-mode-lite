---
name: skill-check
description: Validate skill/command file format and structure. Use after creating or editing a skill, before committing skill changes, or when a skill fails to load or trigger.
user-invocable: true
---

# Skill File Validator

Validate skill files for correct format against the official Claude Code spec.

---

## Validation Target

- With argument: validate specific file
- Without: validate all `.claude/skills/*/SKILL.md`

---

## Frontmatter Reference (official fields)

Skills support these fields. Only `description` is meaningfully required (a
skill with none of these still loads — `name` defaults to the directory name).

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
                              #   (e.g. arguments "target flags" -> use $target and $flags in the body).
                              #   NOT a structured array of name/description/required objects.
disable-model-invocation: false  # Optional: bool; true also blocks scheduled-task invocation
paths:                        # Optional: glob patterns that limit where the skill activates
  - "src/**/*.ts"
shell: bash                   # Optional: bash or powershell for inline !`command` blocks
hooks:                        # Optional: skill-scoped lifecycle hooks (same schema as settings.json)
  PreToolUse:
    - matcher: Write
      hooks:
        - type: command
          command: ./scripts/validate.sh
  Stop:
    - hooks:
        - type: command
          command: ./scripts/verify.sh
          once: true
---
```

### Valid Tools (for allowed-tools / disallowed-tools)
```
Read, Write, Edit, Bash, Grep, Glob, Agent (Task = legacy alias),
Skill, WebFetch, WebSearch, TodoWrite, NotebookEdit, AskUserQuestion
```

### Non-official fields (flag as warnings, not errors)
```
metadata, license, version   # Not part of the skill spec; harmless but should be removed
once                         # Valid ONLY inside a hooks[] entry, never at skill top level
```

---

## Validation Checklist

### Required / Recommended Fields
- [ ] `description` present (recommended; used for the / menu and triggering)
- [ ] `name`, if present, is lowercase and hyphenated (defaults to directory name if omitted)

### Optional Field Validation
- [ ] `allowed-tools` / `disallowed-tools` are valid tool names
- [ ] `allowed-tools` / `disallowed-tools` are a comma-separated string OR a YAML list (both valid)
- [ ] `model` is a valid value: fable, opus, sonnet, haiku, inherit, default, best, sonnet[1m], opus[1m], or a full model ID (NOT opusplan)
- [ ] `effort` is one of: low, medium, high, xhigh, max
- [ ] `context` is `fork` (if specified)
- [ ] `agent` only set alongside `context: fork` (defaults to general-purpose)
- [ ] `argument-hint` is a string
- [ ] `arguments` is a space-separated string of argument names (NOT a structured array)
- [ ] `when_to_use` is a descriptive string (appended to description for triggering)
- [ ] `disable-model-invocation` is boolean
- [ ] `paths` is a list of glob patterns
- [ ] `shell` is `bash` or `powershell`
- [ ] `user-invocable` is boolean
- [ ] `hooks` has valid structure (matcher + hooks[] with type/command)

### Unknown / Non-official Fields
- [ ] Warn (do not error) on `metadata`, `license`, `version`
- [ ] Warn on `once` used at the top level (only valid inside a hooks[] entry)

### Content Structure
- [ ] Clear instructions
- [ ] Uses `$ARGUMENTS` (or `$name` per `arguments`) if expecting input
- [ ] Step-by-step process if complex

---

## Output Format

```markdown
## Skill Validation Report

### Files Checked
| File | Status | Issues |
|------|--------|--------|
| workflow/SKILL.md | OK | None |
| my-skill/SKILL.md | WARN | Missing description |

### Summary
- Total: [N]
- Valid: [N]
- Needs fixes: [N]
```

---

## Auto-Fix

- Add missing `name` from directory name
- Add missing `description`
- Normalize a comma-separated `allowed-tools` string to a YAML list (house style only — the string form is valid; do NOT flag it as an error)
- Remove non-official fields (`metadata`, `license`, `version`)
- Convert a structured `arguments` array to a space-separated name string
- Replace `opusplan` model with a supported value
- Add `$ARGUMENTS` handling
