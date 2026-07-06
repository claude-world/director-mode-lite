---
name: changelog
description: View and manage the runtime changelog for observability
user-invocable: true
---

# Changelog Skill

> **Status: Experimental** — uses Claude Code PostToolUse hooks; the hook interface may change in future versions. If hooks don't fire, events can still be logged manually via auto-loop prompts.

Runtime observability changelog that records every change during a development session, so subagents can understand prior context and sessions can be recovered or debugged.

---

## Overview

Automatically, via PostToolUse hooks, the changelog:
- Records file changes (Write / Edit)
- Logs test results when tests run (Bash)
- Records git commits (Bash)
- Rotates itself when it exceeds 500 lines

Events are stored as append-only JSONL at `.director-mode/changelog.jsonl`.

---

## Usage

### Via `/changelog` command

```bash
/changelog                  # Recent 10 events
/changelog --summary        # Statistics
/changelog --type test      # Filter by event type
/changelog --list-archives  # Show rotated changelogs
/changelog --export log.json
/changelog --archive        # Manually archive current changelog
/changelog --clear          # Clear current changelog
```

### Via Bash

```bash
# Last 5 events
tail -n 5 .director-mode/changelog.jsonl | jq '.'

# All file changes
grep '"event_type":"file_' .director-mode/changelog.jsonl

# Count by type
jq -r '.event_type' .director-mode/changelog.jsonl | sort | uniq -c
```

---

## Event Schema

```json
{
  "id": "evt_1705142400_12345",
  "timestamp": "2025-01-13T10:30:00.000Z",
  "event_type": "file_edit",
  "agent": "hook",
  "iteration": 3,
  "summary": "file_edit: Login.tsx",
  "files": ["src/components/Login.tsx"]
}
```

### Event Types

| Type | Source | Description |
|------|--------|-------------|
| `file_write` | Hook (Write) | File written via the Write tool |
| `file_edit` | Hook (Edit) | File edited via the Edit tool |
| `test_pass` | Hook (Bash) | Tests passing |
| `test_fail` | Hook (Bash) | Tests failing |
| `test_run` | Hook (Bash) | Tests ran, result undetermined |
| `commit` | Hook (Bash) | Git commit made |
| `session_start` | auto-loop | Session begins |
| `session_end` | auto-loop | Session completes |
| `changelog_rotated` | System | Changelog was rotated |

---

## Automatic Logging via Hooks

Configured in `.claude/settings.local.json` (the shipped template is `hooks/settings-hooks.json`):

```json
{
  "hooks": {
    "PostToolUse": [
      { "matcher": "Write", "hooks": [{ "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/log-file-change.sh" }] },
      { "matcher": "Edit",  "hooks": [{ "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/log-file-change.sh" }] },
      { "matcher": "Bash",  "hooks": [{ "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/log-bash-event.sh" }] }
    ]
  }
}
```

> `$CLAUDE_PROJECT_DIR` keeps paths portable (resolved at runtime by Claude Code).

| Script | Trigger | Events Logged |
|--------|---------|---------------|
| `log-file-change.sh` | Write, Edit | `file_write`, `file_edit` |
| `log-bash-event.sh` | Bash | `test_pass`, `test_fail`, `test_run`, `commit` |

Core helpers live in `_lib-changelog.sh`:

```bash
log_event "file_write" "Wrote Login.tsx" "hook" '["src/Login.tsx"]'
archive_changelog   # move current changelog to a timestamped archive
clear_changelog     # empty the current changelog
list_archives       # list rotated changelogs
```

---

## Rotation & Archiving

Two independent thresholds keep the changelog bounded. They are complementary, not contradictory:

| Trigger | Threshold | Who does it | When |
|---------|-----------|-------------|------|
| Session-start archive | > 100 lines | `/auto-loop` init | At the start of each auto-loop session, so the new session begins with a fresh log |
| Runtime auto-rotation | > 500 lines (`MAX_LINES`) | `_lib-changelog.sh` (`rotate_if_needed`) | Continuously, as events are appended within a session |

On rotation the current file is moved to `changelog.YYYYMMDD_HHMMSS.jsonl`, a fresh `changelog.jsonl` is started, and a `changelog_rotated` event is logged:

```
.director-mode/
├── changelog.jsonl                    ← Current
├── changelog.20250113_103000.jsonl    ← Archived
└── changelog.20250112_150000.jsonl    ← Archived
```

---

## Checkpoint vs Changelog

| Aspect | Checkpoint | Changelog |
|--------|------------|-----------|
| Location | `.auto-loop/checkpoint.json` | `.director-mode/changelog.jsonl` |
| Purpose | Current state snapshot ("where am I now?") | Historical event stream ("how did I get here?") |
| Used by | Stop hook (continue/stop decision) | Subagents (context) |
| Format | Single JSON object | JSONL (append-only) |
| Persistence | Overwritten each iteration | Accumulated, then rotated |

Only one auto-loop session runs per project. Starting `/auto-loop` while a session is `in_progress` blocks with a prompt to use `--resume` (continue with the existing checkpoint + changelog) or `--force` (archive the old session, start fresh).

---

## Subagent Integration

- **code-reviewer** — before reviewing, checks recent file changes, the current iteration, and recent test results.
- **debugger** — before debugging, checks when errors first appeared, which files changed just before them, and the pattern of test failures.

---

## Installation

Hooks ship with Director Mode Lite. After install, verify:

```bash
ls .claude/hooks/
# _lib-changelog.sh  auto-loop-stop.sh  log-bash-event.sh  log-file-change.sh  pre-tool-validator.sh

cat .claude/settings.local.json | jq '.hooks'
```

---

## Troubleshooting

### Events not logged

1. Check hooks exist: `ls .claude/hooks/*.sh`
2. Check the live hook config: `cat .claude/settings.local.json | jq '.hooks'` (the shipped template is `hooks/settings-hooks.json`)
3. Check scripts are executable: `chmod +x .claude/hooks/*.sh`

### Stale session blocking

```bash
cat .auto-loop/checkpoint.json | jq '.status'
/auto-loop --force "New task"
```

### Changelog too large

```bash
/changelog --archive   # manual archive
/changelog --clear     # or clear
```
