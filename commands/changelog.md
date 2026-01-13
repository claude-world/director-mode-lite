---
description: View and manage the runtime changelog for observability
---

# Changelog

Query and manage the runtime changelog that tracks all development session events.

---

## Usage

```bash
# Show recent events (last 10)
/changelog

# Show more events
/changelog --limit 20

# Show all events in current session
/changelog --all

# Filter by event type
/changelog --type test      # test_pass, test_fail
/changelog --type file      # file_created, file_modified
/changelog --type commit    # commit

# Filter by iteration
/changelog --iteration 3

# Show summary statistics
/changelog --summary

# Manage changelog
/changelog --clear          # Clear current changelog
/changelog --archive        # Archive current to timestamped file
/changelog --list-archives  # Show archived changelogs

# Export to file
/changelog --export session-log.json
```

---

## How It Works

The changelog is **automatically populated** by PostToolUse hooks:

| Event | Trigger | Auto-logged |
|-------|---------|-------------|
| `file_created` | Write tool | Yes |
| `file_modified` | Edit tool | Yes |
| `test_pass` | Bash (test commands) | Yes |
| `test_fail` | Bash (test commands) | Yes |
| `commit` | Bash (git commit) | Yes |

**No manual logging required** for these events.

---

## Automatic Rotation

Changelog automatically rotates when exceeding 500 lines:

```
.director-mode/
├── changelog.jsonl                    ← Current (active)
├── changelog.20250113_103000.jsonl    ← Archived
└── changelog.20250112_150000.jsonl    ← Archived
```

Rotation happens automatically during logging. Old changelogs are preserved for historical analysis.

---

## Execution

When user runs `/changelog`:

### Default (Recent Events)

```bash
CHANGELOG=".director-mode/changelog.jsonl"

if [ ! -f "$CHANGELOG" ]; then
  echo "No changelog found."
  echo "Events are automatically logged when you use Write/Edit tools or run tests."
  exit 0
fi

echo "=== Recent Development Activity ==="
echo ""

tail -n 10 "$CHANGELOG" | while read line; do
  timestamp=$(echo "$line" | jq -r '.timestamp' | cut -d'T' -f2 | cut -d'.' -f1)
  event_type=$(echo "$line" | jq -r '.event_type')
  summary=$(echo "$line" | jq -r '.summary')
  iteration=$(echo "$line" | jq -r '.iteration // ""')
  
  if [ -n "$iteration" ] && [ "$iteration" != "null" ]; then
    echo "[$timestamp] #$iteration $event_type: $summary"
  else
    echo "[$timestamp] $event_type: $summary"
  fi
done

echo ""
echo "---"
total=$(wc -l < "$CHANGELOG" | tr -d ' ')
echo "Total events: $total"
echo "Location: $CHANGELOG"
```

### With `--summary`

```bash
echo "=== Changelog Summary ==="
echo ""

# Session info
if [ -f ".auto-loop/checkpoint.json" ]; then
    status=$(jq -r '.status' .auto-loop/checkpoint.json 2>/dev/null || echo "unknown")
    iteration=$(jq -r '.current_iteration' .auto-loop/checkpoint.json 2>/dev/null || echo "0")
    echo "Session status: $status"
    echo "Current iteration: $iteration"
    echo ""
fi

# Total events
total=$(wc -l < "$CHANGELOG" | tr -d ' ')
echo "Total events: $total"

# Events by type
echo ""
echo "Events by type:"
jq -r '.event_type' "$CHANGELOG" | sort | uniq -c | sort -rn

# Files changed
echo ""
echo "Files touched:"
jq -r '.files[]? // empty' "$CHANGELOG" | sort | uniq | head -20

# Test results
echo ""
echo "Test results:"
echo "  Passes: $(grep -c '"event_type":"test_pass"' "$CHANGELOG" || echo 0)"
echo "  Fails:  $(grep -c '"event_type":"test_fail"' "$CHANGELOG" || echo 0)"

# Commits
echo ""
echo "Commits: $(grep -c '"event_type":"commit"' "$CHANGELOG" || echo 0)"

# Archives
archive_count=$(ls -1 .director-mode/changelog.*.jsonl 2>/dev/null | wc -l | tr -d ' ')
echo ""
echo "Archived changelogs: $archive_count"
```

### With `--clear`

```bash
rm -f .director-mode/changelog.jsonl
echo "Changelog cleared."
```

### With `--archive`

```bash
source .claude/hooks/changelog-logger.sh 2>/dev/null
archive_changelog
```

### With `--list-archives`

```bash
echo "=== Archived Changelogs ==="
echo ""
ls -lh .director-mode/changelog.*.jsonl 2>/dev/null | while read line; do
    echo "$line"
done || echo "No archives found."

echo ""
echo "To view an archive:"
echo "  cat .director-mode/changelog.TIMESTAMP.jsonl | jq '.'"
```

### With `--export FILENAME`

```bash
jq -s '.' "$CHANGELOG" > "$FILENAME"
echo "Exported $(wc -l < "$CHANGELOG" | tr -d ' ') events to $FILENAME"
```

---

## Output Formats

### Default View

```
=== Recent Development Activity ===

[10:30:00] #3 file_modified: file_modified: Login.tsx
[10:28:00] #3 test_fail: 1 tests failing
[10:25:00] #2 test_pass: 3 tests passing
[10:20:00] #2 commit: feat(auth): add JWT service
[10:15:00] #2 file_created: file_created: auth.ts

---
Total events: 45
Location: .director-mode/changelog.jsonl
```

### Summary View

```
=== Changelog Summary ===

Session status: in_progress
Current iteration: 3

Total events: 45

Events by type:
  15 file_modified
  12 test_pass
   8 file_created
   5 test_fail
   5 commit

Files touched:
  src/components/Login.tsx
  src/components/Login.test.tsx
  src/services/auth.ts

Test results:
  Passes: 12
  Fails: 5

Commits: 5

Archived changelogs: 2
```

---

## Integration with Auto-Loop

The changelog works seamlessly with `/auto-loop`:

1. **Start**: Session start is logged
2. **During**: All file changes, tests, commits auto-logged
3. **Resume**: Changelog provides context for what happened before interruption
4. **Complete**: Full history available for review

```bash
# Before resuming, check what happened
/changelog --summary
/changelog --type test

# Then resume
/auto-loop --resume
```

---

## Tips

1. Run `/changelog --summary` before `/auto-loop --resume` to understand session state
2. Use `/changelog --type error` to quickly find issues
3. Archive before starting new major task: `/changelog --archive`
4. Export for sharing: `/changelog --export debug-session.json`
