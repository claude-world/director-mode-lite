#!/bin/bash
# Self-Evolving Loop - Phase Tracker Hook
# Tracks phase transitions and generates phase-specific prompts

set +e  # Don't exit on error

STATE_DIR=".self-evolving-loop"
CHECKPOINT="$STATE_DIR/state/checkpoint.json"
PHASE_FILE="$STATE_DIR/state/phase.txt"

# Read current phase
CURRENT_PHASE="ANALYZE"
if [ -f "$PHASE_FILE" ]; then
    CURRENT_PHASE=$(cat "$PHASE_FILE" 2>/dev/null || echo "ANALYZE")
fi

# Generate phase-specific context
case "$CURRENT_PHASE" in
    "ANALYZE")
        cat << 'EOF'
## Phase: ANALYZE

**Agent**: requirement-analyzer
**Purpose**: Deep requirement analysis

**Steps**:
1. Parse the user's request
2. Generate acceptance criteria
3. Assess complexity
4. Suggest implementation strategy
5. Save to .self-evolving-loop/reports/analysis.json

**Expected Output**:
- analysis.json with structured analysis

**Next Phase**: GENERATE
EOF
        ;;
    "GENERATE")
        cat << 'EOF'
## Phase: GENERATE

**Agent**: skill-synthesizer
**Purpose**: Generate custom skills based on analysis

**Steps**:
1. Read .self-evolving-loop/reports/analysis.json
2. Generate executor-v[N].md
3. Generate validator-v[N].md
4. Generate fixer-v[N].md
5. Update checkpoint with skill info

**Expected Output**:
- Three skill files in generated-skills/
- Updated checkpoint.json

**Next Phase**: EXECUTE
EOF
        ;;
    "EXECUTE")
        cat << 'EOF'
## Phase: EXECUTE

**Skill**: Generated executor skill
**Purpose**: Implement the requirements using TDD

**Steps**:
1. Read the generated executor skill
2. For each acceptance criterion:
   a. Write failing test (RED)
   b. Implement code to pass (GREEN)
   c. Refactor if needed
3. Track files changed

**Expected Output**:
- Implementation code
- Test files
- Updated files_changed in checkpoint

**Next Phase**: VALIDATE
EOF
        ;;
    "VALIDATE")
        cat << 'EOF'
## Phase: VALIDATE

**Skill**: Generated validator skill
**Purpose**: Verify implementation quality

**Steps**:
1. Run test suite
2. Run linter
3. Check each AC status
4. Calculate score
5. Generate validation.json

**Expected Output**:
- validation.json with scores and status

**Next Phase**: DECIDE
EOF
        ;;
    "DECIDE")
        cat << 'EOF'
## Phase: DECIDE

**Agent**: completion-judge
**Purpose**: Determine next action based on validation

**Decision Tree**:
- All AC met + score >= 90 → SHIP
- Minor issues (score >= 70) → FIX (back to EXECUTE)
- Major issues or patterns → EVOLVE (go to LEARN)
- Max iterations reached → ABORT

**Expected Output**:
- decision.json with routing info

**Next Phase**: Depends on decision
EOF
        ;;
    "LEARN")
        cat << 'EOF'
## Phase: LEARN

**Agent**: experience-extractor
**Purpose**: Analyze failures and extract learning

**Steps**:
1. Collect failure data
2. Identify patterns
3. Analyze root causes
4. Generate improvement suggestions
5. Save to learning.json

**Expected Output**:
- learning.json with actionable insights

**Next Phase**: EVOLVE
EOF
        ;;
    "EVOLVE")
        cat << 'EOF'
## Phase: EVOLVE

**Agent**: skill-evolver
**Purpose**: Generate improved skill versions

**Steps**:
1. Read learning.json
2. Apply adjustments to current skills
3. Generate new skill versions
4. Update checkpoint
5. Save evolution.json

**Expected Output**:
- New skill versions (v2, v3, etc.)
- Updated checkpoint

**Next Phase**: EXECUTE (new iteration)
EOF
        ;;
    "SHIP")
        cat << 'EOF'
## Phase: SHIP

**Purpose**: Finalize and commit

**Steps**:
1. Run final test suite
2. Clean up temporary files
3. Generate final report
4. Create commit with /smart-commit
5. Update status to "completed"

**Expected Output**:
- final.json with summary
- Git commit

**Session Complete**
EOF
        ;;
esac

exit 0
