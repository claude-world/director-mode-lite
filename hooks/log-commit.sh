#!/bin/bash
# Log Commit Hook - Records git commit operations
# Director Mode Lite
#
# PostToolUse hook for Bash tool
# Detects git commits and logs them to the changelog
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
    OUTPUT=""
fi

# Only process Bash tool
[[ "$TOOL_NAME" != "Bash" ]] && exit 0
[[ -z "$COMMAND" ]] && exit 0

# Only process git commit commands
[[ ! "$COMMAND" =~ git[[:space:]]+commit ]] && exit 0

# Extract commit message
COMMIT_MSG=""

# Try to get from -m flag (various formats)
# git commit -m "message"
# git commit -m 'message'
# git commit -m message
if [[ "$COMMAND" =~ -m[[:space:]]+\"([^\"]+)\" ]]; then
    COMMIT_MSG="${BASH_REMATCH[1]}"
elif [[ "$COMMAND" =~ -m[[:space:]]+\'([^\']+)\' ]]; then
    COMMIT_MSG="${BASH_REMATCH[1]}"
elif [[ "$COMMAND" =~ -m[[:space:]]+([^[:space:]\"\'][^[:space:]]*) ]]; then
    COMMIT_MSG="${BASH_REMATCH[1]}"
fi

# Try to extract SHA from output
COMMIT_SHA=""
if [[ -n "$OUTPUT" ]]; then
    # Pattern: [branch abc1234] or [branch abc1234567890]
    if [[ "$OUTPUT" =~ \[[^]]+[[:space:]]+([a-f0-9]{7,}) ]]; then
        COMMIT_SHA="${BASH_REMATCH[1]}"
    fi
fi

# Build summary
if [[ -n "$COMMIT_MSG" ]]; then
    # Truncate long messages and escape
    COMMIT_MSG="${COMMIT_MSG:0:60}"
    COMMIT_MSG="${COMMIT_MSG//\\/\\\\}"
    COMMIT_MSG="${COMMIT_MSG//\"/\\\"}"
    SUMMARY="commit: $COMMIT_MSG"
elif [[ -n "$COMMIT_SHA" ]]; then
    SUMMARY="commit: $COMMIT_SHA"
else
    SUMMARY="commit: (message unknown)"
fi

# Log the event
log_event "commit" "$SUMMARY" "hook" "[]"

exit 0
