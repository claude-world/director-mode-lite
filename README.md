# Director Mode Lite

> **Use Claude Code like a Director, not a Programmer**

A free, community-shared toolkit to transform your Claude Code experience. Based on the Director Mode methodology from [claude-world.com](https://claude-world.com).

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-v2.1.4+-blue)](https://claude.ai/code)
[![Discord](https://img.shields.io/discord/1234567890?color=7289da&label=Discord&logo=discord&logoColor=white)](https://discord.com/invite/rBtHzSD288)

---

## ⭐ Key Feature: Auto-Loop

**Fully autonomous TDD development cycle** - Claude keeps iterating until all acceptance criteria are met.

```
You: /auto-loop "Create a calculator module

Acceptance Criteria:
- [ ] add(a, b) function
- [ ] subtract(a, b) function
- [ ] Unit tests"

Claude: [Iteration 1] RED → Write failing test...
        [Iteration 2] GREEN → Implement add()...
        [Iteration 3] REFACTOR → Clean up...
        [Iteration 4] GREEN → Implement subtract()...
        [Iteration 5] ✓ All criteria complete!
```

No manual intervention needed. Stop anytime with `touch .auto-loop/stop`.

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

### Option A: Plugin Install (Recommended)

```bash
# In Claude Code, run:
/plugin marketplace add claude-world/director-mode-marketplace
/plugin install director-mode-lite
```

### Option B: Script Install

```bash
# One-liner install to current project
curl -fsSL https://raw.githubusercontent.com/claude-world/director-mode-lite/main/install.sh | bash -s .

# Or clone and install
git clone https://github.com/claude-world/director-mode-lite.git /tmp/dml
/tmp/dml/install.sh /path/to/your-project
rm -rf /tmp/dml
```

### Option C: Try Demo First

```bash
git clone https://github.com/claude-world/director-mode-lite.git
cd director-mode-lite
./demo.sh ~/director-mode-demo
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

- 🌐 **Website**: [claude-world.com](https://claude-world.com)
- 💬 **Discord**: [Claude World Community](https://discord.com/invite/rBtHzSD288)
- 🐛 **Issues**: [GitHub Issues](https://github.com/claude-world/director-mode-lite/issues)

---

## Author

**Lucas Wang** ([@lukashanren1](https://x.com/lukashanren1))

- GitHub: [@gn00295120](https://github.com/gn00295120)
- Website: [claude-world.com](https://claude-world.com)

---

## License

MIT License - Free for personal and commercial use.

---

## About

Director Mode Lite is a free, open-source toolkit from the [Claude World](https://claude-world.com) community. It represents the core concepts from the Director Mode methodology, shared freely to help developers work more effectively with Claude Code.

**What's included (free):**
- 13 Commands, 3 Agents, 4 Skills
- Auto-Loop with TDD cycle
- Complete documentation

**Want more?** Visit [claude-world.com](https://claude-world.com) for advanced methodologies, enterprise support, and the full Director Mode experience.

---

<p align="center">
  <i>"Don't write code. Direct Claude to write code for you."</i>
</p>

---

<p align="center">
  <a href="https://claude-world.com">Website</a> •
  <a href="https://discord.com/invite/rBtHzSD288">Discord</a> •
  <a href="https://x.com/lukashanren1">Twitter</a>
</p>
