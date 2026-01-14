---
description: Self-Evolving Development Loop - Dynamic skill generation with learning and evolution
user-invocable: true
---

# Self-Evolving Development Loop

Execute an autonomous development cycle that dynamically generates, validates, and evolves its own execution strategy.

---

## Usage

```bash
# Start new task
/evolving-loop "Implement user authentication"

# With acceptance criteria
/evolving-loop "Build REST API

Acceptance Criteria:
- [ ] GET /users endpoint
- [ ] POST /users endpoint
- [ ] Input validation
- [ ] Error handling
"

# Resume interrupted session
/evolving-loop --resume

# Force restart (clear old state)
/evolving-loop --force "New task"

# Check status
/evolving-loop --status

# With iteration limit
/evolving-loop "Task" --max-iterations 30
```

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    SELF-EVOLVING DEVELOPMENT LOOP                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐   │
│  │   PHASE 1   │───▶│   PHASE 2   │───▶│   PHASE 3   │───▶│   PHASE 4   │   │
│  │   ANALYZE   │    │   GENERATE  │    │   EXECUTE   │    │  VALIDATE   │   │
│  │  (需求分析)  │    │ (生成Skills) │    │  (執行開發)  │    │  (驗證結果)  │   │
│  └─────────────┘    └─────────────┘    └─────────────┘    └──────┬──────┘   │
│         ▲                                                        │          │
│         │                                                        ▼          │
│         │           ┌─────────────┐    ┌─────────────┐    ┌─────────────┐   │
│         │           │   PHASE 7   │◀───│   PHASE 6   │◀───│   PHASE 5   │   │
│         └───────────│   EVOLVE    │    │    LEARN    │    │   DECIDE    │   │
│                     │ (進化Skills) │    │  (學習經驗)  │    │  (決策判斷)  │   │
│                     └─────────────┘    └─────────────┘    └─────────────┘   │
│                                                                              │
│  Pass ✓ ────────────────────────────────────────────────────▶ PHASE 8: SHIP │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Execution

When user runs `/evolving-loop "$ARGUMENTS"`:

### 1. State Detection

```bash
STATE_DIR=".self-evolving-loop"
CHECKPOINT="$STATE_DIR/state/checkpoint.json"

# Check for --status flag
if [[ "$ARGUMENTS" == *"--status"* ]]; then
    if [ -f "$CHECKPOINT" ]; then
        echo "=== Self-Evolving Loop Status ==="
        jq -r '"Status: \(.status)\nPhase: \(.current_phase // "N/A")\nIteration: \(.current_iteration)/\(.max_iterations)\nRequest: \(.request | .[0:50])..."' "$CHECKPOINT"
        echo ""
        echo "Skill Versions:"
        jq -r '.skill_versions | to_entries | .[] | "  \(.key): v\(.value)"' "$CHECKPOINT"
        exit 0
    else
        echo "No active session found."
        exit 0
    fi
fi

# Check for --resume flag
if [[ "$ARGUMENTS" == *"--resume"* ]]; then
    if [ -f "$CHECKPOINT" ]; then
        CURRENT_PHASE=$(jq -r '.current_phase // "ANALYZE"' "$CHECKPOINT")
        echo "Resuming from phase: $CURRENT_PHASE"
        # Continue from current phase
    else
        echo "No session to resume. Start a new one with /evolving-loop \"task\""
        exit 1
    fi
fi

# Check for existing in-progress session
if [ -f "$CHECKPOINT" ]; then
    status=$(jq -r '.status // "unknown"' "$CHECKPOINT")
    if [ "$status" == "in_progress" ] && [[ "$ARGUMENTS" != *"--force"* ]]; then
        iteration=$(jq -r '.current_iteration // 0' "$CHECKPOINT")
        phase=$(jq -r '.current_phase // "unknown"' "$CHECKPOINT")
        echo "⚠️  Found active session at iteration #$iteration (phase: $phase)"
        echo ""
        echo "Options:"
        echo "  /evolving-loop --resume        → Continue from current phase"
        echo "  /evolving-loop --force \"...\"  → Clear old state, start fresh"
        echo "  /evolving-loop --status        → View detailed status"
        exit 1
    fi
fi
```

### 2. Initialize New Session

