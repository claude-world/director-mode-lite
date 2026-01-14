---
description: View Self-Evolving Loop session status, history, and memory metrics
user-invocable: true
---

# Self-Evolving Loop Status (Meta-Engineering v2.0)

View detailed status, history, memory metrics, and lifecycle information for the current or past evolving-loop sessions.

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
/evolving-status --report patterns    # NEW: Pattern recommendations
/evolving-status --report context     # NEW: Context check result

# View event history
/evolving-status --history

# View skill evolution
/evolving-status --evolution

# NEW: View memory system
/evolving-status --memory

# NEW: View tool dependencies
/evolving-status --dependencies
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

# Skill versions and lifecycle
echo "📦 Skill Versions:"
jq -r '.skill_versions | to_entries | .[] | "   \(.key): v\(.value)"' "$CHECKPOINT"
echo ""

# Lifecycle status (NEW)
echo "🔄 Lifecycle Status:"
jq -r '.skill_lifecycle // {} | to_entries | .[] | "   \(.key): \(.value)"' "$CHECKPOINT"
echo ""

# Task type and pattern
TASK_TYPE=$(jq -r '.task_type // "general"' "$CHECKPOINT")
PATTERN_MATCHED=$(jq -r '.pattern_matched // "none"' "$CHECKPOINT")
echo "🎯 Task Type: $TASK_TYPE (pattern: $PATTERN_MATCHED)"
echo ""

# AC status if available
AC_COUNT=$(jq '.acceptance_criteria | length' "$CHECKPOINT" 2>/dev/null || echo "0")
if [ "$AC_COUNT" -gt 0 ]; then
    echo "📋 Acceptance Criteria:"
    jq -r '.acceptance_criteria[] | "   [\(if .done then "x" else " " end)] \(.id): \(.description)"' "$CHECKPOINT"
    echo ""
fi

# Tools used (NEW)
TOOLS_USED=$(jq -r '.tools_used // [] | length' "$CHECKPOINT" 2>/dev/null || echo "0")
if [ "$TOOLS_USED" -gt 0 ]; then
    echo "🔧 Tools Used:"
    jq -r '.tools_used | .[] | "   - \(.)"' "$CHECKPOINT"
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

### Memory View (--memory) NEW!

```bash
if [[ "$ARGUMENTS" == *"--memory"* ]]; then
    MEMORY_DIR=".claude/memory/meta-engineering"

    echo "════════════════════════════════════════════════════════════════"
    echo "META-ENGINEERING MEMORY SYSTEM"
    echo "════════════════════════════════════════════════════════════════"
    echo ""

    if [ -d "$MEMORY_DIR" ]; then
        # Tool usage summary
        echo "📊 Tool Usage:"
        if [ -f "$MEMORY_DIR/tool-usage.json" ]; then
            TOOL_COUNT=$(jq '.tools | length' "$MEMORY_DIR/tool-usage.json")
            echo "   Tracked tools: $TOOL_COUNT"
            echo "   Top 5 by usage:"
            jq -r '.tools | sort_by(-.usage_count) | .[0:5] | .[] | "     - \(.name): \(.usage_count) uses, \(.success_rate | . * 100 | floor)% success"' "$MEMORY_DIR/tool-usage.json" 2>/dev/null || echo "     (no data)"
        else
            echo "   (not initialized)"
        fi
        echo ""

        # Pattern summary
        echo "🎯 Task Patterns:"
        if [ -f "$MEMORY_DIR/patterns.json" ]; then
            jq -r '.task_patterns | to_entries | .[] | "   \(.key): \(.value.success_rate | . * 100 | floor)% success (\(.value.sample_count) samples)"' "$MEMORY_DIR/patterns.json" 2>/dev/null || echo "   (no data)"
        else
            echo "   (not initialized)"
        fi
        echo ""

        # Evolution summary
        echo "🧬 Evolution:"
        if [ -f "$MEMORY_DIR/evolution.json" ]; then
            VERSION=$(jq -r '.version' "$MEMORY_DIR/evolution.json")
            LAST=$(jq -r '.last_evolution // "never"' "$MEMORY_DIR/evolution.json")
            UPGRADES=$(jq '.lifecycle_upgrades | length' "$MEMORY_DIR/evolution.json" 2>/dev/null || echo "0")
            echo "   Version: $VERSION"
            echo "   Last evolution: $LAST"
            echo "   Lifecycle upgrades: $UPGRADES"
        else
            echo "   (not initialized)"
        fi
    else
        echo "(Memory system not initialized)"
        echo "Run /evolving-loop to initialize."
    fi
fi
```

### Dependencies View (--dependencies) NEW!

```bash
if [[ "$ARGUMENTS" == *"--dependencies"* ]]; then
    MEMORY_DIR=".claude/memory/meta-engineering"

    echo "════════════════════════════════════════════════════════════════"
    echo "TOOL DEPENDENCY GRAPH"
    echo "════════════════════════════════════════════════════════════════"
    echo ""

    if [ -f "$MEMORY_DIR/patterns.json" ]; then
        DEPS=$(jq '.tool_dependencies | length' "$MEMORY_DIR/patterns.json" 2>/dev/null || echo "0")

        if [ "$DEPS" -gt 0 ]; then
            echo "Tools commonly used together:"
            jq -r '.tool_dependencies | to_entries | sort_by(-.value.co_usage_count) | .[0:10] | .[] | "   \(.value.tools[0]) + \(.value.tools[1]): \(.value.co_usage_count) times"' "$MEMORY_DIR/patterns.json"
        else
            echo "(No dependencies recorded yet)"
            echo "Dependencies are recorded when tools are used together in a session."
        fi
    else
        echo "(Memory system not initialized)"
    fi
fi
```

---

## Output Example

```
╔══════════════════════════════════════════════════════════════╗
║     SELF-EVOLVING LOOP STATUS (Meta-Engineering v2.0)        ║
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

🔄 Lifecycle Status:
   executor: task-scoped
   validator: task-scoped
   fixer: task-scoped

🎯 Task Type: auth (pattern: auth)

📋 Acceptance Criteria:
   [x] AC-F1: GET /users endpoint
   [x] AC-F2: POST /users endpoint
   [ ] AC-F3: Input validation
   [ ] AC-F4: Error handling

🔧 Tools Used:
   - code-reviewer
   - test-runner
   - debugger
```

### Memory View Example

```
════════════════════════════════════════════════════════════════
META-ENGINEERING MEMORY SYSTEM
════════════════════════════════════════════════════════════════

📊 Tool Usage:
   Tracked tools: 5
   Top 5 by usage:
     - code-reviewer: 12 uses, 91% success
     - test-runner: 10 uses, 90% success
     - debugger: 5 uses, 80% success

🎯 Task Patterns:
   auth: 85% success (8 samples)
   api: 78% success (5 samples)
   database: 75% success (2 samples)
   ui: 75% success (0 samples)

🧬 Evolution:
   Version: 3
   Last evolution: 2026-01-14T15:00:00Z
   Lifecycle upgrades: 2
```
