# Migrating Director Mode Lite

## 1.x → 2.1

Version 2 is a major behavior change: Director Mode is now guidance-first and
supports Claude Code, Codex CLI, and Grok Build from one installation.

### Upgrade

```bash
git pull
./install.sh --update --cli all --hooks none /path/to/project
./scripts/verify-install.sh /path/to/project
```

The installer backs up the project's existing `.claude/` directory before
updating distributed files. It merges shipped skill files in place and keeps
unrelated user files already present in the skill directories.

Choose the hook mode explicitly on every update. The command above
intentionally migrates to zero Director-owned hooks. Use `--hooks guide` or
`--hooks automation` when updating those opt-in surfaces instead. Existing
non-Director project, user, or plugin hooks remain under their native CLI.

Managed write paths are checked before installation. A symlinked destination
component or a final file with multiple hard links stops the update; resolve
that path explicitly rather than allowing the installer to write through it.

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

### Existing 1.x or 2.0 hook registrations

Use the default update mode to retire Director-owned hook state:

```bash
./install.sh --update --hooks none /path/to/project
./scripts/verify-install.sh --hooks none /path/to/project
```

The migration removes Director registrations and unmodified owned hook assets.
It preserves unrelated custom hooks and locally modified files; the verifier
names any preserved Director asset that still needs a human decision.

This ownership check is exact. Product-local commands must reference the full
`.director-mode/...` asset path. Generic legacy `.claude/hooks/...` names are
pruned only when the ownership inventory proves Director installed that file,
so an unowned same-name custom hook is preserved. Automation mode warns when
such a conflict would otherwise be overwritten.

### New cross-CLI assets

An `--cli all` install adds:

```text
.director-mode/GUIDANCE.md
.director-mode/bin/director-relay
.director-mode/bin/director-open
.director-mode/bin/director-doctor
.director-mode/handoff.schema.json
.agents/skills/
.codex/agents/
.codex/hooks.json             # only with --hooks guide|automation
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

For a read-only post-migration audit, run:

```bash
python3 scripts/director-doctor.py --cwd /path/to/project --json --no-probe
```

`runtime.source` reports whether the doctor selected a project-local, user, or
bundled plugin runtime. It inspects project/user Claude and Codex hook configs
and every discovered Grok `hooks/*.json` file. Malformed or shape-invalid hook
files are listed under `hooks.invalid_surfaces`, not treated as zero-hook.
Doctor exit zero means the report was generated, not that it is healthy:
require empty `runtime.missing`, `runtime.issues`, and
`hooks.invalid_surfaces`, plus `hooks.known_registrations == 0`, for that
conclusion. Use `verify-install.sh` as the pass/fail installation gate.

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

Protocol v2 preserves multi-hop lineage with `--parent`. Run
`director-relay status --json` before receiving to compare the checkpoint with
the live worktree; v1 packets remain readable.

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
