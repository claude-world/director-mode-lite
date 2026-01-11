# Director Mode Lite

> **Use Claude Code like a Director, not a Programmer**

A free, community-shared toolkit to transform your Claude Code experience. Based on the Director Mode methodology from [claude-world.com](https://claude-world.com).

---

## What is Director Mode?

Director Mode is a mindset shift in how you use AI coding assistants:

```
Traditional Mode          Director Mode
━━━━━━━━━━━━━━━           ━━━━━━━━━━━━━━━
You: Write code            You: Direct the vision
AI: Follows orders         AI: Executes autonomously
Micromanagement           High-level oversight
One task at a time        Parallel agent execution
```

**Key Principles:**

1. **Efficiency First** - Direct execution, minimal interruption
2. **Parallel Processing** - Multiple agents working simultaneously
3. **Autonomous Execution** - AI handles implementation details
4. **Strategic Oversight** - You focus on the "what" and "why"

---

## What's Included

### Commands (13)

| Command | Description |
|---------|-------------|
| `/workflow` | Complete 5-step development flow |
| `/focus-problem` | Problem analysis with Explore agents |
| `/test-first` | TDD: Red-Green-Refactor cycle |
| `/smart-commit` | Conventional Commits automation |
| `/plan` | Task breakdown and planning |
| `/project-health-check` | 7-point project audit |
| `/project-init` | Quick project setup with CLAUDE.md |
| `/check-environment` | Verify development environment |
| `/auto-loop` | **TDD-based autonomous loop** |
| `/handoff-codex` | Delegate to Codex CLI (save tokens) |
| `/handoff-gemini` | Delegate to Gemini CLI (save tokens) |
| `/agents` | List available agents |
| `/skills` | List available skills |

### Agents (3)

| Agent | Purpose |
|-------|---------|
| `code-reviewer` | Code quality, security, best practices |
| `debugger` | Error analysis and fix recommendations |
| `doc-writer` | README, API docs, code comments |

### Skills (4)

| Skill | Purpose |
|-------|---------|
| `code-reviewer` | Code quality checklist, security review |
| `test-runner` | Test automation, TDD support |
| `debugger` | 5-step debugging methodology |
| `doc-writer` | Documentation templates |

### CLAUDE.md Template

A starter template for your project's AI behavior configuration.

---

## Quick Start

### 1. Install to Your Project

```bash
# Clone this repository
git clone https://github.com/claude-world/director-mode-lite.git

# Option A: Use install script (recommended - backup + merge)
./director-mode-lite/install.sh /path/to/your-project

# Option B: Manual copy
cp -r director-mode-lite/.claude your-project/
cp director-mode-lite/docs/CLAUDE-TEMPLATE.md your-project/CLAUDE.md
```

**Install script features:**
- Automatic backup of existing `.claude/` directory
- Merge hooks.json (won't overwrite existing hooks)
- Skip already-installed files

### 2. Start Using Commands

```bash
# In your project with Claude Code
/workflow           # Start the 5-step development flow
/focus-problem      # Analyze a specific problem
/auto-loop          # Start TDD autonomous loop
```

### 3. Uninstall (if needed)

```bash
./director-mode-lite/uninstall.sh /path/to/your-project
```

### 4. Customize CLAUDE.md

Edit `CLAUDE.md` in your project root to configure Claude's behavior.

---

## The 5-Step Workflow

Director Mode Lite centers on a proven development workflow:

```
Step 1: Focus Problem     (/focus-problem)
   │    Understand before coding
   ▼
Step 2: Prevent Overdev   (YAGNI principle)
   │    Only build what's needed
   ▼
Step 3: Test First        (/test-first)
   │    Red → Green → Refactor
   ▼
Step 4: Document          (Auto-documented)
   │    Code is self-explanatory
   ▼
Step 5: Smart Commit      (/smart-commit)
        Conventional Commits
```

---

## Parallel Agent Execution

One of Director Mode's key advantages is parallel processing:

```markdown
Traditional (Sequential):
Agent 1 → Agent 2 → Agent 3 → Agent 4
Total time: 4 × single_agent_time

Director Mode (Parallel):
Agent 1 ─┐
Agent 2 ─┼─→ Results aggregated
Agent 3 ─┤
Agent 4 ─┘
Total time: max(single_agent_time)
```

### Example: Problem Analysis

Instead of manually searching:

```bash
# Old way: Sequential manual searches
grep -r "authentication" src/
grep -r "login" src/
cat src/auth/index.ts
# ... (slow, tedious)

# Director Mode: Parallel Explore agent
/focus-problem "understand the authentication flow"
# Claude automatically launches 5 parallel agents
```

---

## Agents

### code-reviewer

Automatically reviews code for:
- Code quality and readability
- Security vulnerabilities
- Error handling
- Performance issues
- Test coverage

**Triggers automatically when:**
- Code is modified
- Before commits
- User mentions "review"

### debugger

Systematic debugging process:
1. Capture error information
2. Isolate the problem
3. Form hypotheses
4. Investigate systematically
5. Fix and verify

**Triggers automatically when:**
- Errors appear
- Tests fail
- User mentions "bug", "error", "debug"

### doc-writer

Creates and maintains:
- README files
- API documentation
- Code comments
- Architecture docs

**Triggers automatically when:**
- New features added
- Code structure changes
- User mentions "document"

---

## CLAUDE.md Configuration

The `CLAUDE.md` file in your project root configures Claude's behavior.

### Key Sections

```markdown
# Project Information
- Project name and purpose
- Tech stack
- Directory structure

# Development Policies
- Code style preferences
- Testing requirements
- Documentation standards

# Workflow Preferences
- Parallel vs sequential execution
- Confirmation requirements
- Auto-commit policies
```

See `docs/CLAUDE-TEMPLATE.md` for a complete template.

---

## Community

- **Website**: [claude-world.com](https://claude-world.com)
- **Discord**: [Claude World Taiwan](https://discord.gg/claude-world)
- **GitHub Issues**: Report bugs and request features

---

## License

MIT License - Free for personal and commercial use.

---

## About

Director Mode Lite is maintained by the Claude World community. It represents the core concepts from Director Mode methodology, shared freely to help developers work more effectively with Claude Code.

For advanced features, enterprise support, or custom implementations, visit [claude-world.com](https://claude-world.com).

---

*"Don't write code. Direct Claude to write code for you."*
