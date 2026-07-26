---
name: interop-router
description: Suggest whether Claude Code, Codex CLI, or Grok Build is a useful next collaborator, without launching a CLI or changing controls. Use when comparing the three CLIs, planning a handoff, or deciding whether an independent implementation or review would help.
user-invocable: true
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
---

# Cross-CLI Routing Guide

Offer a recommendation, its tradeoffs, and a copyable next step. Do not launch
another CLI unless the user asks you to execute the handoff.

## Decision prompts

- Continuity: would switching cost more context than it saves?
- Fit: does another CLI have a native workflow or perspective useful here?
- Independence: would a separate review reduce correlated mistakes?
- Worktree: can the receiver safely inspect or edit the current repository?
- Evidence: is the handoff packet specific enough to verify completion?

## Practical mapping

| Need | Useful option |
| --- | --- |
| Stay with the full current conversation | Keep the current CLI |
| Independent implementation or review | Codex CLI or Grok Build |
| Claude-native project workflow or existing Claude session | Claude Code |
| Claude-compatible import plus xAI-native workflows | Grok Build |
| Repository instructions and reusable cross-tool skills | Codex CLI |

These are starting points, not rankings. Prefer the CLI the user already has
authenticated and understands unless a switch brings a concrete benefit.

## Suggested response

1. Name the recommended CLI and one reason.
2. Name the switching cost or uncertainty.
3. Offer to create a `session-relay` packet.
4. If accepted, create it and print the receiving command.

Keep the result at suggestion level. Never add auto-approve, permission bypass,
sandbox, network, or hook-trust flags to make a handoff easier.
