# Self-Evolving Loop - Architecture Details

> **Main Skill**: [.claude/skills/evolving-loop/SKILL.md](../.claude/skills/evolving-loop/SKILL.md)
> **Version**: 2.0.0 (Meta-Engineering integrated)

This document contains detailed architecture information for the Self-Evolving Development Loop.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Memory System Initialization](#memory-system-initialization)
3. [Phase Dependency Validation](#phase-dependency-validation)
4. [Context Isolation Design](#context-isolation-design)
5. [Lifecycle Management](#lifecycle-management)
6. [Observability](#observability)

---

## Architecture Overview

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

### Context Budget

| Context | Token Budget | Purpose |
|---------|--------------|---------|
| Main | ~500 tokens | Status lines only |
| Orchestrator | ~2000 tokens | Coordination |
| Each Phase | Full budget | Isolated, disposable |
| Memory | Persistent | Cross-session learning |

---

## Memory System Initialization

### Full Memory File Schemas

#### tool-usage.json

```json
{
  "tools": [],
  "last_updated": null
}
```

#### patterns.json

```json
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
```

#### evolution.json

```json
{
  "version": 1,
  "last_evolution": null,
  "template_improvements": [],
  "learned_rules": [],
  "predicted_tools": [],
  "lifecycle_upgrades": []
}
```

#### feedback-history.json

```json
{
  "feedback": [],
  "last_updated": null
}
```

### Task Type Detection

```bash
TASK_TYPE="general"
REQUEST_LOWER=$(echo "$REQUEST" | tr '[:upper:]' '[:lower:]')

if echo "$REQUEST_LOWER" | grep -qE "login|auth|jwt|oauth|session"; then
    TASK_TYPE="auth"
elif echo "$REQUEST_LOWER" | grep -qE "api|endpoint|rest|route|controller"; then
    TASK_TYPE="api"
elif echo "$REQUEST_LOWER" | grep -qE "database|schema|migration|query|model"; then
    TASK_TYPE="database"
elif echo "$REQUEST_LOWER" | grep -qE "component|ui|form|button|layout|style"; then
    TASK_TYPE="ui"
fi
```

### Checkpoint Schema

```json
{
  "version": "2.0.0",
  "request": "User's original request",
  "task_type": "auth",
  "current_phase": "EXECUTE",
  "current_iteration": 2,
  "max_iterations": 50,
  "status": "in_progress",
  "started_at": "2026-01-16T10:00:00Z",
  "ac_total": 5,
  "ac_completed": 3,
  "skill_versions": {"executor": 1, "validator": 1, "fixer": 1},
  "skill_lifecycle": {"executor": "task-scoped", "validator": "task-scoped", "fixer": "task-scoped"},
  "last_score": 85,
  "pattern_matched": "auth",
  "tools_used": ["code-reviewer", "test-runner"],
  "feedback_collected": []
}
```

---

## Phase Dependency Validation

**CRITICAL**: Before executing any phase, verify its prerequisites exist.

```bash
validate_phase_prerequisites() {
    local phase="$1"
    local missing_prereq=false

    case "$phase" in
        "GENERATE")
            if [ ! -f "$STATE_DIR/reports/analysis.json" ]; then
                echo "⚠️ ANALYZE phase output missing. Running ANALYZE first..."
                missing_prereq=true
            fi
            ;;
        "EXECUTE")
            if ! ls "$STATE_DIR/generated-skills"/executor-v*.md 1> /dev/null 2>&1; then
                echo "⚠️ GENERATE phase output missing. Running GENERATE first..."
                missing_prereq=true
            fi
            ;;
        "DECIDE")
            if [ ! -f "$STATE_DIR/reports/validation.json" ]; then
                echo "⚠️ VALIDATE phase output missing. Running VALIDATE first..."
                missing_prereq=true
            fi
            ;;
        "LEARN")
            if [ ! -f "$STATE_DIR/reports/decision.json" ]; then
                echo "⚠️ DECIDE phase output missing. Running DECIDE first..."
                missing_prereq=true
            fi
            ;;
        "EVOLVE")
            if [ ! -f "$STATE_DIR/reports/learning.json" ]; then
                echo "⚠️ LEARN phase output missing. Running LEARN first..."
                missing_prereq=true
            fi
            ;;
    esac

    if [ "$missing_prereq" = true ]; then
        return 1
    fi
    return 0
}

validate_checkpoint() {
    if [ ! -f "$CHECKPOINT" ]; then
        echo "❌ Checkpoint missing. Cannot resume."
        return 1
    fi

    local version=$(jq -r '.version // "missing"' "$CHECKPOINT")
    local status=$(jq -r '.status // "missing"' "$CHECKPOINT")

    if [ "$version" = "missing" ] || [ "$status" = "missing" ]; then
        echo "❌ Checkpoint corrupted. Missing required fields."
        return 1
    fi

    return 0
}
```

---

## Context Isolation Design

### Problem: Context Bloat

```
❌ Old Pattern:
User → "analyze this" → ANALYZE returns 2000 tokens
User → "generate skills" → GENERATE returns 3000 tokens
User → "execute" → EXECUTE returns 5000 tokens
...
Total: 15000+ tokens in main context → COMPACT triggered
```

### Solution: Fork Context

```
✅ New Pattern:
User → /evolving-loop "task"
     → Orchestrator (fork) handles everything
     → Returns: "✅ Complete! 3 iterations, 8 files"

Total: ~200 tokens in main context → No compact needed
```

### Agent Return Format (CRITICAL)

All Self-Evolving agents must return <100 character summaries:

| Agent | Return Format |
|-------|--------------|
| `requirement-analyzer` | `"Analysis complete. 5 AC. Complexity: medium"` |
| `skill-synthesizer` | `"Generated executor-v1, validator-v1, fixer-v1"` |
| `completion-judge` | `"Decision: SHIP - all tests pass"` |
| `experience-extractor` | `"Identified 3 patterns, 2 suggestions"` |
| `skill-evolver` | `"Evolved to v2. Lifecycle: unchanged"` |

---

## Lifecycle Management

### Lifecycle Types

| Type | Description | Auto-Cleanup |
|------|-------------|--------------|
| `task-scoped` | Default for new skills | Cleaned after session |
| `persistent` | Proven skills (auto-upgraded) | Never cleaned |

### Auto-Upgrade Conditions

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

### Query Commands

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

# Tool usage (top 5)
cat .claude/memory/meta-engineering/tool-usage.json | jq '.tools | sort_by(-.usage_count) | .[0:5]'
```

### State Files

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

## Related Documentation

- [DEVELOPMENT-PATTERNS.md](./DEVELOPMENT-PATTERNS.md) - Learned best practices
- [SELF-EVOLVING-LOOP.md](./SELF-EVOLVING-LOOP.md) - Conceptual overview
- [evolving-orchestrator agent](../.claude/agents/evolving-orchestrator.md) - Orchestrator details
