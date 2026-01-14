#!/bin/bash
# Self-Evolving Loop - Stop Hook
# Intercepts exit and determines if loop should continue

set -e  # Exit on error for this hook

STATE_DIR=".self-evolving-loop"
CHECKPOINT="$STATE_DIR/state/checkpoint.json"
PHASE_FILE="$STATE_DIR/state/phase.txt"
ITERATION_FILE="$STATE_DIR/state/iteration.txt"
STOP_FILE="$STATE_DIR/state/stop"

# Helper: Read JSON field safely
read_json() {
    local file="$1"
    local field="$2"
    local default="$3"

    if [ -f "$file" ]; then
        result=$(jq -r "$field // \"$default\"" "$file" 2>/dev/null || echo "$default")
        echo "$result"
    else
        echo "$default"
    fi
}

# Check if evolving-loop is active
if [ ! -f "$CHECKPOINT" ]; then
    # No active session, allow exit
    exit 0
fi

# Check if session is idle (not started)
INITIAL_STATUS=$(jq -r '.status // "idle"' "$CHECKPOINT" 2>/dev/null || echo "idle")
if [ "$INITIAL_STATUS" == "idle" ]; then
    # Session not started, allow exit
    exit 0
fi

# Check for stop signal
if [ -f "$STOP_FILE" ]; then
    rm -f "$STOP_FILE"
    echo "Stop signal detected. Ending session."

    # Update status
    jq '.status = "stopped"' "$CHECKPOINT" > tmp.json && mv tmp.json "$CHECKPOINT"

    # Log event
    echo "{\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"event\":\"session_stopped\",\"reason\":\"user_signal\"}" >> "$STATE_DIR/history/events.jsonl"

    exit 0
fi

# Read current state
STATUS=$(read_json "$CHECKPOINT" ".status" "unknown")
CURRENT_PHASE=$(read_json "$CHECKPOINT" ".current_phase" "unknown")
CURRENT_ITERATION=$(read_json "$CHECKPOINT" ".current_iteration" "0")
MAX_ITERATIONS=$(read_json "$CHECKPOINT" ".max_iterations" "50")

# Check if already completed
if [ "$STATUS" == "completed" ]; then
    exit 0
fi

# Check if max iterations reached
if [ "$CURRENT_ITERATION" -ge "$MAX_ITERATIONS" ]; then
    echo "Max iterations ($MAX_ITERATIONS) reached."
    jq '.status = "max_iterations_reached"' "$CHECKPOINT" > tmp.json && mv tmp.json "$CHECKPOINT"
    exit 0
fi

# Determine next phase based on current phase
case "$CURRENT_PHASE" in
    "ANALYZE")
        NEXT_PHASE="GENERATE"
        ;;
    "GENERATE")
        NEXT_PHASE="EXECUTE"
        ;;
    "EXECUTE")
        NEXT_PHASE="VALIDATE"
        ;;
    "VALIDATE")
        NEXT_PHASE="DECIDE"
        ;;
    "DECIDE")
        # Decision determines next phase
        DECISION=$(read_json "$STATE_DIR/reports/decision.json" ".decision" "FIX")
        case "$DECISION" in
            "SHIP")
                NEXT_PHASE="SHIP"
                ;;
            "FIX")
                NEXT_PHASE="EXECUTE"
                ;;
            "EVOLVE")
                NEXT_PHASE="LEARN"
                ;;
            "ABORT")
                jq '.status = "aborted"' "$CHECKPOINT" > tmp.json && mv tmp.json "$CHECKPOINT"
                exit 0
                ;;
            *)
                # Unknown decision, default to FIX
                echo "Warning: Unknown decision '$DECISION', defaulting to FIX" >&2
                NEXT_PHASE="EXECUTE"
                ;;
        esac
        ;;
    "LEARN")
        NEXT_PHASE="EVOLVE"
        ;;
    "EVOLVE")
        # After evolution, increment iteration and go back to EXECUTE
        NEW_ITERATION=$((CURRENT_ITERATION + 1))
        echo "$NEW_ITERATION" > "$ITERATION_FILE"
        jq ".current_iteration = $NEW_ITERATION" "$CHECKPOINT" > tmp.json && mv tmp.json "$CHECKPOINT"
        NEXT_PHASE="EXECUTE"
        ;;
    "SHIP")
        # Completed!
        jq '.status = "completed"' "$CHECKPOINT" > tmp.json && mv tmp.json "$CHECKPOINT"
        exit 0
        ;;
    *)
        echo "Unknown phase: $CURRENT_PHASE"
        exit 1
        ;;
esac

# Update phase
echo "$NEXT_PHASE" > "$PHASE_FILE"
jq ".current_phase = \"$NEXT_PHASE\"" "$CHECKPOINT" > tmp.json && mv tmp.json "$CHECKPOINT"

# Log phase transition
echo "{\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"event\":\"phase_transition\",\"from\":\"$CURRENT_PHASE\",\"to\":\"$NEXT_PHASE\",\"iteration\":$CURRENT_ITERATION}" >> "$STATE_DIR/history/events.jsonl"

# Generate continuation prompt based on next phase
case "$NEXT_PHASE" in
    "ANALYZE")
        PROMPT="Continue Self-Evolving Loop: ANALYZE phase. Use requirement-analyzer agent to analyze the request and generate analysis.json"
        ;;
    "GENERATE")
        PROMPT="Continue Self-Evolving Loop: GENERATE phase. Use skill-synthesizer agent to generate executor, validator, and fixer skills based on analysis.json"
        ;;
    "EXECUTE")
        PROMPT="Continue Self-Evolving Loop: EXECUTE phase. Execute the generated executor skill to implement the requirements following TDD."
        ;;
    "VALIDATE")
        PROMPT="Continue Self-Evolving Loop: VALIDATE phase. Execute the generated validator skill to check implementation quality."
        ;;
    "DECIDE")
        PROMPT="Continue Self-Evolving Loop: DECIDE phase. Use completion-judge agent to evaluate validation results and decide next action."
        ;;
    "LEARN")
        PROMPT="Continue Self-Evolving Loop: LEARN phase. Use experience-extractor agent to analyze failures and extract improvement suggestions."
        ;;
    "EVOLVE")
        PROMPT="Continue Self-Evolving Loop: EVOLVE phase. Use skill-evolver agent to generate improved skill versions based on learning."
        ;;
    "SHIP")
        PROMPT="Continue Self-Evolving Loop: SHIP phase. Finalize the implementation, run final tests, and commit."
        ;;
esac

# Output continuation signal
cat << EOF
{
  "continue": true,
  "reason": "Phase $CURRENT_PHASE completed, continuing to $NEXT_PHASE",
  "prompt": "$PROMPT",
  "iteration": $CURRENT_ITERATION,
  "next_phase": "$NEXT_PHASE"
}
EOF
