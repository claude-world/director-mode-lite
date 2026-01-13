#!/bin/bash
# Log Commit Hook - Records git commit operations
# Director Mode Lite
#
# PostToolUse hook for Bash tool
# Detects git commits and logs them to the changelog

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

# Get command and output
COMMAND="${CLAUDE_COMMAND:-}"
OUTPUT="${CLAUDE_OUTPUT:-}"

# Try to extract from input JSON
if command -v jq &>/dev/null; then
    [[ -z "$COMMAND" ]] && COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || echo "")
    [[ -z "$OUTPUT" ]] && OUTPUT=$(echo "$INPUT" | jq -r '.tool_output // empty' 2>/dev/null || echo "")
fi

# Only process git commit commands
if [[ ! "$COMMAND" =~ git[[:space:]]+commit ]]; then
    exit 0
fi

# Extract commit message from command or output
COMMIT_MSG=""

# Try to get from -m flag
if [[ "$COMMAND" =~ -m[[:space:]]+[\"\']([^\"\']+)[\"\'] ]]; then
    COMMIT_MSG="${BASH_REMATCH[1]}"
elif [[ "$COMMAND" =~ -m[[:space:]]+([^[:space:]]+) ]]; then
    COMMIT_MSG="${BASH_REMATCH[1]}"
fi

# Try to extract SHA from output
COMMIT_SHA=""
if [[ "$OUTPUT" =~ \[([a-zA-Z0-9_/-]+)[[:space:]]+([a-f0-9]{7,}) ]]; then
    COMMIT_SHA="${BASH_REMATCH[2]}"
fi

# Build summary
if [[ -n "$COMMIT_MSG" ]]; then
    # Truncate long messages
    COMMIT_MSG=$(echo "$COMMIT_MSG" | head -c 80)
    SUMMARY="commit: $COMMIT_MSG"
else
    SUMMARY="commit: ${COMMIT_SHA:-unknown}"
fi

# Log the event
log_event "commit" "$SUMMARY" "hook" "[]"

exit 0
