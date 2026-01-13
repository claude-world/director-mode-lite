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

# Show all events
/changelog --all

# Filter by event type
/changelog --type test
/changelog --type file
/changelog --type commit

# Filter by iteration
/changelog --iteration 3

# Show summary statistics
/changelog --summary

# Clear changelog (start fresh)
/changelog --clear

# Export to file
/changelog --export session-log.json
```

---

## Execution

When user runs `/changelog`:

### Default (Recent Events)

```bash
# Check if changelog exists
if [ ! -f .director-mode/changelog.jsonl ]; then
  echo "No changelog found. Start a session with /auto-loop to begin logging."
  exit 0
fi

# Show last 10 events in readable format
echo "=== Recent Development Activity ==="
echo ""

tail -n 10 .director-mode/changelog.jsonl | while read line; do
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
echo "Total events: $(wc -l < .director-mode/changelog.jsonl | tr -d ' ')"
```

### With `--limit N`

```bash
tail -n $N .director-mode/changelog.jsonl | # same formatting as above
```

### With `--all`

```bash
cat .director-mode/changelog.jsonl | # same formatting as above
```

### With `--type TYPE`

Filter by event type prefix:

```bash
# --type test → test_run, test_pass, test_fail
# --type file → file_created, file_modified, file_deleted
# --type commit → commit
# --type iteration → iteration_start, iteration_end
# --type ac → ac_completed
# --type error → error

grep "\"event_type\":\"${TYPE}" .director-mode/changelog.jsonl | # format
```

### With `--iteration N`

```bash
grep "\"iteration\":$N" .director-mode/changelog.jsonl | # format
```

### With `--summary`

```bash
echo "=== Changelog Summary ==="
echo ""

# Total events
total=$(wc -l < .director-mode/changelog.jsonl | tr -d ' ')
echo "Total events: $total"

# Events by type
echo ""
echo "Events by type:"
cat .director-mode/changelog.jsonl | jq -r '.event_type' | sort | uniq -c | sort -rn

# Files changed
echo ""
echo "Files touched:"
cat .director-mode/changelog.jsonl | jq -r '.files[]? // empty' | sort | uniq

# Iterations
echo ""
echo "Iterations completed:"
grep '"event_type":"iteration_end"' .director-mode/changelog.jsonl | wc -l | tr -d ' '

# AC completed
echo ""
echo "Acceptance criteria completed:"
grep '"event_type":"ac_completed"' .director-mode/changelog.jsonl | jq -r '.summary'
```

### With `--clear`

```bash
echo "This will clear the changelog. Are you sure? (y/n)"
# If confirmed:
rm -f .director-mode/changelog.jsonl
echo "Changelog cleared."
```

### With `--export FILENAME`

```bash
cat .director-mode/changelog.jsonl | jq -s '.' > "$FILENAME"
echo "Exported $(wc -l < .director-mode/changelog.jsonl | tr -d ' ') events to $FILENAME"
```

---

## Output Format

### Default View

```
=== Recent Development Activity ===

[10:30:00] #3 file_modified: Updated Login.tsx with validation
[10:28:00] #3 test_fail: Expected validation error test
[10:25:00] #3 iteration_start: Starting iteration 3 - Error handling
[10:20:00] #2 ac_completed: AC #2 complete: JWT token generation
[10:18:00] #2 commit: feat(auth): add JWT token service
...

---
Total events: 45
```

### Summary View

```
=== Changelog Summary ===

Total events: 45

Events by type:
  12 file_modified
   8 test_run
   6 test_pass
   5 iteration_start
   5 iteration_end
   4 commit
   3 ac_completed
   2 file_created

Files touched:
  src/components/Login.tsx
  src/components/Login.test.tsx
  src/services/auth.ts
  src/services/auth.test.ts

Iterations completed: 5

Acceptance criteria completed:
  AC #1 complete: Login form
  AC #2 complete: JWT token generation
  AC #3 complete: Error handling
```

---

## Integration with Subagents

When reviewing code or debugging, agents can reference the changelog:

```markdown
Before analysis, I checked the changelog:
- Last 3 iterations focused on authentication
- Login.tsx was modified 4 times
- 2 test failures were resolved in iteration #2

Based on this context...
```

---

## Tips

1. Run `/changelog --summary` before `/auto-loop --resume` to understand session state
2. Use `/changelog --type error` to quickly find issues
3. Export changelog before clearing for historical reference
4. The changelog persists across sessions in `.director-mode/`
