# Director Mode Lite FAQ

## Product and scope

### What is Director Mode Lite?

It is a guidance-first operating kit for Claude Code, Codex CLI, and Grok
Build. It helps you define outcomes, provide context, coordinate agents, verify
work, and leave portable state for another CLI.

### Is it an official Anthropic, OpenAI, or xAI product?

No. It is an open-source community project from Claude World.

### Does it restrict permissions?

No. Director Mode adds no deny rule, permission gate, forced approval, or
mandatory workflow. Native CLI controls remain user-selected, including a
trusted/full-access mode when desired. The default install registers no hooks.

### How do I start the full-capability profile?

In a trusted workspace, use the installed launcher:

```bash
.director-mode/bin/director-open claude
.director-mode/bin/director-open codex
.director-mode/bin/director-open grok
```

This selects the current CLI's native open mode. Managed organization policy
can still override it, and native hooks still execute; the launcher does not
pretend prompt text can grant authority.

### Why guidance instead of a large policy file?

Concise, specific instructions are easier for agents to apply consistently and
consume less context. Director Mode keeps permanent guidance small and moves
task procedures into on-demand skills.

## Three-CLI support

### Which CLIs are first-class?

- Claude Code (`claude`)
- OpenAI Codex CLI (`codex`)
- xAI Grok Build (`grok`)

### How are skills shared?

Claude uses `.claude/skills/`; Codex receives the same skill directories under
`.agents/skills/`; Grok reads the Claude-compatible skill tree directly. The
installer avoids a duplicate `.grok/skills/` copy that could surface a skill
twice.

### How are agents shared?

Markdown agents are canonical. Claude and Grok use those files through Claude
compatibility where possible. To avoid silently dropping Claude-specific
frontmatter, the installer also generates a minimal native `.grok/agents/*.md`
adapter for each role. Every agent is converted to Codex TOML with a name,
description, and developer instructions.

The content is portable, but vendor-specific model names, tool APIs, and
permission semantics are not assumed to be identical.

### Are hooks really universal?

No hook is required for portability. Claude and Codex can optionally add
SessionStart stdout as context. Grok receives the actual guidance through
`AGENTS.md`; because it ignores stdout from passive events, Director Mode does
not install an inert Grok hook. Grok can also discover Claude hooks through its
compatibility layer, so avoiding duplicate registration matters. The optional
script never denies a tool call and always exits zero.

### Why not convert every old Auto-Loop hook?

Stop-hook continuation is a Claude-specific legacy automation feature. Treating
it as a universal policy would be misleading and would conflict with the
guidance-first product boundary. It remains an explicit Claude-only opt-in.

## Session relay

### Can Codex resume a Claude session ID, or Claude resume a Grok ID?

No universal vendor session format exists. Each CLI can resume its own native
sessions. A Director relay starts a new native target session and supplies a
portable checkpoint.

### What is in a handoff packet?

- goal and concise progress summary;
- completed work and decisions;
- next steps, verification, blockers, and notes;
- working directory, Git root, branch, HEAD, status, and diff statistics;
- optional source session ID as metadata.

### What is not automatically captured?

Raw transcripts, file contents, environment variables, and the source CLI's
approvals or sandbox state. User-supplied goal/summary text, absolute paths,
session metadata, and Git filenames can still be sensitive. Review the packet
before sharing it; `--reviewed` records that review without enforcing it.

### How do I create one?

Use the `session-relay` skill or run:

```bash
.director-mode/bin/director-relay create \
  --from claude --to grok \
  --goal "Finish the feature" \
  --summary "Implementation is complete; review remains" \
  --next "Review the diff" \
  --verification "Unit tests pass"
```

### How does the next CLI continue?

```bash
.director-mode/bin/director-relay continue --to grok
```

This prints a copyable command. Add `--run` to launch it, or `--headless` for a
one-shot receiver.

### What about `grok import`?

Grok Build can import Claude Code sessions. Use it when that native shortcut is
helpful, but retain a Director packet when work may later move to Codex or back
to Claude.

## Installation

### What is the recommended command?

```bash
./install.sh --cli all /path/to/project
```

It installs all three adapters with no active hooks.

### Can I add the useful non-blocking context hook?

```bash
./install.sh --cli all --hooks guide /path/to/project
```

This registers it for Claude and Codex only. The relay, guidance, skills, and
agents already work without it.

### How do I update an existing install?

```bash
./install.sh --update --cli all /path/to/project
```

The installer backs up the existing `.claude/` tree. Distributed skill and
agent files update; project guides keep non-Director content.

### What does the wizard do?

`./install.sh --wizard` asks for project type, CLI adapters, and setup style.
The recommended style is all three CLIs with no active hooks.

### How do I enable the old automation?

```bash
./install.sh --hooks automation /path/to/project
```

This installs the legacy Claude Auto-Loop, changelog, validator, and evolving
loop scaffolding. Review the native hook configuration before using it.

## Troubleshooting

### The target CLI does not see a skill

Inspect the expected path:

```bash
find .claude/skills -name SKILL.md       # Claude + Grok compatibility
find .agents/skills -name SKILL.md       # Codex
```

Then use the CLI's native inspection command. For Grok, `grok inspect --json`
shows discovered rules, skills, plugins, hooks, and MCP servers.

### Codex does not see an agent

Check `.codex/agents/*.toml`, then inspect the generated file for valid TOML.
Re-run `./install.sh --update --cli codex` to regenerate adapters.

### The optional advisory hook is not running

Confirm the generated native config exists:

```text
.claude/settings.local.json
.codex/hooks.json
```

Codex may require project trust. Grok has no Director passive-hook entry because
it would not consume the output. The toolkit does not approve hooks on your
behalf.

### A packet no longer matches the worktree

The receiver should trust the current repository over the snapshot, revise the
next steps, and record the difference. Create a new packet after integrating
concurrent work.

### How do I validate the installation?

```bash
./scripts/verify-install.sh /path/to/project
```

For repository development, run `./tests/run-tests.sh` as well.
