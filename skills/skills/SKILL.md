---
name: skills
description: List all available skills grouped by category. Use when the user asks what skills are available or runs /skills.
user-invocable: true
---

# Available Skills

List all skills available in Director Mode Lite.

---

Slash-prefixed names (`/name`) are user-invocable commands. Bare names are internal — Claude runs them automatically when relevant.

## Workflow

| Skill | Function |
|-------|----------|
| `/workflow` | Complete 5-step development flow (research, plan, implement, test, review) |
| `/plan` | Break a task into a detailed execution plan |
| `/focus-problem` | Deep problem analysis using Explore agents |
| `/test-first` | Test-Driven Development (Red-Green-Refactor) |
| `/smart-commit` | Conventional Commits with pre-commit quality checks |

---

## Loops

| Skill | Function |
|-------|----------|
| `/auto-loop` | Autonomous TDD loop with checkpoint recovery |
| `/evolving-loop` | Self-evolving loop that generates and evolves its own skills |
| `/evolving-status` | View evolving-loop session status, history, and memory |
| `/changelog` | View and manage the runtime observability changelog |

---

## Setup & Health

| Skill | Function |
|-------|----------|
| `/getting-started` | Guided 5-minute onboarding for Director Mode Lite |
| `/project-init` | Expert-guided project setup (6 phases) |
| `/project-health-check` | Full project health audit (7 checks) |
| `/check-environment` | Verify the development environment is ready |
| `/agents` | List all available agents |
| `/skills` | List all available skills |

---

## Validators

| Skill | Function |
|-------|----------|
| `/claude-md-check` | Validate CLAUDE.md structure and completeness |
| `/agent-check` | Validate agent file format and structure |
| `/skill-check` | Validate skill/command file format and structure |
| `/hooks-check` | Validate hooks configuration and scripts |
| `/mcp-check` | Validate MCP configuration |

---

## Generators

| Skill | Function |
|-------|----------|
| `/claude-md-template` | Generate a CLAUDE.md for the current project |
| `/agent-template` | Generate a custom agent from template |
| `/skill-template` | Generate a custom skill/command from template |
| `/hook-template` | Generate a hook script from template |

---

## Handoff / Interop

| Skill | Function |
|-------|----------|
| `/handoff-claude` | Delegate to another authorized Claude Code account/profile via `claude -p` |
| `/handoff-codex` | Delegate bulk mechanical tasks to OpenAI Codex CLI (`codex exec`) |
| `/handoff-gemini` | Delegate long-context analysis to Google Gemini CLI (`gemini -p`) |

---

## Internal (model-invoked)

Not slash commands — Claude activates these automatically when it judges them relevant.

| Skill | Function |
|-------|----------|
| `code-reviewer` | Reviews code for quality, security, and best practices |
| `debugger` | Root-cause analysis and problem resolution |
| `doc-writer` | Writes README, API docs, and code comments |
| `test-runner` | Runs tests and ensures coverage |
| `interop-router` | Auto-routes eligible tasks to an external CLI (Codex/Gemini) |

---

## Creating Custom Skills

```markdown
---
name: my-skill
description: What this skill does
user-invocable: true
---

# Skill Name

## Purpose
## Workflow
## Output
```

Save to `.claude/skills/my-skill/SKILL.md`
