---
description: Self-Evolving Development Loop - Dynamic skill generation with learning and evolution (Meta-Engineering integrated)
user-invocable: true
---

# Self-Evolving Development Loop

Execute an autonomous development cycle that dynamically generates, validates, and evolves its own execution strategy. Integrates with Meta-Engineering memory system for pattern learning and tool evolution.

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
/evolving-loop --evolve    # Trigger manual evolution learning
/evolving-loop --memory    # Show memory system status
```

---

## Execution

When user runs `/evolving-loop "$ARGUMENTS"`:

### 1. Handle Flags

```bash
STATE_DIR=".self-evolving-loop"
MEMORY_DIR=".claude/memory/meta-engineering"
CHECKPOINT="$STATE_DIR/state/checkpoint.json"

# --status: Show current state
if [[ "$ARGUMENTS" == *"--status"* ]]; then
    /evolving-status
    exit 0
fi

# --memory: Show memory system status
if [[ "$ARGUMENTS" == *"--memory"* ]]; then
    echo "Memory System Status:"
    echo "===================="
    if [ -d "$MEMORY_DIR" ]; then
        echo "Tool Usage: $(jq '.tools | length' "$MEMORY_DIR/tool-usage.json" 2>/dev/null || echo "0") tools tracked"
        echo "Patterns: $(jq '.task_patterns | keys | length' "$MEMORY_DIR/patterns.json" 2>/dev/null || echo "0") task patterns"
        echo "Evolution: v$(jq -r '.version' "$MEMORY_DIR/evolution.json" 2>/dev/null || echo "0")"
    else
        echo "(Not initialized - will create on first run)"
    fi
    exit 0
fi

# --evolve: Manual evolution trigger
if [[ "$ARGUMENTS" == *"--evolve"* ]]; then
    echo "Triggering manual evolution (Phase -1C)..."
    # Delegate to skill-evolver with evolution mode
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

### 2. Initialize Memory System (Phase -1 Prep)

```bash
# Create memory directories if not exist
mkdir -p "$MEMORY_DIR"

# Initialize tool-usage.json
if [ ! -f "$MEMORY_DIR/tool-usage.json" ]; then
    cat > "$MEMORY_DIR/tool-usage.json" << 'EOF'
{
  "tools": [],
  "last_updated": null
}
EOF
fi

# Initialize patterns.json
if [ ! -f "$MEMORY_DIR/patterns.json" ]; then
    cat > "$MEMORY_DIR/patterns.json" << 'EOF'
{
  "task_patterns": {
    "auth": {
      "keywords": ["login", "authentication", "authorize", "JWT", "OAuth", "session"],
      "recommended_agents": ["security-checker"],
      "recommended_skills": ["test-runner"],
      "success_rate": 0.75,
      "sample_count": 0
    },
    "api": {
      "keywords": ["API", "endpoint", "REST", "GraphQL", "route", "controller"],
      "recommended_agents": ["code-reviewer"],
      "recommended_skills": ["test-runner"],
      "success_rate": 0.75,
      "sample_count": 0
    },
    "database": {
      "keywords": ["database", "schema", "migration", "query", "model", "ORM"],
      "recommended_agents": ["code-reviewer"],
      "recommended_skills": ["test-runner"],
      "success_rate": 0.75,
      "sample_count": 0
    },
    "ui": {
      "keywords": ["component", "UI", "form", "button", "layout", "style", "CSS"],
      "recommended_agents": ["code-reviewer"],
      "recommended_skills": ["test-runner"],
      "success_rate": 0.75,
      "sample_count": 0
    }
  },
  "tech_patterns": {},
  "tool_dependencies": {}
}
EOF
fi

# Initialize evolution.json
if [ ! -f "$MEMORY_DIR/evolution.json" ]; then
    cat > "$MEMORY_DIR/evolution.json" << 'EOF'
{
  "version": 1,
  "last_evolution": null,
  "template_improvements": [],
  "learned_rules": [],
  "predicted_tools": [],
  "lifecycle_upgrades": []
}
EOF
fi

# Initialize feedback-history.json
if [ ! -f "$MEMORY_DIR/feedback-history.json" ]; then
    cat > "$MEMORY_DIR/feedback-history.json" << 'EOF'
{
  "feedback": [],
  "last_updated": null
}
EOF
fi
```

