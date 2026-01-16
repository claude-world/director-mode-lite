# Development Patterns - Learned Best Practices

> **Purpose**: Document learned patterns from development experience for consistent implementation.
> **Version**: 1.3.0
> **Last Updated**: 2026-01-16

---

## Table of Contents

1. [Context Isolation Pattern](#1-context-isolation-pattern)
2. [First-Run Error Handling](#2-first-run-error-handling)
3. [Phase Dependency Validation](#3-phase-dependency-validation)
4. [Memory Persistence Pattern](#4-memory-persistence-pattern)
5. [Version Update Checklist](#5-version-update-checklist)
6. [Agent Return Format](#6-agent-return-format)

---

## 1. Context Isolation Pattern

### Problem

Sub-agents return full analysis content to the main context, consuming excessive tokens and triggering context compaction.

### Solution

Agents only return brief summaries (<100 characters). All detailed content goes to output files.

### Implementation

```python
# Agent output pattern
def agent_return_format():
    """
    ALWAYS return only a brief summary.
    NEVER return full analysis details.
    """
    # ✅ GOOD
    return "Analysis complete. 5 AC identified. Complexity: medium"

    # ❌ BAD
    return {
        "acceptance_criteria": [...full list...],
        "complexity_analysis": {...detailed breakdown...},
        "strategy": {...full strategy...}
    }
```

### Agent-Specific Return Formats

| Agent | Return Format Example |
|-------|----------------------|
| `requirement-analyzer` | `"Analysis complete. [N] AC. Complexity: [level]"` |
| `skill-synthesizer` | `"Generated executor-v[N], validator-v[N], fixer-v[N]"` |
| `experience-extractor` | `"Identified [N] patterns, [M] suggestions"` |
| `skill-evolver` | `"Evolved to v[N+1]. Lifecycle: [status]"` |
| `completion-judge` | `"Decision: [SHIP\|FIX\|EVOLVE\|ABORT] - [reason]"` |
| `evolving-orchestrator` | `"Phase [X] complete. Next: [Y]"` |

### Section to Add to Agents

```markdown
## Return Format (CRITICAL for Context Isolation)

**ALWAYS return only a brief summary:**
```
[Decision/Status]: [brief reason] (<100 chars)
```

**NEVER return:**
- Full analysis details
- Complete file contents
- Detailed reasoning paragraphs

All detailed content goes to `[output_file].json`, NOT to the return value.
```

---

## 2. First-Run Error Handling

### Problem

Memory files don't exist on first run, causing crashes when reading.

### Solution

1. Ensure directories exist with `makedirs(exist_ok=True)`
2. Use fallback defaults when reading files

### Implementation

```python
import os
import json

MEMORY_DIR = ".claude/memory/meta-engineering"

def ensure_first_run_safety():
    """
    Handle first-run scenario safely.
    """
    # 1. Ensure directory exists
    os.makedirs(MEMORY_DIR, exist_ok=True)

    # 2. Read with fallback default
    patterns = read_json_safe(f"{MEMORY_DIR}/patterns.json") or {"task_patterns": {}}
    evolution = read_json_safe(f"{MEMORY_DIR}/evolution.json") or {"predicted_tools": []}

    # 3. Detect first run
    is_first_run = not os.path.exists(f"{MEMORY_DIR}/patterns.json")

    return is_first_run

def read_json_safe(filepath, default=None):
    """
    Read JSON with fallback for missing files.
    """
    try:
        with open(filepath, 'r') as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return default
```

### Bash Equivalent

```bash
# Ensure directory exists
mkdir -p "$MEMORY_DIR"

# Read with fallback (jq)
patterns=$(cat "$MEMORY_DIR/patterns.json" 2>/dev/null || echo '{"task_patterns": {}}')
evolution=$(cat "$MEMORY_DIR/evolution.json" 2>/dev/null || echo '{"predicted_tools": []}')

# Check first run
is_first_run=false
if [ ! -f "$MEMORY_DIR/patterns.json" ]; then
    is_first_run=true
fi
```

---

## 3. Phase Dependency Validation

### Problem

Phase -1 assumes Phase -1A output exists. If Phase -1A didn't run (e.g., due to resume), Phase -1 fails.

### Solution

Before each phase, verify its prerequisites exist.

### Implementation

```python
def validate_phase_prerequisites(phase_name):
    """
    Verify required outputs from previous phases exist.
    """
    prerequisites = {
        "PHASE_-1": {
            "required_files": [".auto/pattern-recommendations.json"],
            "fallback_phase": "PHASE_-1A"
        },
        "GENERATE": {
            "required_files": [".self-evolving-loop/reports/analysis.json"],
            "fallback_phase": "ANALYZE"
        },
        "EXECUTE": {
            "required_files": [".self-evolving-loop/generated-skills/executor-v*.md"],
            "fallback_phase": "GENERATE"
        },
        "VALIDATE": {
            "required_files": [],  # EXECUTE modifies codebase, no single file
            "fallback_phase": None
        },
        "DECIDE": {
            "required_files": [".self-evolving-loop/reports/validation.json"],
            "fallback_phase": "VALIDATE"
        }
    }

    config = prerequisites.get(phase_name, {})

    for required_file in config.get("required_files", []):
        if "*" in required_file:
            # Glob pattern
            matches = glob.glob(required_file)
            if not matches:
                fallback = config.get("fallback_phase")
                if fallback:
                    print(f"⚠️ {phase_name} prerequisite missing. Running {fallback}...")
                    run_phase(fallback)
                else:
                    raise ValueError(f"Missing prerequisite: {required_file}")
        else:
            if not os.path.exists(required_file):
                fallback = config.get("fallback_phase")
                if fallback:
                    print(f"⚠️ {phase_name} prerequisite missing. Running {fallback}...")
                    run_phase(fallback)
                else:
                    raise ValueError(f"Missing prerequisite: {required_file}")
```

### Bash Equivalent

```bash
# Phase -1 prerequisite check
validate_phase_prerequisites() {
    local phase="$1"

    case "$phase" in
        "PHASE_-1")
            recommendations_file=".auto/pattern-recommendations.json"
            if [ ! -f "$recommendations_file" ]; then
                echo "⚠️ Phase -1A 未完成，正在執行..."
                run_phase_1a
            fi
            ;;
        "GENERATE")
            if [ ! -f ".self-evolving-loop/reports/analysis.json" ]; then
                echo "⚠️ ANALYZE phase 未完成，正在執行..."
                run_analyze_phase
            fi
            ;;
        "DECIDE")
            if [ ! -f ".self-evolving-loop/reports/validation.json" ]; then
                echo "⚠️ VALIDATE phase 未完成，正在執行..."
                run_validate_phase
            fi
            ;;
    esac
}
```

---

## 4. Memory Persistence Pattern

### Problem

Need to persist learning across sessions without bloating context.

### Solution

Write to memory files on success, read on session start.

### Implementation

```python
MEMORY_DIR = ".claude/memory/meta-engineering"

def persist_success_pattern(task_type, tools_used, success):
    """
    Update memory on successful completion.
    """
    # 1. Update patterns.json - success rate
    patterns = read_json_safe(f"{MEMORY_DIR}/patterns.json") or {"task_patterns": {}}

    if task_type in patterns.get("task_patterns", {}):
        pattern = patterns["task_patterns"][task_type]
        old_count = pattern.get("sample_count", 0)
        old_rate = pattern.get("success_rate", 0.75)

        # Weighted average
        new_rate = (old_rate * old_count + (1 if success else 0)) / (old_count + 1)
        pattern["success_rate"] = round(new_rate, 3)
        pattern["sample_count"] = old_count + 1

    write_json(f"{MEMORY_DIR}/patterns.json", patterns)

def persist_failure_learning(failure_patterns):
    """
    Record learning from failures.
    """
    learning_file = f"{MEMORY_DIR}/learning-history.jsonl"

    with open(learning_file, 'a') as f:
        entry = {
            "timestamp": datetime.now().isoformat(),
            "patterns": failure_patterns,
            "session_id": get_session_id()
        }
        f.write(json.dumps(entry) + "\n")
```

### Trigger Conditions

| Event | Memory Action |
|-------|--------------|
| Success (SHIP) | Write to `patterns.json` (update success_rate) |
| Failure (≥3 consecutive) | Trigger LEARN phase, write to `learning-history.jsonl` |
| Evolution complete | Write to `evolution.json` |
| Session end | Cleanup task-scoped skills (if not upgraded) |

---

## 5. Version Update Checklist

### Files to Update When Releasing

| File | What to Update |
|------|----------------|
| `VERSION` | Version number only |
| `CHANGELOG.md` | Add new version section with changes |
| `CLAUDE.md` (root) | Update version info section |
| `.claude/CLAUDE.md` | Update version info section |
| Related reports/docs | If they reference version |

### Version Format

Follow Semantic Versioning:
- `MAJOR.MINOR.PATCH`
- Example: `1.3.0`

### Changelog Entry Template

```markdown
## [1.3.0] - 2026-01-16

### Added
- Feature A description
- Feature B description

### Changed
- Change A description

### Fixed
- Fix A description

### Deprecated
- Deprecated item (if any)
```

---

## 6. Agent Return Format

### Standard Template for All Self-Evolving Agents

Add this section to all agents that participate in the Self-Evolving Loop:

```markdown
## Return Format (CRITICAL for Context Isolation)

**ALWAYS return only a brief summary:**
```
[Status]: [brief description] (<100 chars)
```

**Examples:**
- ✅ `"Analysis complete. 5 AC. Complexity: medium"`
- ✅ `"Decision: SHIP - all tests pass"`
- ✅ `"Generated 3 skills (lifecycle: task-scoped)"`

**NEVER return:**
- Full analysis reports
- Complete file contents
- Detailed reasoning paragraphs
- Raw JSON structures

All detailed content must be written to the designated output file, NOT returned to the orchestrator.

**Output File**: `[Specify the output file path for this agent]`
```

---

## Summary Table

| Pattern | Problem | Solution |
|---------|---------|----------|
| Context Isolation | Token bloat from agent returns | <100 char returns, details to files |
| First-Run Safety | Missing files crash | `makedirs` + fallback defaults |
| Phase Dependencies | Missing prerequisites | Validate before, run fallback |
| Memory Persistence | Cross-session learning | Write on success/failure events |
| Version Management | Scattered version info | Checklist of files to update |
| Agent Returns | Inconsistent output formats | Standard return format template |

---

## References

- [SELF-EVOLVING-LOOP.md](./SELF-EVOLVING-LOOP.md) - Full technical documentation
- [evolving-orchestrator.md](../.claude/agents/evolving-orchestrator.md) - Orchestrator implementation
- [evolving-loop.md](../.claude/commands/evolving-loop.md) - Command implementation
