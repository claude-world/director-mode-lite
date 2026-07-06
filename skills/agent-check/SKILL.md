---
name: agent-check
description: Validate custom agent file format and structure. Use after creating or editing an agent, before committing agent changes, or when an agent fails to load.
user-invocable: true
---

# Agent File Validator

Validate agent files in `.claude/agents/` for correct format against the
official Claude Code spec (plus Director Mode conventions).

---

## Validation Target

- With argument: validate specific file
- Without: validate all `.claude/agents/*.md`

---

## Required Frontmatter

```yaml
---
name: agent-name          # Required: lowercase, hyphenated, 3-50 chars
description: >            # Required: 10-5000 chars, include triggering conditions + <example> blocks
  Use this agent when [conditions]. Examples:
  <example>
  Context: [situation]
  user: "[request]"
  assistant: "[response using this agent]"
  </example>
color: cyan               # Required by Director Mode convention (CI-enforced); OPTIONAL per official spec
model: sonnet             # Required by Director Mode convention (CI-enforced); OPTIONAL per official spec.
                          #   Valid: fable, opus, sonnet, haiku, inherit, default, best, sonnet[1m], opus[1m]
                          #   (or a full model ID). inherit is the recommended default. NOT opusplan.
effort: medium            # Optional: low, medium, high, xhigh, max
tools:                    # Optional: YAML list (omit = all tools available)
  - Read
  - Write
  - Grep
disallowedTools:          # Optional: explicit tool blocking
  - NotebookEdit
maxTurns: 20              # Optional: max agentic turns (positive integer)
skills:                    # Optional: preloaded skill names (list)
  - linked-skill
memory: project            # Optional: one of user, project, local
background: false          # Optional: run the agent in the background (boolean)
isolation: worktree        # Optional: run the agent in an isolated git worktree
---
```

### Valid Tools
```
Read, Write, Edit, Bash, Grep, Glob, Agent (Task = legacy alias),
Skill, WebFetch, WebSearch, TodoWrite, NotebookEdit, AskUserQuestion
```

### Valid Colors
```
yellow, red, green, blue, magenta, cyan
```

### Valid Models
```
fable, opus, sonnet, haiku, inherit, default, best, sonnet[1m], opus[1m]
(or a full model ID). inherit recommended. NOT opusplan (session-only, invalid for agents).
```

### NOT supported in filesystem/plugin agent frontmatter (WARN if present)
```
hooks           # Root/skill-scoped only; ignored on filesystem/plugin agents
mcpServers      # Not supported on filesystem/plugin agents
permissionMode  # Security restriction — not honored from agent frontmatter
forkContext     # Not an official field (agents fork automatically when dispatched)
```

---

## Validation Checklist

### Required Fields
- [ ] `name` exists (lowercase, hyphenated, 3-50 chars)
- [ ] `description` exists (10-5000 chars, recommend 200-1000 with `<example>` blocks)
- [ ] `color` is set (valid color name) — required by Director Mode convention, optional per spec
- [ ] `model` is set (valid value below) — required by Director Mode convention, optional per spec

### Optional Fields (official)
- [ ] `tools` are valid tool names, YAML list format (omit = all tools available)
- [ ] `disallowedTools` are valid tool names
- [ ] `effort` is one of: low, medium, high, xhigh, max
- [ ] `maxTurns` is a positive integer
- [ ] `skills` is a list of skill names (references existing skills)
- [ ] `memory` is one of: user, project, local
- [ ] `background` is boolean
- [ ] `isolation` is `worktree`
- [ ] `model` is valid: fable, opus, sonnet, haiku, inherit, default, best, sonnet[1m], opus[1m], or a full model ID (NOT opusplan)

### Unsupported / Unknown Fields (WARN, do not silently accept)
- [ ] Warn on `hooks`, `mcpServers`, `permissionMode` — not supported in filesystem/plugin agent frontmatter
- [ ] Warn on `forkContext` — not an official field

### Content Structure
- [ ] `# Agent Name` heading
- [ ] `## Activation` section
- [ ] Process/workflow description
- [ ] Output format definition

### Format Rules
- [ ] `tools` uses YAML list format (not `[Read, Write]` bracket array) — Director Mode / CI house rule
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
- Convert string `skills` to YAML list
- Add missing `color` field (default: cyan)
- Add missing `model` field (default: inherit)
- Remove unsupported fields (`hooks`, `mcpServers`, `permissionMode`) or flag for review
- Remove `forkContext` (not an official field)
- Replace `opusplan` model with a supported value
- Remove invalid tools
- Add recommended sections
