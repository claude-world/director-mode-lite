---
name: agents
description: List all available agents (core, expert, self-evolving). Use when the user asks what agents are available or runs /agents.
user-invocable: true
---

# Available Agents

List all agents available in Director Mode Lite.

---

## Core Agents

| Agent | Purpose |
|-------|---------|
| `code-reviewer` | Reviews code for quality, security, and best practices after changes or on PRs |
| `debugger` | Root-cause analysis for errors, test failures, and unexpected behavior |
| `doc-writer` | Creates and maintains README, API docs, and code comments |

---

## Expert Agents

| Agent | Purpose |
|-------|---------|
| `claude-md-expert` | CLAUDE.md design patterns, best practices, and project configuration |
| `mcp-expert` | MCP server configuration, troubleshooting, and discovery |
| `agents-expert` | Creating, configuring, and using custom agents |
| `skills-expert` | Creating, configuring, and managing custom skills and commands |
| `hooks-expert` | Designing and troubleshooting PreToolUse/PostToolUse hooks |

---

## Self-Evolving Agents

Used by [/evolving-loop](../evolving-loop/SKILL.md) to run the autonomous development cycle.

| Agent | Purpose |
|-------|---------|
| `evolving-orchestrator` | Coordinates the loop phases and manages memory; returns brief summaries |
| `requirement-analyzer` | Extracts acceptance criteria, complexity, and implementation strategy |
| `skill-synthesizer` | Generates tailored executor, validator, and fixer skills |
| `completion-judge` | Evaluates validation results and decides continue / evolve / ship |
| `experience-extractor` | Analyzes successes and failures to extract improvement suggestions |
| `skill-evolver` | Applies learning insights to produce improved skill versions |

---

## How Agents Work

1. **Auto-activate** based on context
2. **Follow specific methodologies**
3. **Provide structured output**
4. **Can be explicitly invoked**

---

## Using Agents

```
"Use code-reviewer to check src/auth/"
"I need the debugger - tests are failing"
"Have doc-writer update the API docs"
```

---

## Creating Custom Agents

```markdown
---
name: my-agent
description: What this agent does, and when to use it
color: blue
tools:
  - Read
  - Grep
  - Glob
  - Bash
model: sonnet
---

# Agent Name

## When to Activate
## Process
## Output Format
```

Save to `.claude/agents/my-agent.md`