```bash
# Create directories
mkdir -p "$STATE_DIR"/{state,generated-skills,reports,history,hooks}

# Parse max-iterations flag
MAX_ITER=50
if [[ "$ARGUMENTS" =~ --max-iterations[[:space:]]+([0-9]+) ]]; then
    MAX_ITER="${BASH_REMATCH[1]}"
fi

# Clean the request (remove flags)
REQUEST=$(echo "$ARGUMENTS" | sed 's/--max-iterations[[:space:]]*[0-9]*//g' | sed 's/--force//g' | xargs)

# Initialize checkpoint
cat > "$CHECKPOINT" << EOF
{
  "version": "1.0.0",
  "request": "$REQUEST",
  "current_phase": "ANALYZE",
  "current_iteration": 0,
  "max_iterations": $MAX_ITER,
  "status": "in_progress",
  "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "acceptance_criteria": [],
  "generated_skills": {
    "executor": null,
    "validator": null,
    "fixer": null
  },
  "skill_versions": {
    "executor": 0,
    "validator": 0,
    "fixer": 0
  },
  "validation_history": [],
  "evolution_history": [],
  "files_changed": [],
  "last_validation_result": null
}
EOF

echo "0" > "$STATE_DIR/state/iteration.txt"
echo "ANALYZE" > "$STATE_DIR/state/phase.txt"

# Log session start
echo "{\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"event\":\"session_start\",\"request\":\"$REQUEST\"}" >> "$STATE_DIR/history/events.jsonl"
```

### 3. Execute Phases

#### PHASE 1: ANALYZE

Use the `requirement-analyzer` agent:

```
Task(subagent_type="requirement-analyzer", prompt="""
Analyze the following requirement and generate a structured analysis report.

Requirement:
$REQUEST

Save output to: .self-evolving-loop/reports/analysis.json

Include:
1. Parsed acceptance criteria
2. Complexity assessment
3. Implementation strategy suggestion
4. Codebase context analysis
""")
```

After completion:
- Update phase: `echo "GENERATE" > .self-evolving-loop/state/phase.txt`
- Update checkpoint with analysis results

#### PHASE 2: GENERATE

Use the `skill-synthesizer` agent:

```
Task(subagent_type="skill-synthesizer", prompt="""
Generate tailored skills based on the analysis report.

Input: .self-evolving-loop/reports/analysis.json

Generate:
1. Executor skill → .self-evolving-loop/generated-skills/executor-v1.md
2. Validator skill → .self-evolving-loop/generated-skills/validator-v1.md
3. Fixer skill → .self-evolving-loop/generated-skills/fixer-v1.md

Use templates from: .self-evolving-loop/templates/
""")
```

After completion:
- Create symlinks to .claude/commands/
- Update checkpoint with skill info
- Update phase: `echo "EXECUTE" > .self-evolving-loop/state/phase.txt`

#### PHASE 3: EXECUTE

Execute the generated executor skill:

```
# Read the generated executor skill and execute its instructions
# This follows TDD: Red → Green → Refactor cycle

For each acceptance criterion:
1. Write failing test (RED)
2. Implement minimal code (GREEN)
3. Refactor if needed
4. Commit progress
```

After completion:
- Update files_changed in checkpoint
- Update phase: `echo "VALIDATE" > .self-evolving-loop/state/phase.txt`

#### PHASE 4: VALIDATE

Execute the generated validator skill:

```
# Run validation against all criteria
# Generate validation report

Output: .self-evolving-loop/reports/validation.json
```

After completion:
- Store validation result in checkpoint
- Update phase: `echo "DECIDE" > .self-evolving-loop/state/phase.txt`

#### PHASE 5: DECIDE

Use the `completion-judge` agent:

```
Task(subagent_type="completion-judge", prompt="""
Evaluate validation results and decide next action.

Input:
- .self-evolving-loop/reports/validation.json
- .self-evolving-loop/state/checkpoint.json

Decide: SHIP | FIX | EVOLVE | ABORT

Output decision to: .self-evolving-loop/reports/decision.json
""")
```

**Decision routing:**
- `SHIP` → Phase 8
- `FIX` → Phase 3 (re-execute with fixer)
- `EVOLVE` → Phase 6 (learn and evolve)
- `ABORT` → End session

#### PHASE 6: LEARN (if needed)

Use the `experience-extractor` agent:

```
Task(subagent_type="experience-extractor", prompt="""
Analyze failures and extract learning.

Input:
- Validation reports
- Decision history
- Changelog

Output: .self-evolving-loop/reports/learning.json
""")
```

After completion:
- Update phase: `echo "EVOLVE" > .self-evolving-loop/state/phase.txt`

#### PHASE 7: EVOLVE (if needed)

Use the `skill-evolver` agent:

```
Task(subagent_type="skill-evolver", prompt="""
Apply learning to generate improved skill versions.

Input: .self-evolving-loop/reports/learning.json
Current skills: .self-evolving-loop/generated-skills/

Generate new versions with improvements.
Update checkpoint with new versions.
""")
```

After completion:
- Increment iteration counter
- Update phase: `echo "EXECUTE" > .self-evolving-loop/state/phase.txt`
- Loop back to Phase 3

#### PHASE 8: SHIP

```bash
# Final cleanup and commit
echo "=== SHIP Phase ==="

# Run final tests
npm test || pytest || go test ./...

# Clean up temp files
rm -f .self-evolving-loop/reports/fix-result.json

# Generate final report
cat > .self-evolving-loop/reports/final.json << EOF
{
  "status": "completed",
  "iterations": $(cat .self-evolving-loop/state/iteration.txt),
  "evolution_count": $(jq '.skill_versions.executor' .self-evolving-loop/state/checkpoint.json),
  "completed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

# Update checkpoint
jq '.status = "completed" | .current_phase = "SHIP"' "$CHECKPOINT" > tmp.json && mv tmp.json "$CHECKPOINT"

# Use smart-commit
/smart-commit

echo "✅ Self-Evolving Loop completed successfully!"
```

---

## Flags

| Flag | Description |
|------|-------------|
| `--resume` | Continue interrupted session |
| `--force` | Clear old state, start fresh |
| `--status` | Show current session status |
| `--max-iterations N` | Set iteration limit (default: 50) |

---

## Agents Used

| Phase | Agent | Purpose |
|-------|-------|---------|
| ANALYZE | `requirement-analyzer` | Deep requirement analysis |
| GENERATE | `skill-synthesizer` | Dynamic skill generation |
| EXECUTE | (generated executor) | Task implementation |
| VALIDATE | (generated validator) | Quality verification |
| DECIDE | `completion-judge` | Decision making |
| LEARN | `experience-extractor` | Failure analysis |
| EVOLVE | `skill-evolver` | Skill improvement |

---

## Files Structure

```
.self-evolving-loop/
├── state/
│   ├── checkpoint.json      # Main state
│   ├── iteration.txt        # Current iteration
│   └── phase.txt            # Current phase
├── generated-skills/
│   ├── executor-v1.md       # Generated executor
│   ├── validator-v1.md      # Generated validator
│   └── fixer-v1.md          # Generated fixer
├── reports/
│   ├── analysis.json        # Phase 1 output
│   ├── validation.json      # Phase 4 output
│   ├── decision.json        # Phase 5 output
│   ├── learning.json        # Phase 6 output
│   └── evolution.json       # Phase 7 output
├── history/
│   ├── events.jsonl         # All events
│   ├── decision-log.jsonl   # Decision history
│   ├── learning-log.jsonl   # Learning history
│   └── skill-evolution.jsonl # Evolution history
├── templates/
│   ├── executor-template.md
│   ├── validator-template.md
│   └── fixer-template.md
└── hooks/
    ├── continue-loop.sh     # Stop hook
    └── log-event.sh         # Event logger
```

---

## Observability

```bash
# View current status
/evolving-loop --status

# View event history
cat .self-evolving-loop/history/events.jsonl | jq '.'

# View skill evolution
cat .self-evolving-loop/history/skill-evolution.jsonl | jq '.'

# View validation history
ls -la .self-evolving-loop/reports/validation*.json
```

---

## Interrupt

```bash
# Create stop signal
touch .self-evolving-loop/state/stop

# Loop stops after current phase completes
```

---

## Key Differences from auto-loop

| Feature | auto-loop | evolving-loop |
|---------|-----------|---------------|
| Strategy | Fixed TDD steps | Dynamic generation |
| Skills | Uses existing | Generates custom |
| Failure handling | Retry same | Learn & evolve |
| Learning | None | Extracts patterns |
| Adaptation | Low | High |

---

## Community

Questions? Join [Claude World](https://claude-world.com).