### 3. Initialize Session

```bash
mkdir -p "$STATE_DIR"/{state,reports,generated-skills,history}

# Parse request (remove flags)
REQUEST=$(echo "$ARGUMENTS" | sed 's/--[a-z-]*//g' | xargs)

# Detect task type from keywords (for pattern matching)
TASK_TYPE="general"
REQUEST_LOWER=$(echo "$REQUEST" | tr '[:upper:]' '[:lower:]')

# Check patterns for task type
if echo "$REQUEST_LOWER" | grep -qE "login|auth|jwt|oauth|session"; then
    TASK_TYPE="auth"
elif echo "$REQUEST_LOWER" | grep -qE "api|endpoint|rest|route|controller"; then
    TASK_TYPE="api"
elif echo "$REQUEST_LOWER" | grep -qE "database|schema|migration|query|model"; then
    TASK_TYPE="database"
elif echo "$REQUEST_LOWER" | grep -qE "component|ui|form|button|layout|style"; then
    TASK_TYPE="ui"
fi

# Initialize checkpoint with task type for pattern matching
cat > "$CHECKPOINT" << EOF
{
  "version": "2.0.0",
  "request": "$REQUEST",
  "task_type": "$TASK_TYPE",
  "current_phase": "CONTEXT_CHECK",
  "current_iteration": 0,
  "max_iterations": 50,
  "status": "in_progress",
  "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "ac_total": 0,
  "ac_completed": 0,
  "skill_versions": {"executor": 0, "validator": 0, "fixer": 0},
  "skill_lifecycle": {"executor": "task-scoped", "validator": "task-scoped", "fixer": "task-scoped"},
  "last_score": null,
  "pattern_matched": "$TASK_TYPE",
  "tools_used": [],
  "feedback_collected": []
}
EOF
```

### 4. Delegate to Orchestrator (Context Isolation)

**CRITICAL**: Use the orchestrator to manage phases in isolated contexts.

```markdown
Task(subagent_type="general-purpose", prompt="""
You are the Self-Evolving Loop Orchestrator with Meta-Engineering integration.

Request: $ARGUMENTS
Task Type: $TASK_TYPE (from pattern matching)

Read checkpoint from: .self-evolving-loop/state/checkpoint.json
Read memory from: .claude/memory/meta-engineering/

Execute phases in sequence, each in fork context:

## Phase -2: CONTEXT_CHECK (New!)
- Check context pressure (estimate token usage)
- If pressure > 80%: auto-unload idle task-scoped tools
- Log context status

## Phase -1A: PATTERN_LOOKUP (New!)
- Read patterns.json for task_type recommendations
- Pre-select recommended agents/skills
- Check evolution.json for predicted_tools
- Pass recommendations to GENERATE phase

## Phase 1: ANALYZE
- Save to reports/analysis.json

## Phase 2: GENERATE
- Use pattern recommendations from Phase -1A
- Add lifecycle markers (task-scoped) to skills
- Save to generated-skills/

## Phase 3: EXECUTE
- Modify codebase (TDD)
- Track tools_used for dependency graph

## Phase 4: VALIDATE
- Save to reports/validation.json

## Phase 5: DECIDE
- Route: SHIP/FIX/EVOLVE/ABORT

## Phase 6: LEARN (on EVOLVE or SHIP)
- Extract patterns from success/failure
- Update tool_dependencies in patterns.json
- Save to reports/learning.json

## Phase 7: EVOLVE (if decided)
- Apply learning to skills
- Check lifecycle auto-upgrade conditions
- Save evolved skills

## Phase -1C: EVOLUTION (on SHIP)
- Update patterns.json with task outcome
- Record tool_usage statistics
- Check for lifecycle upgrades (task-scoped → persistent)

Loop until SHIP or max iterations

IMPORTANT - Context Management:
- Run each phase agent with fork context
- Store ALL detailed output in files
- Only return brief status updates (1 line per phase)
- Never return full analysis/validation/learning content
- Update memory system after each session

Return format:
📊 CONTEXT: [OK/Warning] - [N]% usage
🔍 PATTERNS: Matched [type], [N] recommendations
✅ ANALYZE: [N] AC identified
✅ GENERATE: Created v[N] skills (lifecycle: task-scoped)
🔄 EXECUTE: Iter [N] - [status]
✅ VALIDATE: Score [N]/100
➡️ DECIDE: [SHIP/FIX/EVOLVE]
📚 LEARN: [N] patterns, [M] suggestions
🧬 EVOLVE: v[N] → v[N+1]
✅ SHIP: Complete! Memory updated.
""")
```

