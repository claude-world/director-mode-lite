#!/bin/bash
# Log Bash Event Hook - Records test results and git commits
# Director Mode Lite
#
# PostToolUse hook for Bash tool
# Detects test runs and git commits, logs to changelog
#
# Input: JSON via stdin (Claude Code PostToolUse format)
# Output: None (always exits 0 to not block)
#
# Note: This single hook handles both tests and commits to avoid stdin conflicts

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
        local ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")
        local iter="null"
        [[ -f ".auto-loop/iteration.txt" ]] && iter=$(cat ".auto-loop/iteration.txt" 2>/dev/null || echo "null")
        echo "{\"id\":\"evt_$(date +%s)_$RANDOM\",\"timestamp\":\"$ts\",\"event_type\":\"$1\",\"agent\":\"$3\",\"iteration\":$iter,\"summary\":\"$2\",\"files\":$4}" >> ".director-mode/changelog.jsonl" 2>/dev/null
    }
    HAS_JQ=false
    command -v jq &>/dev/null && HAS_JQ=true
fi

# Read JSON from stdin ONCE
INPUT=$(cat 2>/dev/null) || INPUT=""
[[ -z "$INPUT" ]] && exit 0

# Parse fields
if ${HAS_JQ:-false}; then
    TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null) || TOOL_NAME=""
    COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null) || COMMAND=""
    OUTPUT=$(echo "$INPUT" | jq -r '.tool_response // empty' 2>/dev/null) || OUTPUT=""
