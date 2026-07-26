---
name: director-mode
description: Apply the Director Mode guidance-first workflow across Claude Code, Codex CLI, or Grok Build. Use when starting substantial repository work, coordinating agents, defining evidence of completion, or deciding how another CLI can continue without inheriting vendor-specific session state.
user-invocable: true
allowed-tools:
  - Read
  - Bash
  - Grep
  - Glob
---

# Director Mode

Read `.director-mode/GUIDANCE.md` and adapt its brief to the current task.

Keep the working contract small:

1. State the outcome, relevant context, meaningful constraints, and completion
   evidence.
2. Inspect the repository before choosing an approach.
3. Use independent agents when parallel work or an independent review helps.
4. Keep one integrator responsible for the final diff and verification.
5. If another CLI should take over, use the `session-relay` skill.

These are operating suggestions, not a policy engine. Do not change the CLI's
permissions, approvals, sandbox, network access, or hook trust on behalf of this
skill.
