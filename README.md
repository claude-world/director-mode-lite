<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/claude-world/director-mode-lite/main/assets/banner-dark.svg">
    <source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/claude-world/director-mode-lite/main/assets/banner-light.svg">
    <img alt="Director Mode Lite" src="https://raw.githubusercontent.com/claude-world/director-mode-lite/main/assets/banner-light.svg" width="600">
  </picture>
</p>

<h1 align="center">Director Mode Lite</h1>

<p align="center">
  <strong>Use Claude Code like a Director, not a Programmer</strong>
</p>

<p align="center">
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License: MIT"></a>
  <a href="https://claude.ai/code"><img src="https://img.shields.io/badge/Claude%20Code-v2.1.4+-blueviolet?logo=anthropic" alt="Claude Code"></a>
  <a href="https://discord.com/invite/rBtHzSD288"><img src="https://img.shields.io/discord/1234567890?color=7289da&label=Discord&logo=discord&logoColor=white" alt="Discord"></a>
  <a href="https://github.com/claude-world/director-mode-lite/stargazers"><img src="https://img.shields.io/github/stars/claude-world/director-mode-lite?style=social" alt="GitHub Stars"></a>
</p>

<p align="center">
  <a href="https://claude-world.com">Website</a> |
  <a href="#quick-start">Quick Start</a> |
  <a href="#whats-included">Features</a> |
  <a href="examples/">Examples</a> |
  <a href="https://discord.com/invite/rBtHzSD288">Discord</a>
</p>

---

<p align="center">
  <i>"Don't write code. Direct Claude to write code for you."</i>
</p>

---

## What is Director Mode?

**Director Mode** is a paradigm shift in AI-assisted development. Instead of writing code line by line, you **direct** Claude to execute your vision autonomously.

```
  Traditional Coding                    Director Mode
  ━━━━━━━━━━━━━━━━━━                    ━━━━━━━━━━━━━━

  You: Write code                       You: Define the vision
  AI:  Follow orders                    AI:  Execute autonomously
       ↓                                     ↓
  Micromanagement                       Strategic oversight
  One task at a time                    Parallel agent execution
  Manual intervention                   Continuous automation
```

### Core Principles

| Principle | Description |
|-----------|-------------|
| **Efficiency First** | Direct execution, minimal interruption |
| **Parallel Processing** | Multiple agents working simultaneously |
| **Autonomous Execution** | AI handles implementation details |
| **Strategic Oversight** | You focus on "what" and "why" |

---

## Key Feature: Auto-Loop

<table>
<tr>
<td width="50%">

### Fully Autonomous TDD Cycle

**Auto-Loop** keeps iterating through the Red-Green-Refactor cycle until all acceptance criteria are met.

No manual intervention needed.

**Stop anytime** with:
```bash
touch .auto-loop/stop
```

</td>
<td width="50%">

```
/auto-loop "Create a calculator

Acceptance Criteria:
- [ ] add(a, b) function
- [ ] subtract(a, b) function
- [ ] Unit tests"

[Iteration 1] RED    → Write test...
[Iteration 2] GREEN  → Implement...
[Iteration 3] REFACTOR → Clean...
[Iteration 4] GREEN  → subtract()...
[Iteration 5] All criteria complete!
```

</td>
</tr>
</table>

---

## Quick Start

### Option A: Plugin Install (Recommended)

```bash
# In Claude Code, run:
/plugin install https://github.com/claude-world/director-mode-lite
```

### Option B: One-Line Install

```bash
curl -fsSL https://raw.githubusercontent.com/claude-world/director-mode-lite/main/install.sh | bash -s .
```

### Option C: Try Demo First

```bash
git clone https://github.com/claude-world/director-mode-lite.git
cd director-mode-lite
./demo.sh ~/director-mode-demo
```

<details>
<summary><strong>Install Features</strong></summary>

