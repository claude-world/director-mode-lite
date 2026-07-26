# Migrating Director Mode Lite

## 1.x → 2.0

Version 2 is a major behavior change: Director Mode is now guidance-first and
supports Claude Code, Codex CLI, and Grok Build from one installation.

### Upgrade

```bash
git pull
./install.sh --update --cli all /path/to/project
./scripts/verify-install.sh /path/to/project
```

The installer backs up the project's existing `.claude/` directory before
updating distributed files.

### New default

`--hooks none` is the default. Skills, agents, guidance, and the relay remain
fully available without lifecycle scripts. This avoids tool latency, duplicate
compatibility hooks, and session noise.

Optional `--hooks guide` registers a Claude/Codex SessionStart advisory that:

- points to `.director-mode/GUIDANCE.md`;
- mentions `.director-mode/handoffs/latest.md` when present;
- always exits successfully;
- never blocks, denies, or changes permissions.

It deliberately registers no Grok hook because Grok ignores passive hook
stdout and may already discover Claude hooks through its compatibility layer.

The legacy Auto-Loop, changelog, validator, and evolving-loop hooks now require:

```bash
./install.sh --update --hooks automation /path/to/project
```

### Existing 1.x hook registrations

An update preserves existing project settings. If a 1.x project already has
Auto-Loop hooks registered, they do not disappear merely because 2.0 defaults
changed. Review `.claude/settings.local.json` and use `./uninstall.sh` option 1
if you want to remove Director-owned legacy registrations before reinstalling
the advisory setup.

### New cross-CLI assets

An `--cli all` install adds:

```text
.director-mode/GUIDANCE.md
.director-mode/bin/director-relay
.director-mode/bin/director-open
.director-mode/handoff.schema.json
.agents/skills/
.codex/agents/
.codex/hooks.json
.grok/agents/
AGENTS.md
```

`director-open` is the explicit trusted-workspace launcher for native open
permission modes. It does not persistently edit user profiles or use hooks as
an approval bypass.

Grok consumes the shared skills through compatibility without a duplicate
`.grok/skills/` tree. It receives minimal native agent adapters because
Claude-specific model, tool, memory, and turn-limit fields are not universally
portable.

### Session continuity

Do not pass a Claude session ID to Codex or a Codex session ID to Grok. Create a
portable packet instead:

```bash
.director-mode/bin/director-relay create \
  --from claude --to codex \
  --goal "..." --summary "..." --next "..."
```

Then print the target command:

```bash
.director-mode/bin/director-relay continue --to codex
```

The receiver starts a new native session. Its approvals, sandbox, tools, model,
and network configuration remain native.

### Router behavior

The 1.x `interop-router` could cross an internal score threshold and recommend
auto-execution. In 2.0 it only returns a suggestion and a copyable handoff step.
Execution requires an explicit user request or `director-relay ... --run`.

### Permanent guidance

The generated project guide is shorter. Keep only repository facts needed in
every session; move detailed or conditional workflows into skills. Existing
custom project text is preserved, and the installer owns only the block between:

```text
<!-- director-mode-lite:start -->
<!-- director-mode-lite:end -->
```

## 1.8 → 1.9

Version 1.9 introduced `install.sh --wizard`. The 2.0 wizard retains interactive
setup but changes its questions to CLI coverage and guidance style.

## Before 1.8

Older installations may not have an update-aware inventory. The safest path is:

1. Commit or back up the project.
2. Run the current installer with `--update`.
3. Inspect the generated native adapter directories.
4. Run the verifier and the project's own tests.
