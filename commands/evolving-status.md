---
description: View Self-Evolving Loop session status and history
user-invocable: true
---

# Self-Evolving Loop Status

View detailed status, history, and metrics for the current or past evolving-loop sessions.

---

## Usage

```bash
# Current session status
/evolving-status

# Detailed view
/evolving-status --detailed

# View specific report
/evolving-status --report analysis
/evolving-status --report validation
/evolving-status --report decision
/evolving-status --report learning

# View event history
/evolving-status --history

# View skill evolution
/evolving-status --evolution
```

---

## Execution

When user runs `/evolving-status $ARGUMENTS`:

### Basic Status (default)

```bash
STATE_DIR=".self-evolving-loop"
CHECKPOINT="$STATE_DIR/state/checkpoint.json"

if [ ! -f "$CHECKPOINT" ]; then
    echo "No active Self-Evolving Loop session found."
    echo ""
    echo "Start a new session with:"
    echo "  /evolving-loop \"Your task description\""
    exit 0
fi

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║           SELF-EVOLVING LOOP STATUS                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Read state
STATUS=$(jq -r '.status' "$CHECKPOINT")
PHASE=$(jq -r '.current_phase // "N/A"' "$CHECKPOINT")
ITERATION=$(jq -r '.current_iteration' "$CHECKPOINT")
MAX_ITER=$(jq -r '.max_iterations' "$CHECKPOINT")
REQUEST=$(jq -r '.request | .[0:60]' "$CHECKPOINT")
STARTED=$(jq -r '.started_at' "$CHECKPOINT")

# Status icon
case "$STATUS" in
    "in_progress") STATUS_ICON="🔄" ;;
    "completed") STATUS_ICON="✅" ;;
    "stopped") STATUS_ICON="⏹️" ;;
    "aborted") STATUS_ICON="❌" ;;
    *) STATUS_ICON="❓" ;;
esac

echo "Status:     $STATUS_ICON $STATUS"
echo "Phase:      $PHASE"
echo "Iteration:  $ITERATION / $MAX_ITER"
echo "Started:    $STARTED"
echo ""
echo "Request:    $REQUEST..."
echo ""

# Skill versions
echo "📦 Skill Versions:"
jq -r '.skill_versions | to_entries | .[] | "   \(.key): v\(.value)"' "$CHECKPOINT"
echo ""

# AC status if available
AC_COUNT=$(jq '.acceptance_criteria | length' "$CHECKPOINT")
if [ "$AC_COUNT" -gt 0 ]; then
    echo "📋 Acceptance Criteria:"
    jq -r '.acceptance_criteria[] | "   [\(if .done then "x" else " " end)] \(.id): \(.description)"' "$CHECKPOINT"
    echo ""
fi
```

### Detailed View (--detailed)

```bash
if [[ "$ARGUMENTS" == *"--detailed"* ]]; then
    echo "════════════════════════════════════════════════════════════════"
    echo "DETAILED STATE"
    echo "════════════════════════════════════════════════════════════════"
    jq '.' "$CHECKPOINT"
    echo ""
fi
```

### Report View (--report <type>)

```bash
if [[ "$ARGUMENTS" =~ --report[[:space:]]+([a-z]+) ]]; then
    REPORT_TYPE="${BASH_REMATCH[1]}"
    REPORT_FILE="$STATE_DIR/reports/${REPORT_TYPE}.json"

    if [ -f "$REPORT_FILE" ]; then
        echo "════════════════════════════════════════════════════════════════"
        echo "REPORT: $REPORT_TYPE"
        echo "════════════════════════════════════════════════════════════════"
        jq '.' "$REPORT_FILE"
    else
        echo "Report not found: $REPORT_TYPE"
        echo ""
        echo "Available reports:"
        ls -1 "$STATE_DIR/reports/"*.json 2>/dev/null | xargs -I{} basename {} .json || echo "  (none)"
    fi
fi
```

### History View (--history)

```bash
if [[ "$ARGUMENTS" == *"--history"* ]]; then
    EVENTS_FILE="$STATE_DIR/history/events.jsonl"

    if [ -f "$EVENTS_FILE" ]; then
        echo "════════════════════════════════════════════════════════════════"
        echo "EVENT HISTORY (last 20)"
        echo "════════════════════════════════════════════════════════════════"
        tail -20 "$EVENTS_FILE" | jq -r '"[\(.timestamp | split("T")[1] | split(".")[0])] #\(.iteration) \(.event_type): \(.summary // "-")"'
    else
        echo "No event history found."
    fi
fi
```

### Evolution View (--evolution)

```bash
if [[ "$ARGUMENTS" == *"--evolution"* ]]; then
    EVOLUTION_FILE="$STATE_DIR/history/skill-evolution.jsonl"

    if [ -f "$EVOLUTION_FILE" ]; then
        echo "════════════════════════════════════════════════════════════════"
        echo "SKILL EVOLUTION HISTORY"
        echo "════════════════════════════════════════════════════════════════"
        cat "$EVOLUTION_FILE" | jq -r '"[\(.timestamp | split("T")[1] | split(".")[0])] \(.skill): v\(.from) → v\(.to) (\(.changes) changes)"'
    else
        echo "No evolution history found."
    fi
fi
```

---

## Output Example

```
╔══════════════════════════════════════════════════════════════╗
║           SELF-EVOLVING LOOP STATUS                          ║
╚══════════════════════════════════════════════════════════════╝

Status:     🔄 in_progress
Phase:      EXECUTE
Iteration:  3 / 50
Started:    2026-01-14T12:00:00Z

Request:    Build REST API with user authentication and JWT...

📦 Skill Versions:
   executor: v2
   validator: v1
   fixer: v1

📋 Acceptance Criteria:
   [x] AC-F1: GET /users endpoint
   [x] AC-F2: POST /users endpoint
   [ ] AC-F3: Input validation
   [ ] AC-F4: Error handling
```