### 5. Output to User

The orchestrator returns only brief summaries:

```
🚀 Starting Self-Evolving Loop (Meta-Engineering v2.0)...

📊 CONTEXT: OK - 15% usage
🔍 PATTERNS: Matched 'auth', 3 recommendations (security-checker, test-runner)
✅ ANALYZE: 5 acceptance criteria identified
✅ GENERATE: Created executor-v1, validator-v1, fixer-v1 (lifecycle: task-scoped)
🔄 EXECUTE: Iteration 1 - 4 files modified, 3/5 tests passing
✅ VALIDATE: Score 72/100
➡️ DECIDE: FIX (minor test failures)
🔄 EXECUTE: Iteration 2 - 2 files modified, 5/5 tests passing
✅ VALIDATE: Score 94/100
➡️ DECIDE: SHIP
📚 LEARN: 2 patterns identified, 1 dependency recorded
🧬 EVOLUTION: Updated patterns.json, tool-usage.json
✅ SHIP: All criteria met! Memory updated.

📊 Summary: 2 iterations, 6 files changed, 5/5 AC complete
💾 Memory: auth pattern success_rate → 0.80, executor usage_count → 1
```

---

## Architecture (Context Isolation + Meta-Engineering)

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
│  - Reads/writes checkpoint.json + memory/*.json             │
│  - Returns summaries only                                   │
└───────────────────────┬─────────────────────────────────────┘
                        │ spawns (each in fork)
    ┌───────────────────┼───────────────────┐
    ▼                   ▼                   ▼
┌─────────┐      ┌─────────────┐      ┌──────────┐
│Phase -2 │      │  Phase -1A  │      │ Phase -1C│
│CONTEXT  │─────►│  PATTERNS   │      │EVOLUTION │
│ CHECK   │      │  LOOKUP     │      │(on SHIP) │
└─────────┘      └──────┬──────┘      └────▲─────┘
                        │                  │
    ┌───────────────────┼──────────────────┘
    │                   ▼
    │    ┌──────────────────────────────────────────┐
    │    │           Main Loop                       │
    │    ├──────────┬──────────┬──────────┬────────┤
    │    ▼          ▼          ▼          ▼        │
    │ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐  │
    │ │ANALYZE │ │GENERATE│ │EXECUTE │ │VALIDATE│  │
    │ │ (fork) │ │ (fork) │ │ (fork) │ │ (fork) │  │
    │ └───┬────┘ └───┬────┘ └───┬────┘ └───┬────┘  │
    │     │          │          │          │       │
    │     ▼          ▼          ▼          ▼       │
    │ analysis   skills/    codebase   validation  │
    │   .json    *.md                    .json     │
    │                                              │
    │    ┌──────────┐  ┌──────────┐  ┌──────────┐  │
    │    │  DECIDE  │──│  LEARN   │──│  EVOLVE  │  │
    │    │  (fork)  │  │  (fork)  │  │  (fork)  │  │
    │    └────┬─────┘  └────┬─────┘  └────┬─────┘  │
    │         │             │             │        │
    │         ▼             ▼             ▼        │
    │    decision      learning      evolved       │
    │      .json         .json       skills        │
    └──────────────────────────────────────────────┘
                        │
                        ▼
              ┌─────────────────┐
              │  Memory System  │
              │  .claude/memory │
              │  /meta-eng/     │
              ├─────────────────┤
              │ tool-usage.json │
              │ patterns.json   │
              │ evolution.json  │
              └─────────────────┘
```

**Context Budget**:
- Main: ~500 tokens (status lines only)
- Orchestrator: ~2000 tokens (coordination)
- Each Phase: Full budget (isolated, disposable)
- Memory: Persistent across sessions

---

## Phase Agents

| Phase | Agent | Output File | Memory Integration |
|-------|-------|-------------|-------------------|
| **-2: CONTEXT_CHECK** | (orchestrator) | `reports/context.json` | Check tool_usage for idle tools |
| **-1A: PATTERN_LOOKUP** | (orchestrator) | `reports/patterns.json` | Read patterns.json, evolution.json |
| **1: ANALYZE** | `requirement-analyzer` | `reports/analysis.json` | - |
| **2: GENERATE** | `skill-synthesizer` | `generated-skills/*.md` | Use pattern recommendations |
| **3: EXECUTE** | (generated executor) | codebase changes | Track tools_used |
| **4: VALIDATE** | (generated validator) | `reports/validation.json` | - |
| **5: DECIDE** | `completion-judge` | `reports/decision.json` | - |
| **6: LEARN** | `experience-extractor` | `reports/learning.json` | Update tool_dependencies |
| **7: EVOLVE** | `skill-evolver` | `generated-skills/*-v[N+1].md` | Check lifecycle upgrade |
| **-1C: EVOLUTION** | `skill-evolver` | (memory files) | Update all memory files |

---

## State Files

```
.self-evolving-loop/                    ← Session state (temporary)
├── state/
│   └── checkpoint.json                 ← Lightweight state (essential only)
├── reports/
│   ├── context.json                    ← Context check result (Phase -2)
│   ├── patterns.json                   ← Pattern lookup result (Phase -1A)
│   ├── analysis.json                   ← Full analysis (not in context)
│   ├── validation.json                 ← Full validation (not in context)
│   ├── decision.json                   ← Decision details
│   └── learning.json                   ← Learning insights
├── generated-skills/                   ← Dynamic skills (not in context)
└── history/
    ├── events.jsonl                    ← Event log
    └── skill-evolution.jsonl           ← Skill version history

.claude/memory/meta-engineering/        ← Persistent memory (cross-session)
├── tool-usage.json                     ← Tool usage statistics
├── patterns.json                       ← Learned task/tech patterns
├── evolution.json                      ← Evolution history & predictions
└── feedback-history.json               ← User feedback collection
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

## Lifecycle Management

Generated skills have lifecycle markers that determine their persistence:

### Lifecycle Types

| Type | Description | Auto-Cleanup |
|------|-------------|--------------|
| `task-scoped` | Default for new skills | Cleaned after session |
| `persistent` | Proven skills (auto-upgraded) | Never cleaned |

### Auto-Upgrade Conditions

A `task-scoped` skill is upgraded to `persistent` when:

```python
if usage_count >= 5 and success_rate >= 0.80:
    lifecycle = "persistent"
```

### Upgrade Flow

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  task-scoped    │────►│  Phase -1C      │────►│  persistent     │
│  (new skill)    │     │  (evaluation)   │     │  (proven skill) │
└─────────────────┘     └─────────────────┘     └─────────────────┘
       │                       │
       │                       ├── usage_count >= 5?
       │                       └── success_rate >= 80%?
       │
       └── Session ends → task-scoped skills cleaned up
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

# Memory status
/evolving-loop --memory

# Pattern statistics
cat .claude/memory/meta-engineering/patterns.json | jq '.task_patterns | to_entries | .[] | {key: .key, success_rate: .value.success_rate}'

# Tool usage
cat .claude/memory/meta-engineering/tool-usage.json | jq '.tools | sort_by(-.usage_count) | .[0:5]'
```

---

## Stop / Resume

```bash
# Stop after current phase
touch .self-evolving-loop/state/stop

# Resume later
/evolving-loop --resume
```
