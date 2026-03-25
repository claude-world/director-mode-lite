# Frequently Asked Questions

Common questions about Director Mode Lite.

---

## General

### What is Director Mode?

Director Mode is a development methodology where you **direct** Claude Code to execute your vision autonomously, rather than writing code line by line. You become the Director, focusing on "what" and "why", while Claude handles the "how".

### Is this an official Anthropic product?

No. Director Mode Lite is a community project from [Claude World](https://claude-world.com). It works with Claude Code but is not affiliated with Anthropic.

### What's the difference between Director Mode Lite and the full version?

| Feature | Lite (Free) | Full |
|---------|-------------|------|
| Commands | 26 | 85+ |
| Agents | 14 | 35+ |
| Skills | 31 | 60+ |
| Auto-Loop | Yes | Yes |
| Self-Evolving Loop | Yes | Yes |
| Auto-Explore | No | Yes |
| SpecKit | No | Yes |
| Multi-CLI Support | Basic | Advanced |
| Support | Community | Priority |

---

## Installation

### How do I install Director Mode Lite?

**Option A: Plugin Install (Recommended)**
```bash
claude plugin install director-mode-lite
```

**Option B: Clone and Install**
```bash
git clone https://github.com/claude-world/director-mode-lite.git
cd director-mode-lite
./install.sh /path/to/your/project
```

### Can I install it globally?

Yes, install to your project root or `~/.claude/`:
```bash
./install.sh ~/.claude
```

### How do I uninstall?

```bash
./uninstall.sh /path/to/project
```

Or manually remove the `.claude/` directory.

### Will it overwrite my existing CLAUDE.md?

No. The install script:
- Backs up existing `.claude/` directory
- Merges hooks.json (doesn't overwrite)
- Skips files that already exist
- Creates CLAUDE.md only if none exists

---

## Usage

### How do I use Auto-Loop?

```bash
/auto-loop "Implement feature X

Acceptance Criteria:
- [ ] Requirement 1
- [ ] Requirement 2
- [ ] Tests"
```

Auto-Loop will iterate through TDD cycles until all criteria are met.

### How do I stop Auto-Loop?

```bash
touch .auto-loop/stop
```

The loop stops after the current iteration completes.

### How do I resume Auto-Loop?

```bash
rm -f .auto-loop/stop
/auto-loop --resume
```

### What if I don't have acceptance criteria?

Auto-Loop works best with clear acceptance criteria. Without them, it may:
- Run indefinitely
- Not know when to stop
- Miss important requirements

**Tip:** Even simple criteria like "unit tests pass" help Auto-Loop know when it's done.

### Can I use Director Mode with other AI tools?

Yes! Director Mode Lite includes:
- `/handoff-codex` - Delegate to OpenAI's Codex CLI
- `/handoff-gemini` - Delegate to Google's Gemini CLI

---

## Troubleshooting

### Commands not showing up

1. Check installation:
   ```bash
   ls -la .claude/skills/
   ls -la .claude/agents/
   ```

2. Verify Claude Code version:
   ```bash
   claude --version
   ```

3. Run install verification:
   ```bash
   ./scripts/verify-install.sh /path/to/your/project
   ```

4. Restart Claude Code

### Auto-Loop runs forever

- Add clear acceptance criteria
- Set max iterations: `/auto-loop "task" --max-iterations 10`
- Create stop file: `touch .auto-loop/stop`

### Tests fail but Auto-Loop continues

This is expected. Auto-Loop uses TDD:
1. RED: Write failing test
2. GREEN: Make it pass
3. REFACTOR: Clean up

If tests fail in GREEN or REFACTOR phase, the debugger agent investigates.

### Agent not triggered automatically

Agents trigger on specific keywords:
- `code-reviewer`: "review", "quality", before commits
- `debugger`: "bug", "error", "debug", test failures
- `doc-writer`: "document", new features

Or invoke directly by name: "use code-reviewer to review this PR"

### Hooks not firing (Auto-Loop does nothing)

Hooks require `python3` and `jq`:

1. Check dependencies:
   ```bash
   python3 --version
   jq --version
   ```

2. Check hook configuration:
   ```bash
   cat .claude/settings.local.json | grep -A5 "Stop"
   ```

3. If `settings.local.json` is missing or has no hooks section, re-run the install script.

4. Run `/check-environment` for a full diagnostic.

### When should I use Evolving-Loop vs Auto-Loop?

| Scenario | Use `/auto-loop` | Use `/evolving-loop` |
|---|---|---|
| Simple, well-defined tasks | Yes | No |
| Standard TDD is sufficient | Yes | No |
| Complex features with many parts | No | Yes |
| Previous `/auto-loop` attempts failed | No | Yes |
| Need dynamic strategy adaptation | No | Yes |

**Rule of thumb:** Start with `/auto-loop`. If it fails 2+ times on the same task, switch to `/evolving-loop`.

### Evolving-Loop stuck or not progressing

```bash
# Check status
/evolving-status

# View recent events
cat .self-evolving-loop/history/events.jsonl | tail -5

# Force restart
/evolving-loop --force "your task"

# Complete reset
rm -rf .self-evolving-loop/state/* .self-evolving-loop/reports/*
```

### First troubleshooting step

Run the install verification script:
```bash
./scripts/verify-install.sh /path/to/your/project
```

This checks all components and reports PASS/FAIL for each.

---

## Configuration

### How do I customize Claude's behavior?

Edit `CLAUDE.md` in your project root. See [CLAUDE-TEMPLATE.md](CLAUDE-TEMPLATE.md) for options.

### Can I add my own commands?

Yes! Create `.claude/skills/my-command/SKILL.md`:

```markdown
---
description: What this command does
user-invocable: true
---

# My Command

Instructions for Claude...
```

### Can I add my own agents?

Yes! Create `.claude/agents/my-agent.md`:

```markdown
---
name: my-agent
description: What this agent does
model: sonnet
color: cyan
tools:
  - Read
  - Grep
  - Glob
  - Bash
---

# My Agent

You are a specialist in...
```

---

## Contributing

### How do I report a bug?

[Create an issue](https://github.com/claude-world/director-mode-lite/issues/new?template=bug_report.md) with:
- Claude Code version
- Steps to reproduce
- Expected vs actual behavior

### How do I suggest a feature?

[Create a feature request](https://github.com/claude-world/director-mode-lite/issues/new?template=feature_request.md) with:
- Use case
- Proposed solution
- Alternatives considered

### Can I contribute code?

Yes! See [CONTRIBUTING.md](../CONTRIBUTING.md).

---

## More Questions?

- [Discord](https://discord.com/invite/rBtHzSD288)
- [GitHub Issues](https://github.com/claude-world/director-mode-lite/issues)
- [Website](https://claude-world.com)
