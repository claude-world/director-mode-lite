#!/bin/bash
# Log Test Result Hook - Records test execution results
# Director Mode Lite
#
# PostToolUse hook for Bash tool
# Detects test runs and logs results to the changelog
#
# Input: JSON via stdin (Claude Code PostToolUse format)
# Output: None (always exits 0 to not block)

# Never exit on errors
set +e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || SCRIPT_DIR="$(pwd)/.claude/hooks"

# Source the logger
if [[ -f "$SCRIPT_DIR/changelog-logger.sh" ]]; then
    source "$SCRIPT_DIR/changelog-logger.sh"
elif [[ -f ".claude/hooks/changelog-logger.sh" ]]; then
    source ".claude/hooks/changelog-logger.sh"
else
    log_event() {
        mkdir -p ".director-mode" 2>/dev/null
        local ts=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")
        local iter="null"
        [[ -f ".auto-loop/iteration.txt" ]] && iter=$(cat ".auto-loop/iteration.txt" 2>/dev/null || echo "null")
        echo "{\"id\":\"evt_$(date +%s)_$RANDOM\",\"timestamp\":\"$ts\",\"event_type\":\"$1\",\"agent\":\"$3\",\"iteration\":$iter,\"summary\":\"$2\",\"files\":$4}" >> ".director-mode/changelog.jsonl" 2>/dev/null
    }
    HAS_JQ=false
    command -v jq &>/dev/null && HAS_JQ=true
fi

# Read JSON from stdin
INPUT=$(cat 2>/dev/null) || INPUT=""
[[ -z "$INPUT" ]] && exit 0

# Parse command and response
if $HAS_JQ; then
    TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null) || TOOL_NAME=""
    COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null) || COMMAND=""
    OUTPUT=$(echo "$INPUT" | jq -r '.tool_response // empty' 2>/dev/null) || OUTPUT=""
else
    TOOL_NAME=$(echo "$INPUT" | grep -o '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:.*"\([^"]*\)".*/\1/' 2>/dev/null) || TOOL_NAME=""
    COMMAND=$(echo "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:.*"\([^"]*\)".*/\1/' 2>/dev/null) || COMMAND=""
    OUTPUT=""  # Too complex to parse without jq
fi

# Only process Bash tool
[[ "$TOOL_NAME" != "Bash" ]] && exit 0
[[ -z "$COMMAND" ]] && exit 0

# Detect if this is a test command
is_test_command() {
    local cmd="$1"
    # Common test runners
    [[ "$cmd" =~ ^[[:space:]]*(npm|yarn|pnpm)[[:space:]]+(test|run[[:space:]]+test) ]] && return 0
    [[ "$cmd" =~ ^[[:space:]]*(npx|yarn|pnpm)[[:space:]]+(jest|vitest|mocha|ava) ]] && return 0
    [[ "$cmd" =~ ^[[:space:]]*pytest ]] && return 0
    [[ "$cmd" =~ ^[[:space:]]*jest ]] && return 0
    [[ "$cmd" =~ ^[[:space:]]*vitest ]] && return 0
    [[ "$cmd" =~ ^[[:space:]]*mocha ]] && return 0
    [[ "$cmd" =~ ^[[:space:]]*go[[:space:]]+test ]] && return 0
    [[ "$cmd" =~ ^[[:space:]]*cargo[[:space:]]+test ]] && return 0
    [[ "$cmd" =~ ^[[:space:]]*mix[[:space:]]+test ]] && return 0
    [[ "$cmd" =~ ^[[:space:]]*rspec ]] && return 0
    [[ "$cmd" =~ ^[[:space:]]*phpunit ]] && return 0
    [[ "$cmd" =~ ^[[:space:]]*ruby[[:space:]]+-I.*test ]] && return 0
    [[ "$cmd" =~ ^[[:space:]]*python.*-m[[:space:]]+(unittest|pytest) ]] && return 0
    [[ "$cmd" =~ ^[[:space:]]*node[[:space:]]+--test ]] && return 0
    [[ "$cmd" =~ ^[[:space:]]*deno[[:space:]]+test ]] && return 0
    [[ "$cmd" =~ ^[[:space:]]*bun[[:space:]]+test ]] && return 0
    return 1
}

# Exit if not a test command
is_test_command "$COMMAND" || exit 0

# Detect result from output
detect_result() {
    local output="$1"
    
    # No output = can't determine
    [[ -z "$output" ]] && echo "unknown" && return
    
    # Check for failure patterns first (more specific)
    if [[ "$output" =~ (FAIL|FAILED|failed|failure|Error:|AssertionError|✗|✕|[0-9]+[[:space:]]+failing) ]]; then
        echo "fail"
        return
    fi
    
    # Check for success patterns
    if [[ "$output" =~ (PASS|PASSED|passed|success|✓|✔|[0-9]+[[:space:]]+passing|All[[:space:]]+tests[[:space:]]+passed|OK) ]]; then
        echo "pass"
        return
    fi
    
    # Default: unknown
    echo "unknown"
}

RESULT=$(detect_result "$OUTPUT")

# Set event type and summary
case "$RESULT" in
    pass)
        EVENT_TYPE="test_pass"
        SUMMARY="Tests passing"
        ;;
    fail)
        EVENT_TYPE="test_fail"
        SUMMARY="Tests failing"
        ;;
    *)
        EVENT_TYPE="test_run"
        SUMMARY="Tests executed"
        ;;
esac

# Try to extract counts from output
if [[ -n "$OUTPUT" ]]; then
    # Jest/Vitest style: "X passed, Y failed"
    if [[ "$OUTPUT" =~ ([0-9]+)[[:space:]]+(passed|passing) ]]; then
        PASSED="${BASH_REMATCH[1]}"
        SUMMARY="$PASSED tests passing"
    fi
    if [[ "$OUTPUT" =~ ([0-9]+)[[:space:]]+(failed|failing) ]]; then
        FAILED="${BASH_REMATCH[1]}"
        if [[ "$EVENT_TYPE" == "test_fail" ]]; then
            SUMMARY="$FAILED tests failing"
        elif [[ -n "$PASSED" ]]; then
            SUMMARY="$PASSED passing, $FAILED failing"
        fi
    fi
fi

# Log the event
log_event "$EVENT_TYPE" "$SUMMARY" "hook" "[]"

exit 0
