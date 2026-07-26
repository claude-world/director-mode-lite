# Director Mode Lite — shared guidance

Director Mode Lite is a small operating guide for Claude Code, Codex CLI, and
Grok Build. Treat every item below as guidance that can be adapted, skipped, or
stopped when the task calls for something different.

## Start with a brief

Before substantial work, make five things visible:

- Outcome: what should be true when the work is finished.
- Context: the relevant repository, product behavior, and prior decisions.
- Constraints: compatibility, scope, time, or user preferences that matter.
- Evidence: the tests, build, diff, or inspection that will demonstrate success.
- Next decision: the point where human judgment is most useful.

Prefer a concise brief over a long permanent rule file. Put task-specific
procedures in a skill so they load only when useful.

## Work like a director

1. Orient: inspect the real repository and current worktree before deciding.
2. Propose: state a short approach when the task has meaningful tradeoffs.
3. Delegate: use agents for independent work when that improves speed or review.
4. Integrate: keep one owner responsible for the final result and conflicts.
5. Verify: run the smallest convincing checks and report the actual evidence.
6. Relay: when another CLI should continue, create a portable handoff packet.

## Native surfaces

| CLI | Repository guidance | Reusable skills | Agents |
| --- | --- | --- | --- |
| Claude Code | `CLAUDE.md` | `.claude/skills/` | `.claude/agents/` |
| Codex CLI | `AGENTS.md` | `.agents/skills/` | `.codex/agents/*.toml` |
| Grok Build | `AGENTS.md` and Claude-compatible files | shared compatible skills | generated `.grok/agents/*.md` |

The installer adapts the same source assets to these native locations. The
content is shared; CLI-specific permissions and runtime behavior are not.

## Session relay

Vendor session histories and IDs are native to their own CLI. A cross-CLI relay
therefore starts a new native session and gives it a portable packet containing:

- goal and concise progress summary;
- completed work and important decisions;
- current branch, commit, worktree status, and diff statistics;
- verification already run, blockers, and next steps;
- the source session ID only as optional metadata.

Create a packet with the `session-relay` skill or:

```bash
ROOT="${CLAUDE_PROJECT_DIR:-${GROK_WORKSPACE_ROOT:-}}"
[[ -n "$ROOT" ]] || ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
RELAY="$ROOT/.director-mode/bin/director-relay"
[[ -x "$RELAY" ]] || RELAY="$HOME/.claude/bin/director-relay"

"$RELAY" create \
  --from claude --to codex \
  --goal "Finish the authentication change" \
  --summary "API behavior is implemented; UI and integration tests remain" \
  --next "Update the sign-in form" \
  --verification "API unit tests pass"
```

Then print or launch the receiving command:

```bash
"$RELAY" continue --to codex
```

Add `--run` only when you want the tool to launch the target CLI immediately.

## Full capability, no added gate

Director Mode does not add permission gates, deny rules, forced approvals, or
mandatory workflows. Use each CLI's native trusted/full-access mode when that
is the user's choice; the toolkit does not silently rewrite those native
settings. The default installation registers no hooks. The optional `guide`
hook adds only Claude/Codex SessionStart context, always exits successfully,
and never returns a deny decision. Grok reads `AGENTS.md` directly and receives
no inert passive hook.

For an explicit full-capability session in a trusted workspace, run:

```bash
.director-mode/bin/director-open claude
.director-mode/bin/director-open codex
.director-mode/bin/director-open grok
```

The launcher passes native permission/sandbox flags; managed policy and already
configured user hooks remain authoritative. Permission mode is never simulated
through prompt instructions.
