#!/bin/bash
# Log File Change Hook - Records Write/Edit operations
# Director Mode Lite
#
# PostToolUse hook for Write and Edit tools
# Automatically logs file changes to the changelog
#
# Input: JSON via stdin (Claude Code PostToolUse format)
# Output: None (exit 0 per Hooks guide)

# Never exit on errors - don't break the main flow
set +e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || SCRIPT_DIR="$(pwd)/.claude/hooks"

# Source the logger library
if [[ -f "$SCRIPT_DIR/_lib-changelog.sh" ]]; then
    source "$SCRIPT_DIR/_lib-changelog.sh"
elif [[ -f ".claude/hooks/_lib-changelog.sh" ]]; then
    source ".claude/hooks/_lib-changelog.sh"
else
    # Minimal inline fallback (includes session_id for Claude Code 2.1.9+)
    log_event() {
        mkdir -p ".director-mode" 2>/dev/null
        local ts=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")
        local iter="null"
        local sid="${CLAUDE_SESSION_ID:-default}"
        [[ -f ".auto-loop/iteration.txt" ]] && iter=$(cat ".auto-loop/iteration.txt" 2>/dev/null || echo "null")
        echo "{\"id\":\"evt_$(date +%s)_$RANDOM\",\"timestamp\":\"$ts\",\"session_id\":\"$sid\",\"event_type\":\"$1\",\"agent\":\"$3\",\"iteration\":$iter,\"summary\":\"$2\",\"files\":$4}" >> ".director-mode/changelog.jsonl" 2>/dev/null
    }
    HAS_JQ=false
    command -v jq &>/dev/null && HAS_JQ=true
fi

# Read JSON from stdin (Claude Code PostToolUse format)
INPUT=$(cat 2>/dev/null) || INPUT=""

# Exit if no input
[[ -z "$INPUT" ]] && exit 0

# Parse tool name and file path
if $HAS_JQ; then
    TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null) || TOOL_NAME=""
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null) || FILE_PATH=""
else
    # Fallback: grep parsing
    TOOL_NAME=$(echo "$INPUT" | grep -o '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:.*"\([^"]*\)".*/\1/' 2>/dev/null) || TOOL_NAME=""
    FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:.*"\([^"]*\)".*/\1/' 2>/dev/null) || FILE_PATH=""
fi

# Exit if we couldn't parse tool name
[[ -z "$TOOL_NAME" ]] && exit 0

# Determine event type
# Note: Write tool overwrites files, so we use "file_write" (not "file_created")
# since we can't know if the file existed before without PreToolUse context
case "$TOOL_NAME" in
    Write)
        EVENT_TYPE="file_write"
        ;;
    Edit)
        EVENT_TYPE="file_edit"
        ;;
    *)
        # Not a file change tool
        exit 0
        ;;
esac

# Build summary and files JSON
if [[ -n "$FILE_PATH" ]]; then
    FILENAME=$(basename "$FILE_PATH" 2>/dev/null) || FILENAME="$FILE_PATH"
    SUMMARY="$EVENT_TYPE: $FILENAME"
    # Escape file path for JSON
    FILE_PATH_ESCAPED="${FILE_PATH//\\/\\\\}"
    FILE_PATH_ESCAPED="${FILE_PATH_ESCAPED//\"/\\\"}"
    FILES_JSON="[\"$FILE_PATH_ESCAPED\"]"
else
    SUMMARY="$EVENT_TYPE: unknown file"
    FILES_JSON="[]"
fi

# Log the event
log_event "$EVENT_TYPE" "$SUMMARY" "hook" "$FILES_JSON"

exit 0
