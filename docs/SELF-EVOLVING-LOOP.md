# Self-Evolving Development Loop

A meta-automation system that dynamically generates, validates, and evolves its own execution strategy based on learning from failures.

## Overview

Unlike traditional automation that follows fixed steps, the Self-Evolving Loop:

1. **Analyzes** requirements to understand what's needed
2. **Generates** custom skills tailored to the specific task
3. **Executes** the generated skills using TDD
4. **Validates** the results against criteria
5. **Learns** from failures to identify patterns
6. **Evolves** its strategy by improving the skills
7. **Ships** when all criteria are met

## Quick Start

```bash
# Start a new evolving loop
/evolving-loop "Implement user authentication

Acceptance Criteria:
- [ ] Login endpoint with email/password
- [ ] JWT token generation
- [ ] Token validation middleware
- [ ] Error handling for invalid credentials
"

# Check status
/evolving-status

# Resume interrupted session
/evolving-loop --resume
```

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    SELF-EVOLVING DEVELOPMENT LOOP                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐   │
│  │   PHASE 1   │───▶│   PHASE 2   │───▶│   PHASE 3   │───▶│   PHASE 4   │   │
│  │   ANALYZE   │    │   GENERATE  │    │   EXECUTE   │    │  VALIDATE   │   │
│  └─────────────┘    └─────────────┘    └─────────────┘    └──────┬──────┘   │
│         ▲                                                        │          │
│         │                                                        ▼          │
│         │           ┌─────────────┐    ┌─────────────┐    ┌─────────────┐   │
│         │           │   PHASE 7   │◀───│   PHASE 6   │◀───│   PHASE 5   │   │
│         └───────────│   EVOLVE    │    │    LEARN    │    │   DECIDE    │   │
│                     └─────────────┘    └─────────────┘    └─────────────┘   │
│                                                                              │
│  Pass ✓ ────────────────────────────────────────────────────▶ PHASE 8: SHIP │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Phases

### Phase 1: ANALYZE

**Agent**: `requirement-analyzer`

Deeply analyzes user requirements to produce:
- Parsed acceptance criteria
- Complexity assessment (1-10)
- Implementation strategy suggestion
- Codebase context analysis

**Output**: `.self-evolving-loop/reports/analysis.json`

### Phase 2: GENERATE

**Agent**: `skill-synthesizer`

Generates three custom skills based on the analysis:
- **Executor**: Handles implementation with TDD
- **Validator**: Verifies quality and correctness
- **Fixer**: Auto-corrects identified issues

**Output**: `.self-evolving-loop/generated-skills/`

### Phase 3: EXECUTE

Uses the generated executor skill to implement requirements:
- RED: Write failing tests
- GREEN: Implement minimal code
- REFACTOR: Clean up

### Phase 4: VALIDATE

Uses the generated validator skill to check:
- Functional correctness (40%)
- Code quality (25%)
- Test coverage (25%)
- Security (10%)

**Output**: `.self-evolving-loop/reports/validation.json`

### Phase 5: DECIDE

**Agent**: `completion-judge`

Evaluates validation results and decides:
- **SHIP**: All criteria met, proceed to finalize
- **FIX**: Minor issues, try auto-fix and re-execute
- **EVOLVE**: Major issues or patterns, learn and improve skills
- **ABORT**: Max iterations reached or unrecoverable error

### Phase 6: LEARN

**Agent**: `experience-extractor`

Analyzes failures to extract:
- Failure patterns
- Root causes
- Improvement suggestions
- Skill adjustment recommendations

**Output**: `.self-evolving-loop/reports/learning.json`

### Phase 7: EVOLVE

**Agent**: `skill-evolver`

Applies learning insights to:
- Generate improved skill versions
- Update strategy based on patterns
- Track version history

**Output**: New skill versions (v2, v3, etc.)

### Phase 8: SHIP

Finalizes the implementation:
- Run final test suite
- Clean up temporary files
- Generate final report
- Create commit

## File Structure

```
.self-evolving-loop/
├── state/
│   ├── checkpoint.json      # Main state file
│   ├── iteration.txt        # Current iteration number
│   └── phase.txt            # Current phase
├── generated-skills/
│   ├── executor-v1.md       # Generated executor skill
│   ├── executor-v2.md       # Evolved executor skill
│   ├── validator-v1.md      # Generated validator skill
│   └── fixer-v1.md          # Generated fixer skill
├── reports/
│   ├── analysis.json        # Requirement analysis
│   ├── validation.json      # Validation results
│   ├── decision.json        # Decision output
│   ├── learning.json        # Learning insights
│   └── evolution.json       # Evolution report
├── history/
│   ├── events.jsonl         # All events log
│   ├── decision-log.jsonl   # Decision history
│   ├── learning-log.jsonl   # Learning history
│   └── skill-evolution.jsonl # Evolution history
├── templates/
│   ├── executor-template.md
│   ├── validator-template.md
│   └── fixer-template.md
└── hooks/
    ├── continue-loop.sh     # Stop hook for continuation
    ├── log-event.sh         # Event logger
    └── phase-tracker.sh     # Phase tracking
```

