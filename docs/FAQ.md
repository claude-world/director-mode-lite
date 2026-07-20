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
| Commands | 27 | 85+ |
| Agents | 14 | 35+ |
| Skills | 32 | 60+ |
| Auto-Loop | Yes | Yes |
| Self-Evolving Loop | Yes | Yes |
| Auto-Explore | No | Yes |
| SpecKit | No | Yes |
| Multi-CLI Support | Basic | Advanced |
| Support | Community | Priority |

---

## Installation

### How do I install Director Mode Lite?

**Option A: Native Plugin**
```bash
# Register this third-party marketplace once per Claude profile
claude plugin marketplace add claude-world/director-mode-lite

# Install the marketplace-qualified plugin
claude plugin install director-mode-lite@director-mode-lite

# Inside Claude Code, load it without restarting
/reload-plugins
```

The marketplace and plugin commands install the plugin, but they do not attach
hooks to a project. Use the cloned project-integrated path below for hooks; do
not depend on Claude Code's internal, versioned plugin-cache layout.

**Option B: Clone and Install**
```bash
git clone https://github.com/claude-world/director-mode-lite.git
cd director-mode-lite
./install.sh /path/to/your/project --wizard
./scripts/verify-install.sh /path/to/your/project
```

Omit `--wizard` only when you want the documented non-interactive defaults.

### Can I install it globally?

The plugin installs at user scope by default, so its namespaced skills and
agents can be available across projects. Hook configuration remains
project-local. Do not run `./install.sh ~/.claude`; the installer expects a
project root and would create a nested `~/.claude/.claude/` tree.

### How do I uninstall?

```bash
./uninstall.sh /path/to/project
```

Choose **hooks only** to remove Director Mode's five files from the shared
`.claude/hooks/` directory and remove its hook registrations. This preserves
other hook files, agents, skills, `.auto-loop/`, `.director-mode/`, and
`.self-evolving-loop/` state. The complete-removal option is intentionally
broader and removes shared agent/skill/hook directories, so commit or back up
the project before selecting it. Do not replace this review with a blanket
`rm -rf .claude/` command.

### Will it overwrite my existing CLAUDE.md?

No. The install script:
- Backs up existing `.claude/` directory
- Preserves existing settings while adding Director Mode hook events when their event keys are available
- Skips existing agent and skill files; Director Mode's five owned hook filenames are refreshed
- Creates CLAUDE.md only if none exists

If an existing `Stop`, `PreToolUse`, or `PostToolUse` event prevents a Director
Mode registration, the verifier reports the missing hook instead of silently
claiming the setup is ready.

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
- `/handoff-claude` - Delegate to another authorized Claude Code instance (separate account/quota via `CLAUDE_CONFIG_DIR` profiles)

### Do hooks work with a plugin-only install?

Not automatically. Registering the marketplace and installing
`director-mode-lite@director-mode-lite` gives you the plugin's skills and
agents, but Auto-Loop, changelog, and validation hooks are configured in the
project's `.claude/settings.local.json` only by `install.sh`. Clone and inspect
the repository, then run the project-local installer and verifier from that
checkout.

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
   # From the cloned checkout used for project integration
   ./scripts/verify-install.sh /path/to/your/project

   # If the wizard intentionally selected no hooks
   ./scripts/verify-install.sh --allow-no-hooks /path/to/your/project
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

Specifically, it validates dependencies, the 27/14/32 shipped inventory, hook
executability, settings JSON, and at least one registered Director Mode hook.
It accepts an existing custom `CLAUDE.md`; it does not require the bundled
template headings. For an intentionally hook-free wizard setup, use
`--allow-no-hooks`; the inventory is still checked while hook-only requirements
are skipped.

The verifier does not launch Claude Code, invoke commands, run project tests,
or prove that model-generated results are correct. Treat PASS as installation
wiring proof, then run the relevant project tests and review the actual diff.

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
- [Product page](https://claude-world.com/director-mode-lite/)