- Automatic backup of existing `.claude/` directory
- Merge hooks.json (won't overwrite existing hooks)
- Skip already-installed files
- Uninstall script included

</details>

---

## What's Included

<table>
<tr>
<td valign="top" width="33%">

### Commands (13)

| Command | Purpose |
|---------|---------|
| `/workflow` | 5-step dev flow |
| `/focus-problem` | Problem analysis |
| `/test-first` | TDD cycle |
| `/smart-commit` | Auto commits |
| `/plan` | Task breakdown |
| `/auto-loop` | **TDD loop** |
| `/project-init` | Quick setup |
| `/check-environment` | Env check |
| `/project-health-check` | 7-point audit |
| `/handoff-codex` | Delegate |
| `/handoff-gemini` | Delegate |
| `/agents` | List agents |
| `/skills` | List skills |

</td>
<td valign="top" width="33%">

### Agents (3)

| Agent | Purpose |
|-------|---------|
| `code-reviewer` | Quality, security |
| `debugger` | Error analysis |
| `doc-writer` | Documentation |

**Auto-triggered** when:
- Code modified
- Errors appear
- Features added

</td>
<td valign="top" width="34%">

### Skills (4)

| Skill | Purpose |
|-------|---------|
| `code-reviewer` | Code checklist |
| `test-runner` | TDD support |
| `debugger` | 5-step method |
| `doc-writer` | Doc templates |

**Plus:**
- CLAUDE.md template
- Starter hooks
- Best practices

</td>
</tr>
</table>

---

## The 5-Step Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│    Step 1                Step 2                Step 3           │
│  ┌─────────┐           ┌─────────┐           ┌─────────┐        │
│  │ FOCUS   │    ──►    │ PREVENT │    ──►    │  TEST   │        │
│  │ PROBLEM │           │ OVERDEV │           │  FIRST  │        │
│  └─────────┘           └─────────┘           └─────────┘        │
│       │                     │                     │             │
│  Understand             Only build            Red-Green-        │
│  before coding          what's needed         Refactor          │
│                                                                 │
│                    Step 4                Step 5                 │
│                  ┌─────────┐           ┌─────────┐              │
│           ──►    │DOCUMENT │    ──►    │ COMMIT  │              │
│                  └─────────┘           └─────────┘              │
│                       │                     │                   │
│                  Auto-generated         Conventional            │
│                  documentation          Commits                 │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Parallel Agent Execution

One of Director Mode's key advantages is **parallel processing**:

<table>
<tr>
<td width="50%">

### Traditional (Sequential)

```
Agent 1 ─────►
              Agent 2 ─────►
                            Agent 3 ─────►
                                          Agent 4 ─────►

Total time: 4 × single_agent_time
```

</td>
<td width="50%">

### Director Mode (Parallel)

```
Agent 1 ─────┐
Agent 2 ─────┼────► Results
Agent 3 ─────┤
Agent 4 ─────┘

Total time: max(single_agent_time)
```

</td>
</tr>
</table>

### Example: Problem Analysis

```bash
# Old way: Sequential manual searches
grep -r "authentication" src/
grep -r "login" src/
cat src/auth/index.ts
# ... slow, tedious

# Director Mode: One command, 5 parallel agents
/focus-problem "understand the authentication flow"
```

---

## Agents

<table>
<tr>
<td width="33%">

### `code-reviewer`

Automatically reviews:
- Code quality
- Security vulnerabilities
- Error handling
- Performance
- Test coverage

**Triggers:** Code changes, commits, "review"

</td>
<td width="33%">

### `debugger`

5-step debugging:
1. Capture error info
2. Isolate problem
3. Form hypotheses
4. Investigate
5. Fix & verify

**Triggers:** Errors, test failures, "bug"

</td>
<td width="34%">

### `doc-writer`

Creates and maintains:
- README files
- API documentation
- Code comments
- Architecture docs

**Triggers:** New features, structure changes

</td>
</tr>
</table>

---

## CLAUDE.md Configuration

The `CLAUDE.md` file configures Claude's behavior in your project:

```markdown
# Project: My App
Tech: TypeScript, React, PostgreSQL

# Policies
- Always write tests first
- Use conventional commits
- Document public APIs

# Workflow
- Parallel agents: enabled
- Auto-commit: disabled
- Review before merge: required
```

See [`docs/CLAUDE-TEMPLATE.md`](docs/CLAUDE-TEMPLATE.md) for a complete template.

---

## Comparison

<table>
<tr>
<th></th>
<th>Traditional AI Coding</th>
<th>Director Mode Lite</th>
</tr>
<tr>
<td><strong>Workflow</strong></td>
<td>Ask → Wait → Copy → Test → Repeat</td>
<td>Direct → Auto-execute → Review</td>
</tr>
<tr>
<td><strong>Parallelism</strong></td>
<td>One task at a time</td>
<td>Multiple agents simultaneously</td>
</tr>
<tr>
<td><strong>Automation</strong></td>
<td>Manual intervention needed</td>
<td>Auto-Loop runs until done</td>
</tr>
<tr>
<td><strong>Testing</strong></td>
<td>Often forgotten</td>
<td>TDD built into workflow</td>
</tr>
<tr>
<td><strong>Documentation</strong></td>
<td>Afterthought</td>
<td>Auto-generated</td>
</tr>
</table>

---

## Examples

Learn by doing with hands-on tutorials:

| Example | Description | Time |
|---------|-------------|------|
| [Calculator](examples/01-calculator/) | Auto-Loop TDD demo | 5 min |
| REST API | Building an API with TDD | 15 min |
| Bug Fix | Systematic debugging | 10 min |
| Code Review | Quality and security review | 5 min |

See [examples/](examples/) for full tutorials.

---

## Community

<table>
<tr>
<td align="center" width="33%">
<a href="https://claude-world.com">
<strong>Website</strong><br>
claude-world.com
</a>
</td>
<td align="center" width="33%">
<a href="https://discord.com/invite/rBtHzSD288">
<strong>Discord</strong><br>
Join the community
</a>
</td>
<td align="center" width="34%">
<a href="https://github.com/claude-world/director-mode-lite/issues">
<strong>GitHub Issues</strong><br>
Report bugs, request features
</a>
</td>
</tr>
</table>

---

## Author

**Lucas Wang** ([@lukashanren1](https://x.com/lukashanren1))

- GitHub: [@gn00295120](https://github.com/gn00295120)
- Website: [claude-world.com](https://claude-world.com)

---

## License

MIT License - Free for personal and commercial use.

See [LICENSE](LICENSE) for details.

---

## About Director Mode Lite

This is a **free, open-source toolkit** from the [Claude World](https://claude-world.com) community.

<table>
<tr>
<td width="50%">

**What's included (FREE):**
- 13 Commands
- 3 Agents
- 4 Skills
- Auto-Loop with TDD
- Complete documentation

</td>
<td width="50%">

**Want more?**

Visit [claude-world.com](https://claude-world.com) for:
- Advanced methodologies
- Enterprise support
- Full Director Mode experience

</td>
</tr>
</table>

---

<p align="center">
  <a href="https://claude-world.com">Website</a> |
  <a href="https://discord.com/invite/rBtHzSD288">Discord</a> |
  <a href="https://x.com/lukashanren1">Twitter</a>
</p>

<p align="center">
  <sub>Made with direction by Claude World Taiwan</sub>
</p>
