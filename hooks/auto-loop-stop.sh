#!/bin/bash
# Auto-Loop Stop Hook - TDD-based autonomous loop
# Director Mode Lite
#
# Note: This hook uses `set -euo pipefail` (strict mode) unlike other hooks
# because it controls the auto-loop continuation logic and must fail fast
# on any errors to avoid infinite loops or corrupted state.
#
# JSON handling uses jq when available (quoting-safe, atomic); a grep/sed
# fallback keeps jq-less installs working (install.sh warns about jq).

set -euo pipefail

STATE_DIR=".auto-loop"
CHECKPOINT_FILE="$STATE_DIR/checkpoint.json"
ITERATION_FILE="$STATE_DIR/iteration.txt"
STOP_FILE="$STATE_DIR/stop"

# Check if auto-loop is active
if [[ ! -f "$CHECKPOINT_FILE" ]]; then
    # No active loop, allow normal exit
    exit 0
fi

# Check for stop signal
if [[ -f "$STOP_FILE" ]]; then
    rm -f "$STOP_FILE"
    exit 0
fi

HAS_JQ=false
command -v jq &>/dev/null && HAS_JQ=true

# Read checkpoint
if ! checkpoint=$(cat "$CHECKPOINT_FILE" 2>/dev/null); then
    exit 0
fi

# Parse checkpoint fields
if $HAS_JQ; then
    status=$(jq -r '.status // "unknown"' "$CHECKPOINT_FILE")
    current_iteration=$(jq -r '.current_iteration // 0' "$CHECKPOINT_FILE")
    max_iterations=$(jq -r '.max_iterations // 20' "$CHECKPOINT_FILE")
    request=$(jq -r '.request // ""' "$CHECKPOINT_FILE")
else
    status=$(echo "$checkpoint" | grep -o '"status"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4 || echo "unknown")
    current_iteration=$(echo "$checkpoint" | grep -o '"current_iteration"[[:space:]]*:[[:space:]]*[0-9]*' | grep -o '[0-9]*$' || echo "0")
    max_iterations=$(echo "$checkpoint" | grep -o '"max_iterations"[[:space:]]*:[[:space:]]*[0-9]*' | grep -o '[0-9]*$' || echo "20")
    request=$(echo "$checkpoint" | grep -o '"request"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4 || echo "")
fi

# Check if completed or max iterations reached
if [[ "$status" == "completed" ]]; then
    exit 0
fi

if [[ "$current_iteration" -ge "$max_iterations" ]]; then
    # Update status and allow exit
    if $HAS_JQ; then
        jq '.status = "max_iterations_reached"' "$CHECKPOINT_FILE" > "$CHECKPOINT_FILE.tmp" \
            && mv "$CHECKPOINT_FILE.tmp" "$CHECKPOINT_FILE"
    else
        echo "$checkpoint" | sed 's/"status"[[:space:]]*:[[:space:]]*"[^"]*"/"status": "max_iterations_reached"/' > "$CHECKPOINT_FILE"
    fi
    exit 0
fi

# Increment iteration
new_iteration=$((current_iteration + 1))
echo "$new_iteration" > "$ITERATION_FILE"

# Update checkpoint (atomic with jq)
if $HAS_JQ; then
    jq ".current_iteration = $new_iteration" "$CHECKPOINT_FILE" > "$CHECKPOINT_FILE.tmp" \
        && mv "$CHECKPOINT_FILE.tmp" "$CHECKPOINT_FILE"
else
    echo "$checkpoint" | sed "s/\"current_iteration\"[[:space:]]*:[[:space:]]*[0-9]*/\"current_iteration\": $new_iteration/" > "$CHECKPOINT_FILE"
fi

# Extract AC status for prompt
if $HAS_JQ; then
    ac_status=$(jq -r 'if (.acceptance_criteria // []) | length == 0 then "No AC defined"
        else .acceptance_criteria[] | (if .done then "[x] " else "[ ] " end) + (.description // "Unknown") end' \
        "$CHECKPOINT_FILE" 2>/dev/null || echo "Check .auto-loop/checkpoint.json")
else
    ac_status=$(echo "$checkpoint" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    acs = data.get('acceptance_criteria', [])
    if not acs:
        print('No AC defined')
    else:
        for ac in acs:
            mark = '[x]' if ac.get('done') else '[ ]'
            print(f\"{mark} {ac.get('description', 'Unknown')}\")
except:
    print('Unable to parse AC')
" 2>/dev/null || echo "Check .auto-loop/checkpoint.json")
fi

# Build TDD prompt for next iteration
tdd_prompt="Continue Auto-Loop iteration #$new_iteration / $max_iterations

Original request: $request

Acceptance Criteria status:
$ac_status

Follow the TDD cycle:
1. RED - Write a failing test for an incomplete AC
2. GREEN - Implement code to make the test pass
3. REFACTOR - Improve code quality (keep tests passing)
4. VALIDATE - Run lint and tests
5. COMMIT - Commit successful changes
6. DECIDE - Update the corresponding AC's done status in checkpoint.json

If all ACs are complete, update status to \"completed\"."

# Block stop with reason for next iteration (official Stop-hook schema)
if $HAS_JQ; then
    jq -n --arg reason "$tdd_prompt" '{decision: "block", reason: $reason}'
else
    json_reason=$(echo "$tdd_prompt" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))' 2>/dev/null) || {
        json_reason="\"Continue Auto-Loop iteration #$new_iteration\""
    }
    cat <<EOF
{
  "decision": "block",
  "reason": $json_reason
}
EOF
fi