## Commands

| Command | Description |
|---------|-------------|
| `/evolving-loop "task"` | Start new session |
| `/evolving-loop --resume` | Resume interrupted session |
| `/evolving-loop --force "task"` | Clear state, start fresh |
| `/evolving-loop --status` | Quick status check |
| `/evolving-status` | Detailed status view |
| `/evolving-status --history` | View event history |
| `/evolving-status --evolution` | View skill evolution |

## Agents

| Agent | Phase | Purpose |
|-------|-------|---------|
| `requirement-analyzer` | ANALYZE | Deep requirement analysis |
| `skill-synthesizer` | GENERATE | Dynamic skill generation |
| `completion-judge` | DECIDE | Decision making |
| `experience-extractor` | LEARN | Failure analysis |
| `skill-evolver` | EVOLVE | Skill improvement |

## Comparison with auto-loop

| Feature | auto-loop | evolving-loop |
|---------|-----------|---------------|
| Strategy | Fixed TDD steps | Dynamic generation |
| Skills | Uses existing | Generates custom |
| Failure handling | Retry same | Learn & evolve |
| Learning | None | Extracts patterns |
| Adaptation | Low | High |
| Max iterations | 20 (default) | 50 (default) |
| Use case | Simple TDD | Complex features |

## Best Practices

### Writing Good Acceptance Criteria

```markdown
Good:
- [ ] GET /users returns JSON array of users
- [ ] POST /users with valid data returns 201 status
- [ ] POST /users with invalid email returns 400 with error message

Bad:
- [ ] API should be fast
- [ ] Handle errors properly
- [ ] Make it work
```

### When to Use

✅ **Use evolving-loop when:**
- Implementing complex features
- Task has multiple interdependent parts
- Previous attempts with auto-loop failed
- Strategy needs to adapt based on results

❌ **Use auto-loop when:**
- Simple, well-defined tasks
- Standard TDD is sufficient
- No learning/adaptation needed

## Troubleshooting

### Session stuck in a phase

```bash
# Check current status
/evolving-status --detailed

# View recent events
/evolving-status --history

# Force restart if needed
/evolving-loop --force "task"
```

### Skills not improving

```bash
# Check evolution history
/evolving-status --evolution

# View learning report
/evolving-status --report learning
```

### Max iterations reached

```bash
# View what was accomplished
/evolving-status --detailed

# Start fresh with higher limit
/evolving-loop --force "task" --max-iterations 100
```

### State file corruption

If checkpoint.json becomes corrupted:

```bash
# Backup current state
cp .self-evolving-loop/state/checkpoint.json checkpoint.backup.json

# Reset to idle state
cat > .self-evolving-loop/state/checkpoint.json << 'EOF'
{
  "version": "1.0.0",
  "request": null,
  "current_phase": null,
  "current_iteration": 0,
  "max_iterations": 50,
  "status": "idle",
  "started_at": null,
  "acceptance_criteria": [],
  "generated_skills": {"executor": null, "validator": null, "fixer": null},
  "skill_versions": {"executor": 0, "validator": 0, "fixer": 0},
  "validation_history": [],
  "evolution_history": [],
  "files_changed": [],
  "last_validation_result": null
}
EOF

# Reset phase and iteration
echo "idle" > .self-evolving-loop/state/phase.txt
echo "0" > .self-evolving-loop/state/iteration.txt
```

### Loop not continuing after phase completion

Check if hooks are properly configured:

```bash
# Verify hook is executable
ls -la .self-evolving-loop/hooks/continue-loop.sh

# Test hook manually
.self-evolving-loop/hooks/continue-loop.sh

# Check for stop signal
ls -la .self-evolving-loop/state/stop  # Should not exist
```

### Manual phase reset

If you need to manually move to a specific phase:

```bash
# Set phase directly
echo "EXECUTE" > .self-evolving-loop/state/phase.txt

# Update checkpoint
jq '.current_phase = "EXECUTE"' .self-evolving-loop/state/checkpoint.json > tmp.json
mv tmp.json .self-evolving-loop/state/checkpoint.json
```

### Complete reset

To completely reset and start fresh:

```bash
# Remove all state
rm -rf .self-evolving-loop/state/*
rm -rf .self-evolving-loop/reports/*
rm -rf .self-evolving-loop/generated-skills/*
rm -rf .self-evolving-loop/history/*

# Recreate initial state
mkdir -p .self-evolving-loop/{state,reports,generated-skills,history}
echo "0" > .self-evolving-loop/state/iteration.txt
echo "idle" > .self-evolving-loop/state/phase.txt
```

## Contributing

Found a bug or want to improve the system?

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## License

MIT License - See LICENSE file for details.
