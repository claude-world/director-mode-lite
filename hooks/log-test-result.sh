#!/bin/bash
# Log Test Result Hook - Records test execution results
# Director Mode Lite
#
# PostToolUse hook for Bash tool
# Detects test runs and logs results to the changelog

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/changelog-logger.sh" 2>/dev/null || {
    CHANGELOG_FILE=".director-mode/changelog.jsonl"
    mkdir -p ".director-mode"
    log_event() {
        local ts=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
        local iter="null"
        [[ -f ".auto-loop/iteration.txt" ]] && iter=$(cat ".auto-loop/iteration.txt" 2>/dev/null || echo "null")
        echo "{\"id\":\"evt_$(date +%s)_$RANDOM\",\"timestamp\":\"$ts\",\"event_type\":\"$1\",\"agent\":\"$3\",\"iteration\":$iter,\"summary\":\"$2\",\"files\":$4}" >> "$CHANGELOG_FILE"
    }
}

# Read hook input from stdin
INPUT=$(cat)

# Get command and output from environment or input
COMMAND="${CLAUDE_COMMAND:-}"
OUTPUT="${CLAUDE_OUTPUT:-}"
EXIT_CODE="${CLAUDE_EXIT_CODE:-0}"

# Try to extract from input JSON
if command -v jq &>/dev/null; then
    [[ -z "$COMMAND" ]] && COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || echo "")
    [[ -z "$OUTPUT" ]] && OUTPUT=$(echo "$INPUT" | jq -r '.tool_output // empty' 2>/dev/null || echo "")
fi

# Detect if this is a test command
is_test_command() {
    local cmd="$1"
    [[ "$cmd" =~ (npm[[:space:]]+test|yarn[[:space:]]+test|pnpm[[:space:]]+test|pytest|jest|vitest|mocha|go[[:space:]]+test|cargo[[:space:]]+test|mix[[:space:]]+test|rspec|phpunit) ]]
}

# Detect test result from output
detect_test_result() {
    local output="$1"
    local exit_code="$2"
    
    # Check for common pass patterns
    if [[ "$output" =~ (PASS|passed|✓|success|ok[[:space:]]+[0-9]) ]]; then
        if [[ "$exit_code" == "0" ]]; then
            echo "pass"
            return
        fi
    fi
    
    # Check for common fail patterns
    if [[ "$output" =~ (FAIL|failed|✗|error|Error:|AssertionError) ]]; then
        echo "fail"
        return
    fi
    
    # Default based on exit code
    if [[ "$exit_code" == "0" ]]; then
        echo "pass"
    else
        echo "fail"
    fi
}

# Only process test commands
if ! is_test_command "$COMMAND"; then
    exit 0
fi

# Detect result
RESULT=$(detect_test_result "$OUTPUT" "$EXIT_CODE")

# Set event type
if [[ "$RESULT" == "pass" ]]; then
    EVENT_TYPE="test_pass"
    SUMMARY="Tests passing"
else
    EVENT_TYPE="test_fail"
    SUMMARY="Tests failing"
fi

# Extract test counts if possible
if [[ "$OUTPUT" =~ ([0-9]+)[[:space:]]+(passed|pass) ]]; then
    PASSED="${BASH_REMATCH[1]}"
    SUMMARY="$PASSED tests passing"
fi

if [[ "$OUTPUT" =~ ([0-9]+)[[:space:]]+(failed|fail) ]]; then
    FAILED="${BASH_REMATCH[1]}"
    if [[ "$EVENT_TYPE" == "test_fail" ]]; then
        SUMMARY="$FAILED tests failing"
    else
        SUMMARY="$SUMMARY, $FAILED failing"
    fi
fi

# Log the event
log_event "$EVENT_TYPE" "$SUMMARY" "hook" "[]"

exit 0
