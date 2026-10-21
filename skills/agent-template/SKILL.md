---
name: agent-template
description: Generate custom agent from template. Use when creating a new subagent from scratch, or scaffolding an agent file with correct frontmatter.
user-invocable: true
---

# Agent Template Generator

Generate a custom agent file based on requirements.

**Usage**: `/agent-template [agent-name] [purpose]`

---

## Templates

| Purpose | Template | Tools | Color | Model |
|---------|----------|-------|-------|-------|
| Review/Audit | Reviewer | Read, Grep, Glob, Bash | yellow | inherit |
| Generate/Create | Generator | Read, Write, Grep, Glob | cyan | inherit |
| Fix/Modify | Fixer | Read, Write, Edit, Bash, Grep | red | inherit |
| Test/Validate | Tester | Read, Bash, Grep, Glob | green | inherit |
| Document | Documenter | Read, Write, Grep, Glob | cyan | inherit |
| Orchestrate | Orchestrator | Read, Write, Bash, Grep, Glob, Agent | cyan | haiku |

---

## Process

1. **Gather Requirements**
   - Agent name (lowercase, hyphenated)
   - Purpose
   - Tools needed
   - Model (fable/opus/sonnet/haiku/inherit — inherit is the recommended default)
   - Preloaded skills (if any)

2. **Select Template** based on purpose

3. **Generate File** at `.claude/agents/[name].md`

4. **Validate** with `/agent-check`

---

## Frontmatter Reference (official fields)

```yaml
---
name: agent-name            # Required: lowercase, hyphenated (official: <=256 chars, no ':')
description: >              # Required: 200-1000 chars recommended, include <example> blocks.
  Use this agent PROACTIVELY when [triggering conditions]. Examples:
  <example>
  Context: [situation]
  user: "[request]"
  assistant: "[response]"
  <commentary>[why this agent]</commentary>
  </example>
color: cyan                 # Required by Director Mode convention (CI-enforced); optional per spec
model: inherit              # Required by Director Mode convention (CI-enforced); optional per spec.
                            #   Valid: sonnet, opus, haiku, fable, inherit, sonnet[1m], opus[1m],
                            #   or a full model ID (claude-opus-5-5). inherit recommended.
                            #   /model-only values (default, best, opusplan) are not subagent values.
effort: medium              # Optional: low, medium, high, xhigh, max
tools:                      # Optional: YAML list (omit = all tools)
  - Read
  - Write
  - Edit
  - Bash
  - Grep
  - Glob
  - Agent
  - WebFetch
  - WebSearch
  - NotebookEdit
disallowedTools:            # Optional: explicit tool blocking
  - NotebookEdit
maxTurns: 20                # Optional: max agentic turns; output is marked partial at the cap
skills:                     # Optional: preload full skill content (list, at most 32)
  - linked-skill
memory: project             # Optional: persistent memory scope, one of user, project, local
background: false           # Optional: true keeps the agent in the background even when Claude waits
isolation: worktree         # Optional: run the agent in an isolated git worktree
omitClaudeMd: false         # Optional (2.1.271+): true starts without CLAUDE.md files
autoCompactWindow: 200000   # Optional (2.1.296+): auto-compact earlier, 100000-1000000 tokens
experimental:               # Optional (2.1.248+): prompt cache lifetime, 5m or 1h
  cacheTtl: 5m
---
```

**Ignored for plugin subagents** — do not emit these here: `hooks`, `mcpServers`,
`permissionMode`, and `initialPrompt` work in `.claude/agents/`, but Director Mode
also ships its agents as a plugin, where Claude Code ignores them. `forkContext`
is not an official field, and unknown fields are silently ignored.

---

## Reviewer Template Structure

```markdown
---
name: [name]
description: >
  Use this agent PROACTIVELY when [triggering conditions]. Examples:
  <example>
  Context: [situation]
  user: "[request]"
  assistant: "[response]"
  </example>
color: yellow
tools:
  - Read
  - Grep
  - Glob
  - Bash
model: inherit
skills:
  - linked-skill
# maxTurns: 20
# memory: project
---

# [Name] Agent

## Activation
When to trigger

## Review Checklist
- [ ] Check items

## Output Format
Report structure
```

---

## Example

```
/agent-template security-scanner "scan code for vulnerabilities"

Output: Created .claude/agents/security-scanner.md
```
