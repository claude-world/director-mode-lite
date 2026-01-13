#!/bin/bash
# Changelog Logger - Core logging functions for observability
# Director Mode Lite
#
# This script provides the core logging functionality.
# Called by other hooks to record events.

set -euo pipefail

CHANGELOG_DIR=".director-mode"
CHANGELOG_FILE="$CHANGELOG_DIR/changelog.jsonl"
MAX_LINES=500  # Rotate when exceeding this

# Ensure directory exists
ensure_dir() {
    mkdir -p "$CHANGELOG_DIR"
}

# Generate event ID
generate_id() {
    echo "evt_$(date +%s)_$RANDOM"
}

# Get current timestamp
get_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%S.000Z"
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
        mv "$CHANGELOG_FILE" "$CHANGELOG_DIR/$archive_name"
        # Log rotation event to new file
        local ts=$(get_timestamp)
        echo "{\"id\":\"evt_rotation\",\"timestamp\":\"$ts\",\"event_type\":\"changelog_rotated\",\"agent\":\"system\",\"iteration\":null,\"summary\":\"Rotated to $archive_name\",\"files\":[]}" > "$CHANGELOG_FILE"
    fi
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
    
    # Escape summary for JSON (basic escaping)
    summary=$(echo "$summary" | sed 's/\\/\\\\/g; s/"/\\"/g; s/	/\\t/g' | tr '\n' ' ' | head -c 200)
    
    # Build JSON event
    local event="{\"id\":\"$id\",\"timestamp\":\"$timestamp\",\"event_type\":\"$event_type\",\"agent\":\"$agent\",\"iteration\":$iteration,\"summary\":\"$summary\",\"files\":$files}"
    
    # Append to changelog
    echo "$event" >> "$CHANGELOG_FILE"
}

# Archive current changelog (for session restart)
archive_changelog() {
    if [[ -f "$CHANGELOG_FILE" ]]; then
        local line_count
        line_count=$(wc -l < "$CHANGELOG_FILE" 2>/dev/null | tr -d ' ') || line_count=0
        
        if [[ "$line_count" -gt 0 ]]; then
            local archive_name="changelog.$(date +%Y%m%d_%H%M%S).jsonl"
            mv "$CHANGELOG_FILE" "$CHANGELOG_DIR/$archive_name"
            echo "Archived to $CHANGELOG_DIR/$archive_name"
        fi
    fi
}

# Clear changelog
clear_changelog() {
    rm -f "$CHANGELOG_FILE"
    echo "Changelog cleared"
}

# List archived changelogs
list_archives() {
    ls -la "$CHANGELOG_DIR"/changelog.*.jsonl 2>/dev/null || echo "No archives found"
}

# Export functions for sourcing
export -f ensure_dir generate_id get_timestamp get_iteration log_event rotate_if_needed archive_changelog clear_changelog list_archives
export CHANGELOG_DIR CHANGELOG_FILE MAX_LINES
