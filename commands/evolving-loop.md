---
description: Self-Evolving Development Loop - Dynamic skill generation with learning and evolution
user-invocable: true
---

# Self-Evolving Development Loop

Execute an autonomous development cycle that dynamically generates, validates, and evolves its own execution strategy.

## Usage

```bash
/evolving-loop "Your task description

Acceptance Criteria:
- [ ] Criterion 1
- [ ] Criterion 2
"

/evolving-loop --resume    # Resume interrupted session
/evolving-loop --status    # Check status
/evolving-loop --force     # Clear and restart
```

---

## Execution

When user runs `/evolving-loop "$ARGUMENTS"`:

### 1. Handle Flags

```bash
STATE_DIR=".self-evolving-loop"
CHECKPOINT="$STATE_DIR/state/checkpoint.json"

# --status: Show current state
if [[ "$ARGUMENTS" == *"--status"* ]]; then
    /evolving-status
    exit 0
fi

# --resume: Continue from checkpoint
if [[ "$ARGUMENTS" == *"--resume"* ]]; then
    if [ ! -f "$CHECKPOINT" ] || [ "$(jq -r '.status' "$CHECKPOINT")" == "idle" ]; then
        echo "No active session to resume."
        exit 1
    fi
fi

# --force: Clear old state
if [[ "$ARGUMENTS" == *"--force"* ]]; then
    rm -rf "$STATE_DIR/state/*" "$STATE_DIR/reports/*" "$STATE_DIR/generated-skills/*"
fi
```

### 2. Initialize Session

```bash
mkdir -p "$STATE_DIR"/{state,reports,generated-skills,history}

# Parse request (remove flags)
REQUEST=$(echo "$ARGUMENTS" | sed 's/--[a-z-]*//g' | xargs)

# Initialize checkpoint
cat > "$CHECKPOINT" << EOF
{
  "version": "1.0.0",
  "request": "$REQUEST",
  "current_phase": "ANALYZE",
  "current_iteration": 0,
  "max_iterations": 50,
  "status": "in_progress",
  "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "ac_total": 0,
  "ac_completed": 0,
  "skill_versions": {"executor": 0, "validator": 0, "fixer": 0},
  "last_score": null
}
EOF
```

### 3. Delegate to Orchestrator (Context Isolation)

**CRITICAL**: Use the orchestrator to manage phases in isolated contexts.

```markdown
Task(subagent_type="evolving-orchestrator", prompt="""
Manage the Self-Evolving Loop for this request:

Request: $ARGUMENTS

Read checkpoint from: .self-evolving-loop/state/checkpoint.json

Execute phases in sequence, each in fork context:
1. ANALYZE → Save to reports/analysis.json
2. GENERATE → Save to generated-skills/
3. EXECUTE → Modify codebase (TDD)
4. VALIDATE → Save to reports/validation.json
5. DECIDE → Route: SHIP/FIX/EVOLVE
6. Loop until SHIP or max iterations

IMPORTANT - Context Management:
- Run each phase agent with fork context
- Store ALL detailed output in files
- Only return brief status updates (1 line per phase)
- Never return full analysis/validation/learning content

Return format:
✅ ANALYZE: [N] AC identified
✅ GENERATE: Created v[N] skills
🔄 EXECUTE: Iter [N] - [status]
...
✅ SHIP: Complete!
""")
```

### 4. Output to User

The orchestrator returns only brief summaries:

```
🚀 Starting Self-Evolving Loop...

✅ ANALYZE: 5 acceptance criteria identified
✅ GENERATE: Created executor-v1, validator-v1, fixer-v1
🔄 EXECUTE: Iteration 1 - 4 files modified, 3/5 tests passing
✅ VALIDATE: Score 72/100
➡️ DECIDE: FIX (minor test failures)
🔄 EXECUTE: Iteration 2 - 2 files modified, 5/5 tests passing
✅ VALIDATE: Score 94/100
➡️ DECIDE: SHIP
✅ SHIP: All criteria met! Committed.

📊 Summary: 2 iterations, 6 files changed, 5/5 AC complete
```

---

## Architecture (Context Isolation)

```
┌─────────────────────────────────────────────────────────────┐
│  Main Context (User Conversation)                           │
│  - Receives only: brief status lines                        │
│  - Never sees: full reports, skill content, details         │
└───────────────────────┬─────────────────────────────────────┘
                        │ delegates to
                        ▼
┌─────────────────────────────────────────────────────────────┐
│  Orchestrator (fork context)                                │
│  - Coordinates phases                                       │
│  - Reads/writes checkpoint.json                             │
│  - Returns summaries only                                   │
└───────────────────────┬─────────────────────────────────────┘
                        │ spawns (each in fork)
          ┌─────────────┼─────────────┬─────────────┐
          ▼             ▼             ▼             ▼
    ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
    │ ANALYZE  │  │ GENERATE │  │ EXECUTE  │  │ VALIDATE │
    │  (fork)  │  │  (fork)  │  │  (fork)  │  │  (fork)  │
    └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘
         │             │             │             │
         ▼             ▼             ▼             ▼
    analysis.json  skills/*.md   codebase    validation.json
```

**Context Budget**:
- Main: ~500 tokens (status lines only)
- Orchestrator: ~2000 tokens (coordination)
- Each Phase: Full budget (isolated, disposable)

---

## Phase Agents

| Phase | Agent | Output File |
|-------|-------|-------------|
| ANALYZE | `requirement-analyzer` | `reports/analysis.json` |
| GENERATE | `skill-synthesizer` | `generated-skills/*.md` |
| EXECUTE | (generated executor) | codebase changes |
| VALIDATE | (generated validator) | `reports/validation.json` |
| DECIDE | `completion-judge` | `reports/decision.json` |
| LEARN | `experience-extractor` | `reports/learning.json` |
| EVOLVE | `skill-evolver` | `generated-skills/*-v[N+1].md` |

---

## State Files

```
.self-evolving-loop/
├── state/
│   └── checkpoint.json    ← Lightweight state (essential only)
├── reports/
│   ├── analysis.json      ← Full analysis (not in context)
│   ├── validation.json    ← Full validation (not in context)
│   ├── decision.json      ← Decision details
│   └── learning.json      ← Learning insights
├── generated-skills/      ← Dynamic skills (not in context)
└── history/
    └── events.jsonl       ← Event log
```

---

## Key Design: Context Efficiency

### ❌ Old Pattern (Context Bloat)
```
User → "analyze this" → ANALYZE returns 2000 tokens
User → "generate skills" → GENERATE returns 3000 tokens
User → "execute" → EXECUTE returns 5000 tokens
...
Total: 15000+ tokens in main context → COMPACT triggered
```

### ✅ New Pattern (Context Isolation)
```
User → /evolving-loop "task"
     → Orchestrator (fork) handles everything
     → Returns: "✅ Complete! 3 iterations, 8 files"

Total: ~200 tokens in main context → No compact needed
```

---

## Observability

All details are persisted to files, viewable via:

```bash
# Quick status
/evolving-status

# Full analysis
cat .self-evolving-loop/reports/analysis.json | jq

# Validation details
cat .self-evolving-loop/reports/validation.json | jq

# Event history
tail -20 .self-evolving-loop/history/events.jsonl | jq
```

---

## Stop / Resume

```bash
# Stop after current phase
touch .self-evolving-loop/state/stop

# Resume later
/evolving-loop --resume
```
