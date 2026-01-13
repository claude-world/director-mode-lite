#!/bin/bash
# Changelog Logger - Core logging functions for observability
# Director Mode Lite
#
# This script provides the core logging functionality.
# Called by other hooks to record events.
#
# Note: This is experimental. Hook interface may change in future Claude Code versions.

# Don't exit on errors - logging should never break the main flow
set +e

CHANGELOG_DIR=".director-mode"
CHANGELOG_FILE="$CHANGELOG_DIR/changelog.jsonl"
# Configurable via environment variable
MAX_LINES="${DIRECTOR_MODE_MAX_CHANGELOG_LINES:-500}"

# Check if jq is available
HAS_JQ=false
if command -v jq &>/dev/null; then
    HAS_JQ=true
fi

# JSON parse helper (with jq fallback)
json_get() {
    local json="$1"
    local key="$2"
    
    if $HAS_JQ; then
        echo "$json" | jq -r "$key // empty" 2>/dev/null
    else
        # Fallback: basic grep/sed parsing (handles simple cases)
        # This is not a full JSON parser, but handles our use cases
        local simple_key="${key#.}"  # Remove leading dot
        simple_key="${simple_key%%.*}"  # Get first key only
        echo "$json" | grep -o "\"$simple_key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 | sed 's/.*:.*"\([^"]*\)".*/\1/' 2>/dev/null
    fi
}

# Ensure directory exists
ensure_dir() {
    mkdir -p "$CHANGELOG_DIR" 2>/dev/null || true
}

# Generate event ID
generate_id() {
    echo "evt_$(date +%s)_$RANDOM"
}

# Get current timestamp
get_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%S.000Z" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ"
}

# Get current iteration (if auto-loop is active)
get_iteration() {
    if [[ -f ".auto-loop/iteration.txt" ]]; then
        cat ".auto-loop/iteration.txt" 2>/dev/null || echo "null"
    else
        echo "null"
    fi
}

# Rotate changelog if too large
rotate_if_needed() {
    if [[ ! -f "$CHANGELOG_FILE" ]]; then
        return 0
    fi
    
    local line_count
    line_count=$(wc -l < "$CHANGELOG_FILE" 2>/dev/null | tr -d ' ') || line_count=0
    
    if [[ "$line_count" -gt "$MAX_LINES" ]]; then
        local archive_name="changelog.$(date +%Y%m%d_%H%M%S).jsonl"
        mv "$CHANGELOG_FILE" "$CHANGELOG_DIR/$archive_name" 2>/dev/null || true
        # Log rotation event
        local ts=$(get_timestamp)
        echo "{\"id\":\"evt_rotation\",\"timestamp\":\"$ts\",\"event_type\":\"changelog_rotated\",\"agent\":\"system\",\"iteration\":null,\"summary\":\"Rotated to $archive_name\",\"files\":[]}" > "$CHANGELOG_FILE" 2>/dev/null || true
    fi
}

# Escape string for JSON
escape_json() {
    local str="$1"
    # Escape backslash first, then other special characters
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    str="${str//$'\n'/\\n}"
    str="${str//$'\t'/\\t}"
    str="${str//$'\r'/\\r}"
    str="${str//$'\b'/\\b}"
    str="${str//$'\f'/\\f}"
    # Truncate to max length (consistent with log-bash-event.sh)
    echo "${str:0:100}"
}

# Log an event to changelog
# Usage: log_event <event_type> <summary> [agent] [files_json]
log_event() {
    local event_type="${1:-unknown}"
    local summary="${2:-}"
    local agent="${3:-system}"
    local files="${4:-[]}"
    
    ensure_dir
    rotate_if_needed
    
    local id=$(generate_id)
    local timestamp=$(get_timestamp)
    local iteration=$(get_iteration)
    
    # Escape summary for JSON
    summary=$(escape_json "$summary")
    
    # Build and append event
    echo "{\"id\":\"$id\",\"timestamp\":\"$timestamp\",\"event_type\":\"$event_type\",\"agent\":\"$agent\",\"iteration\":$iteration,\"summary\":\"$summary\",\"files\":$files}" >> "$CHANGELOG_FILE" 2>/dev/null || true
}

# Archive current changelog
archive_changelog() {
    if [[ -f "$CHANGELOG_FILE" ]]; then
        local line_count
        line_count=$(wc -l < "$CHANGELOG_FILE" 2>/dev/null | tr -d ' ') || line_count=0
        
        if [[ "$line_count" -gt 0 ]]; then
            local archive_name="changelog.$(date +%Y%m%d_%H%M%S).jsonl"
            mv "$CHANGELOG_FILE" "$CHANGELOG_DIR/$archive_name" 2>/dev/null
            echo "Archived to $CHANGELOG_DIR/$archive_name"
        fi
    fi
}

# Clear changelog
clear_changelog() {
    rm -f "$CHANGELOG_FILE" 2>/dev/null
    echo "Changelog cleared"
}

# Export functions for sourcing
export -f ensure_dir generate_id get_timestamp get_iteration log_event rotate_if_needed archive_changelog clear_changelog json_get escape_json 2>/dev/null || true
export CHANGELOG_DIR CHANGELOG_FILE MAX_LINES HAS_JQ 2>/dev/null || true
