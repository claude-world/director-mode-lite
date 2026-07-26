<h1 align="center">Director Mode Lite</h1>

<p align="center">
  <strong>Direct work across Claude Code, Codex CLI, and Grok Build.</strong>
</p>

<p align="center">
  <a href="https://github.com/claude-world/director-mode-lite/releases"><img src="https://img.shields.io/github/v/release/claude-world/director-mode-lite" alt="GitHub release"></a>
  <a href="https://github.com/claude-world/director-mode-lite/stargazers"><img src="https://img.shields.io/github/stars/claude-world/director-mode-lite?style=social" alt="GitHub stars"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="MIT license"></a>
</p>

Director Mode Lite is a guidance-first development toolkit. It gives three
agentic CLIs a shared operating brief, reusable skills, adapted agents, and a
portable way to hand unfinished work to one another.

It adds no permission gates, deny rules, or forced workflow. Claude Code,
Codex, and Grok keep their native controls, so users can choose their preferred
trusted/full-access mode without Director Mode getting in the way.

## Quick start

```bash
git clone https://github.com/claude-world/director-mode-lite.git
cd director-mode-lite
./install.sh --cli all /path/to/your-project
```

Then open the project with any supported CLI:

```bash
claude
codex
grok
```

For the product's full-capability, no-prompt profile, use the installed launcher
in a trusted workspace:

```bash
.director-mode/bin/director-open claude
.director-mode/bin/director-open codex
.director-mode/bin/director-open grok
```

It uses each CLI's native open flags—Claude `bypassPermissions`, Codex
`danger-full-access` with approvals disabled, and Grok `always-approve` with
its sandbox off. It does not emulate permissions with hooks. Native managed
policy can still override the flags, and existing global hooks can still run.

Start with the `director-mode` skill. When another CLI should continue, use
`session-relay`.

## What gets shared

| Capability | Canonical source | Claude Code | Codex CLI | Grok Build |
| --- | --- | --- | --- | --- |
| Repository guidance | `portable/GUIDANCE.md` | `CLAUDE.md` + `.director-mode/` | `AGENTS.md` + `.director-mode/` | reads both |
| Skills | `skills/*/SKILL.md` | `.claude/skills/` | `.agents/skills/` | reads Claude-compatible skills |
| Agents | `agents/*.md` | `.claude/agents/*.md` | generated `.codex/agents/*.toml` | generated `.grok/agents/*.md` |
| Optional context hook | `hooks/advisory.sh` | `settings.local.json` | `.codex/hooks.json` | none (passive stdout is ignored) |
| Session continuity | `director-handoff/v1` | new native session | new native session | new native session |
| Open launcher | `scripts/director-open.sh` | native bypass mode | native full-access mode | native always-approve / sandbox off |

Grok's Claude compatibility is reused for skills, so the installer does not
create a second, conflicting `.grok/skills/` tree. Agents receive minimal
native adapters because Claude-specific model, tool, and memory frontmatter is
not portable across every Grok release.

## The operating brief

Before substantial work, keep five things visible:

- Outcome — what should be true at the end.
- Context — the repository facts and prior decisions that matter.
- Constraints — compatibility, scope, time, and user preferences.
- Evidence — tests, build, diff, or inspection that will demonstrate success.
- Next decision — where human judgment adds the most value.

The full guide lives at `.director-mode/GUIDANCE.md` after installation. It is
short by design: permanent instruction files are most useful when they contain
only facts needed in every session; detailed procedures belong in skills.

## Cross-CLI session relay

Claude, Codex, and Grok each store their own native conversation history. A
vendor session ID cannot generally resume in a different vendor's CLI.

Director Mode solves the portable part: it creates JSON and Markdown packets
with the goal, current state, decisions, Git snapshot, verification, blockers,
and next steps. The receiver starts a new native session and reads the packet.

### Leave work for another CLI

```bash
.director-mode/bin/director-relay create \
  --from claude \
  --to codex \
  --goal "Finish the authentication refresh" \
  --summary "API behavior is implemented; UI wiring remains" \
  --completed "Added refresh-token rotation" \
  --decision "Kept cookies httpOnly to match the existing threat model" \
  --next "Update the sign-in form" \
  --verification "API unit tests pass"
```

The relay automatically captures only Git metadata and diff statistics; it
does not read raw transcripts, file contents, credentials, or environment
variables. The packet still contains user-supplied text, paths, and Git
filenames. Review those before sharing it outside the workspace; add
`--reviewed` when you want that review recorded in the packet.

### Continue the latest packet

```bash
# Print a copyable interactive command
.director-mode/bin/director-relay continue --to codex

# Launch only when that is what you want
.director-mode/bin/director-relay continue --to codex --run

# Use a one-shot receiving session
.director-mode/bin/director-relay continue --to grok --headless --run
```

