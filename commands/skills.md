---
description: List available skills
---

# Skills

Skills are specialized capabilities that enhance Claude's performance in specific domains.

## Director Mode Lite Skills

Director Mode Lite includes 4 core skills that align with the workflow commands:

### Available Skills

| Skill | Purpose |
|-------|---------|
| `code-reviewer` | Code quality checklist, security review, PR feedback |
| `test-runner` | Test automation, failure analysis, TDD support |
| `debugger` | 5-step debugging methodology, root cause analysis |
| `doc-writer` | README templates, API docs, code comments |

### Included Workflow Commands

| Command | Function |
|---------|----------|
| `/workflow` | Complete 5-step development flow |
| `/focus-problem` | Problem analysis with Explore agents |
| `/test-first` | TDD: Red-Green-Refactor cycle |
| `/smart-commit` | Conventional Commits automation |
| `/plan` | Task breakdown and planning |
| `/project-health-check` | 7-point project audit |
| `/project-init` | Quick project setup with CLAUDE.md |
| `/check-environment` | Verify development environment |
| `/handoff-codex` | Delegate tasks to Codex CLI |
| `/handoff-gemini` | Delegate tasks to Gemini CLI |

---

## Understanding Skills

Skills differ from agents in that they:

1. **Provide domain knowledge** - Specific expertise (e.g., React, PostgreSQL)
2. **Include best practices** - Recommended patterns for that domain
3. **Define workflows** - Step-by-step processes for common tasks
4. **Integrate with tools** - Connect to MCP servers and external services

---

## Skill Structure

Skills are defined as `.md` files with specific sections:

```markdown
---
name: skill-name
description: What this skill does
allowed-tools: Tool1, Tool2
---

# Skill Name

## Purpose
[What this skill enables]

## Knowledge
[Domain expertise included]

## Workflow
[Steps for common tasks]

## Best Practices
[Recommended approaches]
```

---

## Creating Custom Skills

To add project-specific skills:

1. Create `.claude/skills/` directory
2. Add `.md` files following the skill structure
3. Claude will automatically recognize and use them

Example custom skill:

```markdown
---
name: my-api-skill
description: Knowledge about our internal API
---

# My API Skill

## Endpoints
- GET /api/users - List users
- POST /api/users - Create user

## Authentication
All endpoints require Bearer token.

## Common Patterns
[Project-specific patterns]
```

---

*For the full skills library, visit [claude-world.com](https://claude-world.com)*
