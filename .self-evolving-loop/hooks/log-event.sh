#!/bin/bash
# Self-Evolving Loop - Event Logger Hook
# Logs events to the history file for observability
# shellcheck disable=SC2034

set +e  # Don't exit on error - logging should never break the loop

STATE_DIR=".self-evolving-loop"
EVENTS_FILE="$STATE_DIR/history/events.jsonl"
ITERATION_FILE="$STATE_DIR/state/iteration.txt"
LOCK_FILE="$STATE_DIR/.log.lock"

# JSON escape function - handles special characters
json_escape() {
    local str="$1"
    # Escape backslash, double quote, and control characters
    str="${str//\\/\\\\}"    # Escape backslashes first
    str="${str//\"/\\\"}"    # Escape double quotes
    str="${str//$'\n'/\\n}"  # Escape newlines
    str="${str//$'\r'/\\r}"  # Escape carriage returns
    str="${str//$'\t'/\\t}"  # Escape tabs
    printf '%s' "$str"
}

# Ensure directory exists
mkdir -p "$STATE_DIR/history"

# Get current iteration
ITERATION="0"
if [ -f "$ITERATION_FILE" ]; then
    ITERATION=$(cat "$ITERATION_FILE" 2>/dev/null || echo "0")
fi

# Get event type and details from environment or arguments
EVENT_TYPE="${1:-unknown}"
SUMMARY_RAW="${2:-}"
FILES="${3:-[]}"

# Escape summary for JSON safety
SUMMARY=$(json_escape "$SUMMARY_RAW")

# Generate event ID
EVENT_ID="evt_$(date +%s)_$$"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%S.000Z)

# Create event JSON with proper escaping
EVENT="{\"id\":\"$EVENT_ID\",\"timestamp\":\"$TIMESTAMP\",\"event_type\":\"$EVENT_TYPE\",\"iteration\":$ITERATION,\"summary\":\"$SUMMARY\",\"files\":$FILES}"

# Use file locking to prevent race conditions
(
    # Acquire lock (with timeout)
    if command -v flock &> /dev/null; then
        flock -w 5 200 || exit 0  # Skip logging if can't acquire lock
    fi

    # Append to events file
    echo "$EVENT" >> "$EVENTS_FILE"

    # Rotate if too large (> 1000 lines)
    if [ -f "$EVENTS_FILE" ]; then
        LINE_COUNT=$(wc -l < "$EVENTS_FILE" 2>/dev/null | tr -d ' ' || echo "0")
        if [ "$LINE_COUNT" -gt 1000 ]; then
            ARCHIVE_NAME="events.$(date +%Y%m%d_%H%M%S).jsonl"
            mv "$EVENTS_FILE" "$STATE_DIR/history/$ARCHIVE_NAME"
            echo "{\"id\":\"evt_rotate_$(date +%s)\",\"timestamp\":\"$TIMESTAMP\",\"event_type\":\"events_rotated\",\"iteration\":$ITERATION,\"summary\":\"Archived to $ARCHIVE_NAME\",\"files\":[]}" > "$EVENTS_FILE"
        fi
    fi
) 200>"$LOCK_FILE" 2>/dev/null

exit 0