Other relay commands:

```bash
.director-mode/bin/director-relay validate
.director-mode/bin/director-relay show
.director-mode/bin/director-relay list
```

Grok Build also provides `grok import` for Claude Code sessions. That is a
helpful Claude→Grok shortcut; the portable packet remains the three-way format.

## Agents, skills, and hooks

### Agents

The 14 Markdown agents are the source representation. During installation,
Director Mode:

- installs Markdown agents for Claude Code;
- converts each agent to Codex TOML with `name`, `description`, and
  `developer_instructions`;
- generates a minimal Grok Markdown adapter with the shared description and
  role body, leaving Claude-only runtime controls behind.

This adapts the interface without claiming that tool names, models, or runtime
permissions are identical across vendors.

### Skills

The repository ships 35 skills, including 31 user-invocable workflows. The
cross-CLI entry points are:

- `director-mode` — create a concise brief and verification contract;
- `session-relay` — leave or receive portable task state;
- `handoff-claude`, `handoff-codex`, `handoff-grok` — target-specific guidance;
- `interop-router` — suggest a useful next CLI without auto-executing it.

The established workflow, planning, testing, review, debugging, documentation,
and project-health skills remain available. CLI-specific surfaces are described
inside the relevant skill instead of being hidden behind a universal claim.

### Hooks

The default is `none`: session relay, skills, agents, and guidance need no
hook. Optional `--hooks guide` adds useful SessionStart context only for Claude
Code and Codex. Grok loads guidance through `AGENTS.md`; current Grok releases
ignore passive SessionStart stdout, so installing that adapter would add work
without adding context. The optional shared executable:

- consumes the native hook input;
- always exits successfully;
- never returns `deny`, `block`, or a permission decision;
- never launches another CLI.

Hooks are independent of permission mode. In particular, Claude hooks may also
surface in Grok through its compatibility layer. Audit existing user-level
hooks before calling an environment zero-interference.

Project hooks may require native trust or approval in Codex and Grok. Review the
generated config with the CLI's own hook inspection UI.

## Installer

```text
./install.sh [--update] [--wizard]
             [--cli all|claude|codex|grok]
             [--hooks guide|none|automation]
             [target-directory]
```

Common choices:

```bash
# Recommended: all adapters, no active hooks
./install.sh --cli all /path/to/project

# Add non-blocking SessionStart context for Claude and Codex
./install.sh --cli all --hooks guide /path/to/project

# Refresh files installed by Director Mode
./install.sh --update --cli all /path/to/project

# Interactive setup
./install.sh --wizard /path/to/project
```

The installer backs up an existing `.claude/` directory, preserves an existing
project guide, and updates only its marked guidance block. Existing Codex hook
JSON is merged rather than replaced.

### Optional legacy automation

Version 2 defaults to zero-hook guidance. The previous Claude-only Auto-Loop, changelog,
validator, and evolving-loop hook files are not installed or registered unless
you explicitly choose:

```bash
./install.sh --hooks automation /path/to/project
```

This legacy mode is separate from the portable three-CLI layer. Its Stop-hook
continuation behavior is Claude-specific and is not presented as a universal
control mechanism.

## Plugin installs

The repository retains a Claude Code marketplace manifest and adds a Codex
plugin manifest. Plugin managers can expose the shared skills, while the shell
installer remains the complete project-local setup because it also generates
agents, guidance, relay binaries, and optional hook adapters.

## Verify

```bash
./tests/run-tests.sh
./scripts/verify-install.sh /path/to/project
python3 scripts/director-relay.py --help
```

The regression suite covers installer modes, native adapters, advisory hook
behavior, packet creation/validation, metadata-only Git capture, update
behavior, and uninstall preservation.

## Upgrade from 1.x

```bash
git pull
./install.sh --update --cli all /path/to/project
```

The important behavior change is the default: legacy automation is now opt-in.
Existing hook registrations are preserved until you remove them or use the
uninstaller, so review `.claude/settings.local.json` when migrating an already
automated project.

See [MIGRATION.md](docs/MIGRATION.md) and [FAQ.md](docs/FAQ.md) for details.

## Learn

- [Claude World Director Mode guide](https://claude-world.com/director-mode-lite/)
- [Director Mode for Codex CLI](https://openai.claude-world.com/director-mode-lite/)
- [Director Mode for Grok Build](https://grok.claude-world.com/director-mode-lite/)
- [Examples](examples/)
- [Changelog](CHANGELOG.md)

Director Mode Lite is a community project from Claude World. It is not an
official Anthropic, OpenAI, or xAI product.

## License

[MIT](LICENSE)
