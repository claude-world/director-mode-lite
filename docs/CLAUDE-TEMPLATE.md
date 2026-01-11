# [Project Name] - Claude Code Configuration

> **Purpose**: This file configures Claude Code behavior for this project.
> **Location**: Place in your project root as `CLAUDE.md`

---

## Project Overview

**Project**: [Your project name]
**Tech Stack**: [e.g., Node.js + TypeScript + PostgreSQL]
**Purpose**: [Brief description of what this project does]

---

## Directory Structure

```
project-root/
├── src/           # Source code
├── tests/         # Test files
├── docs/          # Documentation
├── .claude/       # Claude Code configuration
│   ├── commands/  # Custom slash commands
│   └── agents/    # Custom agents
└── CLAUDE.md      # This file
```

---

## Core Policies

### 1. Efficiency First

**Default behavior**: Execute directly, minimal asking.

```
Local operations (safe, git can recover):
✅ All file operations (Write/Edit/Read)
✅ All local git operations (add/commit/branch)
✅ All development tasks (implement/test/refactor)
→ Execute immediately, brief explanation (1-2 sentences)

Remote operations (need confirmation):
❌ git push (especially --force)
❌ Cloud resource deletion
❌ Database DROP operations
→ Ask for confirmation first
```

### 2. Parallel Processing

When tasks can be decomposed into independent subtasks:

```
Use parallel agents:
✅ Multiple file searches
✅ Multi-angle code review
✅ Independent module analysis

Don't use parallel agents:
❌ Tasks with dependencies
❌ Simple single operations
```

### 3. Development Workflow

Follow the 5-step workflow:

1. **Focus Problem** (`/focus-problem`)
   - Understand before coding
   - Identify affected files

2. **Prevent Overdev** (YAGNI)
   - Only implement what's needed
   - No "future-proofing"

3. **Test First** (`/test-first`)
   - Red: Write failing test
   - Green: Minimal implementation
   - Refactor: Clean up

4. **Document**
   - Code should be self-explanatory
   - Comments for "why", not "what"

5. **Smart Commit** (`/smart-commit`)
   - Conventional Commits format
   - One commit per logical change

---

## Code Standards

### Style

- [Your linting configuration]
- [Your formatting preferences]
- [Your naming conventions]

### Testing

- Minimum coverage: [e.g., 80%]
- Test location: `tests/` or co-located
- Framework: [e.g., Jest, pytest, Go testing]

### Documentation

- README required for each module
- JSDoc/docstrings for public APIs
- Architecture decisions in `docs/`

---

## Project-Specific Rules

### [Add your project-specific rules here]

Example rules:

```
Database:
- Always use migrations (never direct schema changes)
- Verify table structure before writing queries

API:
- Follow RESTful conventions
- Version all endpoints (/api/v1/)

Security:
- Never commit secrets
- Use environment variables for configuration
```

---

## Forbidden Actions

Things Claude should never do automatically:

- [ ] Delete production data
- [ ] Push to main branch directly
- [ ] Modify authentication logic without review
- [ ] Remove existing tests
- [ ] [Add your own forbidden actions]

---

## Quick Reference

### Available Commands

```bash
/workflow           # Full 5-step development
/focus-problem      # Analyze problem
/test-first         # TDD cycle
/smart-commit       # Create commit
/plan               # Break down tasks
/project-health-check  # Audit project
```

### Available Agents

- `code-reviewer` - Code quality review
- `debugger` - Error analysis
- `doc-writer` - Documentation

---

## Notes

[Add any project-specific notes for Claude here]

---

*This configuration follows Director Mode methodology from [claude-world.com](https://claude-world.com)*
