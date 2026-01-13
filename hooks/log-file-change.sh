#!/bin/bash
# Log File Change Hook - Records Write/Edit operations
# Director Mode Lite
#
# PostToolUse hook for Write and Edit tools
# Automatically logs file changes to the changelog

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/changelog-logger.sh" 2>/dev/null || {
    # Inline fallback if source fails
    CHANGELOG_FILE=".director-mode/changelog.jsonl"
    mkdir -p ".director-mode"
    log_event() {
        local ts=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
        local iter="null"
        [[ -f ".auto-loop/iteration.txt" ]] && iter=$(cat ".auto-loop/iteration.txt" 2>/dev/null || echo "null")
        echo "{\"id\":\"evt_$(date +%s)_$RANDOM\",\"timestamp\":\"$ts\",\"event_type\":\"$1\",\"agent\":\"$3\",\"iteration\":$iter,\"summary\":\"$2\",\"files\":$4}" >> "$CHANGELOG_FILE"
    }
}

# Read hook input from stdin (Claude Code passes JSON)
INPUT=$(cat)

# Parse tool name and file path from hook environment or input
TOOL_NAME="${CLAUDE_TOOL_NAME:-}"
FILE_PATH="${CLAUDE_FILE_PATH:-}"

# Try to extract from input JSON if env vars not set
if [[ -z "$TOOL_NAME" ]] && command -v jq &>/dev/null; then
    TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null || echo "")
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null || echo "")
fi

# Determine event type
case "$TOOL_NAME" in
    Write)
        EVENT_TYPE="file_created"
        ;;
    Edit)
        EVENT_TYPE="file_modified"
        ;;
    *)
        EVENT_TYPE="file_changed"
        ;;
esac

# Build summary
if [[ -n "$FILE_PATH" ]]; then
    FILENAME=$(basename "$FILE_PATH")
    SUMMARY="$EVENT_TYPE: $FILENAME"
    FILES_JSON="[\"$FILE_PATH\"]"
else
    SUMMARY="$EVENT_TYPE: unknown file"
    FILES_JSON="[]"
fi

# Log the event
log_event "$EVENT_TYPE" "$SUMMARY" "hook" "$FILES_JSON"

# Exit successfully (don't block the operation)
exit 0
