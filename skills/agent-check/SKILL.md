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
skills:                    # Optional: preloaded skill names (list, at most 32)
  - linked-skill
memory: project            # Optional: one of user, project, local
background: false          # Optional: true keeps the agent in the background (boolean)
isolation: worktree        # Optional: run the agent in an isolated git worktree
omitClaudeMd: false        # Optional (2.1.271+): true starts without CLAUDE.md files
autoCompactWindow: 200000  # Optional (2.1.296+): integer, 100000-1000000
---
```

### Valid Tools
```
Read, Write, Edit, Bash, Grep, Glob, Agent (Task = legacy alias),
Skill, WebFetch, WebSearch, TodoWrite, NotebookEdit, AskUserQuestion
(TodoWrite is only offered on older models unless CLAUDE_CODE_ENABLE_TODO_TOOLS=1;
list an MCP server as mcp__<whole server name>__*)
```

### Valid Colors
```
red, blue, green, yellow, purple, orange, pink, cyan
```

### Valid Models
```
sonnet, opus, haiku, fable, inherit, sonnet[1m], opus[1m], or a full model ID
(claude-opus-5-5). inherit recommended. Not default, best, or opusplan (/model values).
```

### Ignored for plugin subagents (WARN if present)
```
hooks           # Honored in .claude/agents/; ignored when loaded from a plugin
mcpServers      # Honored in .claude/agents/; ignored when loaded from a plugin
permissionMode  # Honored in .claude/agents/; ignored when loaded from a plugin
initialPrompt   # Main-session agents only; ignored when loaded from a plugin
```
Director Mode ships its agents as a plugin too, so its catalog omits them.
`forkContext` is not an official field: flag it as unknown.

---

## Validation Checklist

### Required Fields
- [ ] `name` exists (lowercase, hyphenated; official limit 256 chars, no `:`, no leading `-`)
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
- [ ] `background` and `omitClaudeMd` are boolean
- [ ] `isolation` is `worktree`
- [ ] `autoCompactWindow` is an integer from 100000 to 1000000
- [ ] `experimental` holds only `cacheTtl: 5m | 1h`
- [ ] `model` is valid: sonnet, opus, haiku, fable, inherit, sonnet[1m], opus[1m], or a full model ID

### Plugin-Ignored / Unknown Fields (WARN, do not silently accept)
- [ ] Warn on `hooks`, `mcpServers`, `permissionMode`, `initialPrompt` — ignored for plugin subagents
- [ ] Flag any other field outside the official list (for example `forkContext`): Claude Code ignores it silently

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
- Remove plugin-ignored fields (`hooks`, `mcpServers`, `permissionMode`, `initialPrompt`) or flag for review
- Remove `forkContext` and other unknown fields
- Replace `default`, `best`, or `opusplan` model values with a supported value
- Remove invalid tools
- Add recommended sections