else
    TOOL_NAME=$(echo "$INPUT" | grep -o '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:.*"\([^"]*\)".*/\1/' 2>/dev/null) || TOOL_NAME=""
    COMMAND=$(echo "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:.*"\([^"]*\)".*/\1/' 2>/dev/null) || COMMAND=""
    OUTPUT=""
fi

# Only process Bash tool
[[ "$TOOL_NAME" != "Bash" ]] && exit 0
[[ -z "$COMMAND" ]] && exit 0

# ============================================================
# Check if this is a TEST command
# ============================================================
is_test_command() {
    local cmd="$1"
    # npm/yarn/pnpm
    [[ "$cmd" =~ (npm|yarn|pnpm)[[:space:]]+(test|run[[:space:]]+test) ]] && return 0
    [[ "$cmd" =~ (npm|yarn|pnpm)[[:space:]]+run[[:space:]]+(test:|test-|test$) ]] && return 0
    # Direct test runners
    [[ "$cmd" =~ (npx|yarn|pnpm)[[:space:]]+(jest|vitest|mocha|ava) ]] && return 0
    [[ "$cmd" =~ ^[[:space:]]*(pytest|jest|vitest|mocha|ava)[[:space:]] ]] && return 0
    [[ "$cmd" =~ ^[[:space:]]*(pytest|jest|vitest|mocha)$ ]] && return 0
    # Language-specific
    [[ "$cmd" =~ ^[[:space:]]*go[[:space:]]+test ]] && return 0
    [[ "$cmd" =~ ^[[:space:]]*cargo[[:space:]]+test ]] && return 0
    [[ "$cmd" =~ ^[[:space:]]*mix[[:space:]]+test ]] && return 0
    [[ "$cmd" =~ ^[[:space:]]*rspec ]] && return 0
    [[ "$cmd" =~ ^[[:space:]]*phpunit ]] && return 0
    [[ "$cmd" =~ ^[[:space:]]*python.*-m[[:space:]]+(unittest|pytest) ]] && return 0
    [[ "$cmd" =~ ^[[:space:]]*node[[:space:]]+--test ]] && return 0
    [[ "$cmd" =~ ^[[:space:]]*deno[[:space:]]+test ]] && return 0
    [[ "$cmd" =~ ^[[:space:]]*bun[[:space:]]+test ]] && return 0
    # Build tools
    [[ "$cmd" =~ ^[[:space:]]*make[[:space:]]+test ]] && return 0
    [[ "$cmd" =~ ^[[:space:]]*gradle[[:space:]]+test ]] && return 0
    [[ "$cmd" =~ ^[[:space:]]*mvn[[:space:]]+test ]] && return 0
    [[ "$cmd" =~ ^[[:space:]]*dotnet[[:space:]]+test ]] && return 0
    return 1
}

# ============================================================
# Check if this is a GIT COMMIT command
# ============================================================
is_commit_command() {
    local cmd="$1"
    [[ "$cmd" =~ git[[:space:]]+commit ]] && return 0
    return 1
}

# ============================================================
# Handle TEST command
# ============================================================
handle_test() {
    local output="$1"
    
    # Detect result
    local result="unknown"
    if [[ -n "$output" ]]; then
        if [[ "$output" =~ (FAIL|FAILED|failed|failure|Error:|AssertionError|✗|✕|[0-9]+[[:space:]]+failing) ]]; then
            result="fail"
        elif [[ "$output" =~ (PASS|PASSED|passed|success|✓|✔|[0-9]+[[:space:]]+passing|All[[:space:]]+tests[[:space:]]+passed|OK) ]]; then
            result="pass"
        fi
    fi
    
    # Set event type and summary
    local event_type="test_run"
    local summary="Tests executed"
    
    case "$result" in
        pass)
            event_type="test_pass"
            summary="Tests passing"
            ;;
        fail)
            event_type="test_fail"
            summary="Tests failing"
            ;;
    esac
    
    # Try to extract counts
    if [[ -n "$output" ]]; then
        if [[ "$output" =~ ([0-9]+)[[:space:]]+(passed|passing) ]]; then
            local passed="${BASH_REMATCH[1]}"
            summary="$passed tests passing"
        fi
        if [[ "$output" =~ ([0-9]+)[[:space:]]+(failed|failing) ]]; then
            local failed="${BASH_REMATCH[1]}"
            if [[ "$event_type" == "test_fail" ]]; then
                summary="$failed tests failing"
            fi
        fi
    fi
    
    log_event "$event_type" "$summary" "hook" "[]"
}

# ============================================================
# Handle COMMIT command
# ============================================================
handle_commit() {
    local cmd="$1"
    local output="$2"
    
    local commit_msg=""
    
    # Extract commit message from -m flag
    if [[ "$cmd" =~ -m[[:space:]]*\"([^\"]+)\" ]]; then
        commit_msg="${BASH_REMATCH[1]}"
    elif [[ "$cmd" =~ -m[[:space:]]*\'([^\']+)\' ]]; then
        commit_msg="${BASH_REMATCH[1]}"
    elif [[ "$cmd" =~ -m[[:space:]]*([^[:space:]\"\'][^[:space:]]*) ]]; then
        commit_msg="${BASH_REMATCH[1]}"
    fi
    
    # Try to extract SHA from output
    local commit_sha=""
    if [[ -n "$output" ]] && [[ "$output" =~ \[[^]]+[[:space:]]+([a-f0-9]{7,}) ]]; then
        commit_sha="${BASH_REMATCH[1]}"
    fi
    
    # Build summary
    local summary=""
    if [[ -n "$commit_msg" ]]; then
        # Truncate and basic escape
        commit_msg="${commit_msg:0:60}"
        commit_msg="${commit_msg//\\/\\\\}"
        commit_msg="${commit_msg//\"/\'}"  # Replace quotes with single quotes for safety
        summary="commit: $commit_msg"
    elif [[ -n "$commit_sha" ]]; then
        summary="commit: $commit_sha"
    else
        summary="commit made"
    fi
    
    log_event "commit" "$summary" "hook" "[]"
}

# ============================================================
# Main logic - determine what type of command and handle it
# ============================================================

if is_test_command "$COMMAND"; then
    handle_test "$OUTPUT"
elif is_commit_command "$COMMAND"; then
    handle_commit "$COMMAND" "$OUTPUT"
fi

# Always exit successfully
exit 0
