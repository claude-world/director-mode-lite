---
name: interop-router
description: "Automatically routes tasks to external AI CLIs (Codex or Gemini) when more efficient; routing decisions are made automatically based on task type, with no manual commands needed. Use when a task is a large refactor, a batch operation, or needs 100K+ tokens of context better handled by an external CLI."
user-invocable: false
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
---

# Automatic Routing to External AI CLIs

**Auto-trigger**: This skill evaluates tasks automatically and decides whether to delegate to an external CLI. No manual invocation needed.

---

## Auto-Trigger Conditions

Automatically evaluate when detecting:
- Large refactoring (10+ files affected)
- Batch file changes
- Template generation tasks
- Multi-model cross-validation needs

---

## Decision Scoring

Calculate delegation score using 3 factors:

| Factor | Range | Description |
|--------|-------|-------------|
| Benefit | 0.0 - 0.6 | Can external CLI produce faster/more reliable results? |
| Cost | -0.3 - 0.0 | Overhead of wrapping, normalizing, reviewing |
| Risk | -0.3 - 0.0 | Permission/write/secret leakage risks |

**Threshold**: Score >= 0.15 with auto-interop enabled -> auto-execute delegation

---

## Routing Targets

| Task Type | Target CLI | Reason |
|-----------|------------|--------|
| Large codebase exploration | Gemini | 1M token context |
| Batch implementation | Codex | Fast bulk generation |
| Complex architecture analysis | Gemini | Deep reasoning |
| Template generation | Codex | Efficient structured output |
| Parallel full-capability delegation (separate account quota) | claude-z-N profiles via /handoff-claude | full Claude Code toolset on another authorized account |

---

## Process

### 1. Check CLI Availability

```bash
# Works for both plugin install (CLAUDE_PLUGIN_ROOT) and local .claude install
IR_DIR="${CLAUDE_PLUGIN_ROOT:-$CLAUDE_PROJECT_DIR/.claude}/skills/interop-router"
bash "$IR_DIR/scripts/check_cli_available.sh" --json
```

Beyond Codex and Gemini, additional authorized `claude` profiles (separate accounts/config dirs — see [/handoff-claude](../handoff-claude/SKILL.md)) are also valid delegation targets when you need the full Claude Code toolset on another account's quota.

### 2. Score the Decision

```bash
IR_DIR="${CLAUDE_PLUGIN_ROOT:-$CLAUDE_PROJECT_DIR/.claude}/skills/interop-router"
python3 "$IR_DIR/scripts/score_decision.py" \
  --task "task description" \
  --files 15 \
  --complexity high \
  --json
```

### 3. Wrap Context (if delegating)

```bash
IR_DIR="${CLAUDE_PLUGIN_ROOT:-$CLAUDE_PROJECT_DIR/.claude}/skills/interop-router"
python3 "$IR_DIR/scripts/wrap_context.py" \
  --files src/*.py \
  --diff \
  --output /tmp/context.md
```

### 4. Execute with External CLI

```bash
# Codex (non-interactive)
codex exec "Your task description" < /tmp/context.md

# Gemini (context piped via stdin; -p carries the prompt)
gemini -p "Your task description" < /tmp/context.md
```

---

## Safety Constraints

- Default read-only mode
- Automatic secret filtering (API keys, passwords, tokens, connection strings)
- All results must be reviewed before landing
- Sensitive files (.env, credentials, private keys) are always skipped

---

## Configuration

Enable auto-interop:

```bash
# Project-level (takes precedence)
mkdir -p .claude/flags
echo '{"enabled": true}' > .claude/flags/auto-interop.json

# User-level
mkdir -p ~/.claude/flags
echo '{"enabled": true}' > ~/.claude/flags/auto-interop.json
```
