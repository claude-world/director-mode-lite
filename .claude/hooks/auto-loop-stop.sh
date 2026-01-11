#!/bin/bash
# Auto-Loop Stop Hook - TDD-based autonomous loop
# Director Mode Lite

set -euo pipefail

STATE_DIR=".auto-loop"
CHECKPOINT_FILE="$STATE_DIR/checkpoint.json"
ITERATION_FILE="$STATE_DIR/iteration.txt"
STOP_FILE="$STATE_DIR/stop"

# Check if auto-loop is active
if [[ ! -f "$CHECKPOINT_FILE" ]]; then
    # No active loop, allow normal exit
    echo '{"decision": "allow"}'
    exit 0
fi

# Check for stop signal
if [[ -f "$STOP_FILE" ]]; then
    rm -f "$STOP_FILE"
    echo '{"decision": "allow"}'
    exit 0
fi

# Read checkpoint
if ! checkpoint=$(cat "$CHECKPOINT_FILE" 2>/dev/null); then
    echo '{"decision": "allow"}'
    exit 0
fi

# Parse checkpoint fields
status=$(echo "$checkpoint" | grep -o '"status"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4 || echo "unknown")
current_iteration=$(echo "$checkpoint" | grep -o '"current_iteration"[[:space:]]*:[[:space:]]*[0-9]*' | grep -o '[0-9]*$' || echo "0")
max_iterations=$(echo "$checkpoint" | grep -o '"max_iterations"[[:space:]]*:[[:space:]]*[0-9]*' | grep -o '[0-9]*$' || echo "20")
request=$(echo "$checkpoint" | grep -o '"request"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4 || echo "")

# Check if completed or max iterations reached
if [[ "$status" == "completed" ]]; then
    echo '{"decision": "allow"}'
    exit 0
fi

if [[ "$current_iteration" -ge "$max_iterations" ]]; then
    # Update status to completed
    echo "$checkpoint" | sed 's/"status"[[:space:]]*:[[:space:]]*"[^"]*"/"status": "max_iterations_reached"/' > "$CHECKPOINT_FILE"
    echo '{"decision": "allow"}'
    exit 0
fi

# Increment iteration
new_iteration=$((current_iteration + 1))
echo "$new_iteration" > "$ITERATION_FILE"

# Update checkpoint
echo "$checkpoint" | sed "s/\"current_iteration\"[[:space:]]*:[[:space:]]*[0-9]*/\"current_iteration\": $new_iteration/" > "$CHECKPOINT_FILE"

# Extract AC status for prompt
ac_status=$(python3 -c "
import json, sys
try:
    data = json.loads('''$checkpoint''')
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

# Return block decision with prompt
cat <<EOF
{
  "decision": "block",
  "prompt": $(echo "$tdd_prompt" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))' 2>/dev/null || echo "\"Continue Auto-Loop iteration #$new_iteration\"")
}
EOF
