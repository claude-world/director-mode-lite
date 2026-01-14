# Self-Evolving Development Loop

## Technical Documentation v2.0

> A meta-automation system that dynamically generates, validates, and evolves its own execution strategy through continuous learning and adaptation.

---

## Table of Contents

1. [Introduction](#introduction)
2. [Theoretical Foundation](#theoretical-foundation)
3. [Architecture Overview](#architecture-overview)
4. [Phase Details](#phase-details)
5. [Memory System](#memory-system)
6. [Safety Architecture](#safety-architecture)
7. [Context Management](#context-management)
8. [Implementation Details](#implementation-details)
9. [Usage Guide](#usage-guide)
10. [Troubleshooting](#troubleshooting)
11. [Academic References](#academic-references)

---

## Introduction

### What is the Self-Evolving Loop?

The Self-Evolving Development Loop is a **meta-cognitive automation system** that goes beyond traditional development automation. While conventional tools like CI/CD pipelines follow fixed, predetermined steps, the Self-Evolving Loop:

1. **Dynamically generates** task-specific tools (skills) based on requirement analysis
2. **Learns from failures** by extracting patterns and root causes
3. **Evolves its strategy** by improving generated tools based on learned insights
4. **Manages context efficiently** through isolation and persistence mechanisms

### Key Differentiators

| Aspect | Traditional Automation | Self-Evolving Loop |
|--------|----------------------|-------------------|
| Strategy | Fixed steps | Dynamic generation |
| Tools | Pre-defined | Generated per task |
| Failure Handling | Retry/abort | Learn and evolve |
| Memory | Stateless | Cross-session learning |
| Adaptation | None | Continuous improvement |

### Design Philosophy

The system embodies three core principles:

1. **Meta-Engineering**: Generate tools to generate tools
2. **Learning by Doing**: Extract patterns from execution outcomes
3. **Context Efficiency**: Minimize token consumption while maximizing capability

---

## Theoretical Foundation

### 1. Meta-Cognitive Architecture

The Self-Evolving Loop implements a **meta-cognitive architecture** inspired by human problem-solving:

```
+---------------------------------------------------------------------+
|                     Meta-Cognitive Layers                            |
+---------------------------------------------------------------------+
|  Layer 3: Meta-Learning                                              |
|  +-- Pattern recognition across sessions                             |
|  +-- Strategy optimization                                           |
|  +-- Tool evolution decisions                                        |
+---------------------------------------------------------------------+
|  Layer 2: Planning & Control                                         |
|  +-- Phase orchestration                                             |
|  +-- Decision making (SHIP/FIX/EVOLVE/ABORT)                        |
|  +-- Resource allocation                                             |
+---------------------------------------------------------------------+
|  Layer 1: Execution                                                  |
|  +-- TDD implementation (Red-Green-Refactor)                        |
|  +-- Code generation                                                 |
|  +-- Validation                                                      |
+---------------------------------------------------------------------+
```

### 2. Reinforcement Learning Principles

The evolution mechanism follows reinforcement learning concepts:

- **State**: Current checkpoint, generated skills, codebase state
- **Action**: SHIP, FIX, EVOLVE, or ABORT decisions
- **Reward**: Validation score, acceptance criteria completion
- **Policy**: Decision rules refined through experience

```
R(state, action) = w1 * functional_correctness +
                   w2 * code_quality +
                   w3 * test_coverage +
                   w4 * security_score

Where: w1=0.4, w2=0.25, w3=0.25, w4=0.1
```

### 3. Genetic Algorithm Inspiration

Skill evolution follows genetic algorithm principles:

1. **Selection**: Choose skills with highest success rates
2. **Mutation**: Apply learning insights to modify skills
3. **Crossover**: Combine successful patterns across skills
4. **Fitness Function**: Validation score + execution efficiency

### 4. Knowledge Graph Memory

The memory system implements a simplified knowledge graph:

```
Entities:
+-- Tasks (with type classification)
+-- Tools (agents, skills)
+-- Patterns (success/failure patterns)
+-- Outcomes (execution results)

Relations:
+-- task HAS_TYPE pattern
+-- tool USED_FOR task
+-- pattern CORRELATES_WITH outcome
+-- tool CO_OCCURS_WITH tool
```

---

## Architecture Overview

### System Architecture

```
+-----------------------------------------------------------------------------+
|                         SELF-EVOLVING LOOP v2.0                              |
+-----------------------------------------------------------------------------+
|                                                                              |
|  +-------------------+                                                       |
|  |   User Request    |                                                       |
|  |  "/evolving-loop" |                                                       |
|  +---------+---------+                                                       |
|            |                                                                 |
|            v                                                                 |
|  +-----------------------------------------------------------------------+   |
|  |                    ORCHESTRATOR (Fork Context)                         |   |
|  |  +---------------------------------------------------------------+    |   |
|  |  | Pre-Phases                                                     |    |   |
|  |  | +--------------+  +--------------+  +--------------+          |    |   |
|  |  | |Phase -2      |  |Phase -1A     |  |Phase -1C     |          |    |   |
|  |  | |CONTEXT CHECK |->|PATTERN LOOKUP|  |EVOLUTION     |          |    |   |
|  |  | |(pressure)    |  |(memory read) |  |(on SHIP)     |          |    |   |
|  |  | +--------------+  +--------------+  +--------------+          |    |   |
|  |  +---------------------------------------------------------------+    |   |
|  |                                                                        |   |
|  |  +---------------------------------------------------------------+    |   |
|  |  | Main Loop (each phase in fork context)                         |    |   |
|  |  |                                                                 |    |   |
|  |  |  +--------+   +--------+   +--------+   +--------+             |    |   |
|  |  |  |ANALYZE |-->|GENERATE|-->|EXECUTE |-->|VALIDATE|             |    |   |
|  |  |  |Phase 1 |   |Phase 2 |   |Phase 3 |   |Phase 4 |             |    |   |
|  |  |  +--------+   +--------+   +--------+   +---+----+             |    |   |
|  |  |       ^                                     |                  |    |   |
|  |  |       |       +--------+   +--------+   +--v-----+             |    |   |
|  |  |       |       |EVOLVE  |<--|LEARN   |<--|DECIDE  |             |    |   |
|  |  |       +-------|Phase 7 |   |Phase 6 |   |Phase 5 |             |    |   |
|  |  |               +--------+   +--------+   +--------+             |    |   |
|  |  |                                              |                 |    |   |
|  |  |                                    SHIP -----+--> Phase 8      |    |   |
|  |  +---------------------------------------------------------------+    |   |
|  +-----------------------------------------------------------------------+   |
|                                                                              |
|  +-----------------------------------------------------------------------+   |
|  |                       PERSISTENCE LAYER                                |   |
|  |  +-------------------+        +-------------------+                    |   |
|  |  | Session State      |        | Persistent Memory  |                    |   |
|  |  | .self-evolving-   |        | .claude/memory/    |                    |   |
|  |  |  loop/            |        |  meta-engineering/ |                    |   |
|  |  | +-- state/        |        | +-- patterns.json  |                    |   |
|  |  | +-- reports/      |        | +-- tool-usage.json|                    |   |
|  |  | +-- generated-    |        | +-- evolution.json |                    |   |
|  |  | |   skills/       |        | +-- feedback.json  |                    |   |
|  |  | +-- history/      |        |                    |                    |   |
|  |  +-------------------+        +-------------------+                    |   |
|  +-----------------------------------------------------------------------+   |
+-----------------------------------------------------------------------------+
```

### Context Flow

```
Main Context (User Conversation)
     |
     | delegates (returns only summaries)
     v
Orchestrator Context (Fork)
     |
     | spawns (each disposable)
     +-------------------------------------+
     v                                     v
Phase Contexts (Fork)              Memory System (Persistent)
+-- ANALYZE -> analysis.json       +-- patterns.json
+-- GENERATE -> skills/*.md        +-- tool-usage.json
+-- EXECUTE -> codebase            +-- evolution.json
+-- VALIDATE -> validation.json    +-- feedback.json
+-- DECIDE -> decision.json
+-- LEARN -> learning.json
+-- EVOLVE -> evolved skills
```

### Data Flow

```
Request -> ANALYZE -> Analysis Report
                          |
              GENERATE -> Executor, Validator, Fixer Skills
                          |
              EXECUTE -> Code Changes + Test Results
                          |
              VALIDATE -> Validation Score (0-100)
                          |
                DECIDE -> Decision: SHIP | FIX | EVOLVE | ABORT
                          |
         +----------------+----------------+
         v                v                v
       SHIP           FIX/EVOLVE       ABORT
    (complete)          |              (stop)
                      LEARN
                        |
                      EVOLVE
                        |
                   (loop back)
```

---

## Phase Details

### Pre-Phase -2: CONTEXT_CHECK

**Purpose**: Monitor context pressure and prevent token overflow.

**Implementation**:
```python
def context_check():
    tool_usage = read_json("patterns.json")

    # Estimate pressure based on active tools
    pressure = len(active_tools) * 0.05

    # Auto-unload idle task-scoped tools (>30 min idle)
    if pressure > 0.8:
        for tool in idle_tools:
            if tool.lifecycle == "task-scoped":
                unload(tool)

    return {"pressure": pressure, "recommendation": "ok" if pressure < 0.8 else "unload"}
```

### Pre-Phase -1A: PATTERN_LOOKUP

**Purpose**: Load historical patterns to guide skill generation.

**Implementation**:
```python
def pattern_lookup(task_type):
    patterns = read_json("patterns.json")
    evolution = read_json("evolution.json")

    # Get recommendations from learned patterns
    recommendations = {
        "agents": patterns[task_type].recommended_agents,
        "skills": patterns[task_type].recommended_skills,
        "predicted_tools": evolution.predicted_tools,
        "template_improvements": evolution.template_improvements
    }

    return recommendations
```

### Phase 1: ANALYZE

**Agent**: `requirement-analyzer`

**Purpose**: Deep analysis of user requirements to produce actionable execution plan.

**Outputs**:
```json
{
  "parsed_goal": "Implement user authentication system",
  "acceptance_criteria": [
    {"id": 1, "description": "Login endpoint", "priority": "P0"},
    {"id": 2, "description": "JWT generation", "priority": "P0"},
    {"id": 3, "description": "Token validation", "priority": "P1"}
  ],
  "complexity": 7,
  "estimated_iterations": 5,
  "codebase_context": {
    "tech_stack": ["Node.js", "Express"],
    "existing_patterns": ["REST API", "MongoDB"],
    "relevant_files": ["src/routes/", "src/middleware/"]
  },
  "strategy": {
    "approach": "incremental TDD",
    "order": ["auth routes", "JWT service", "middleware"],
    "risks": [{"risk": "Token expiry", "mitigation": "Add refresh flow"}]
  }
}
```

### Phase 2: GENERATE

**Agent**: `skill-synthesizer`

**Purpose**: Generate task-specific skills based on analysis.

**Generated Skills**:

1. **Executor Skill**: Implementation guide with TDD steps
2. **Validator Skill**: Quality checks and scoring rubric
3. **Fixer Skill**: Auto-correction rules and patterns

**Skill Lifecycle**:
```yaml
---
name: executor-v1
description: Auto-generated executor for authentication task
lifecycle: task-scoped  # or persistent
context: fork
allowed-tools: [Read, Write, Edit, Bash, Grep, Glob]
---
```

### Phase 3: EXECUTE

**Purpose**: Implement the task following TDD methodology.

**TDD Cycle**:
```
+---------------------------------------------+
|                TDD Iteration                 |
+---------------------------------------------+
|  RED    | Write failing test                |
|         | -> assert login() returns token   |
+---------+-----------------------------------+
|  GREEN  | Write minimal passing code        |
|         | -> implement basic login()        |
+---------+-----------------------------------+
| REFACTOR| Improve without behavior change   |
|         | -> extract JWT service            |
+---------+-----------------------------------+
```

**Tool Usage Tracking**:
- Records which agents/skills are invoked
- Builds dependency graph for pattern learning
- Enables future optimization

### Phase 4: VALIDATE

**Purpose**: Assess implementation quality using scoring rubric.

**Scoring Rubric**:
```
Total Score =
    Functional Correctness (40%)
  + Code Quality (25%)
  + Test Coverage (25%)
  + Security (10%)

Score Ranges:
  90-100: SHIP (excellent)
  70-89:  FIX (minor issues)
  50-69:  EVOLVE (needs improvement)
  <50:    ABORT (fundamental issues)
```

### Phase 5: DECIDE

**Agent**: `completion-judge`

**Purpose**: Determine next action based on validation results.

**Decision Tree**:
```
IF all AC complete AND score >= 90:
    -> SHIP
ELIF score >= 70:
    -> FIX (apply fixer, retry)
ELIF score >= 50 AND iterations < max:
    -> EVOLVE (learn, improve skills)
ELSE:
    -> ABORT
```

### Phase 6: LEARN

**Agent**: `experience-extractor`

**Purpose**: Extract patterns and insights from execution outcomes.

**Learning Outputs**:
```json
{
  "failure_patterns": [
    {
      "pattern": "Missing error handling",
      "occurrences": 3,
      "root_cause": "Executor template lacks error handling section",
      "suggestion": "Add explicit error handling step to executor"
    }
  ],
  "tool_dependencies": {
    "test-runner+code-reviewer": {
      "co_usage_count": 5,
      "correlation": "strong"
    }
  },
  "skill_improvements": [
    {
      "skill": "executor",
      "section": "Implementation Steps",
      "change": "Add error handling after each AC implementation"
    }
  ]
}
```

### Phase 7: EVOLVE

**Agent**: `skill-evolver`

**Purpose**: Apply learning insights to improve skills.

**Evolution Process**:
1. Read learning.json for improvement suggestions
2. Apply modifications to skill templates
3. Generate new skill versions (v1 -> v2)
4. Check lifecycle upgrade conditions

**Lifecycle Upgrade**:
```python
# Upgrade from task-scoped to persistent
if usage_count >= 5 and success_rate >= 0.80:
    skill.lifecycle = "persistent"
    record_upgrade(skill, evolution.json)
```

### Post-Phase -1C: EVOLUTION (On SHIP)

**Purpose**: Update memory system with session outcomes.

**Updates**:
1. **patterns.json**: Update task pattern success rates
2. **tool-usage.json**: Record tool usage statistics
3. **evolution.json**: Increment version, record learnings

---

## Memory System

### Memory Architecture

```
.claude/memory/meta-engineering/
+-- patterns.json       # Task patterns and recommendations
+-- tool-usage.json     # Tool usage statistics
+-- evolution.json      # Evolution history and predictions
+-- feedback.json       # User feedback collection
```

### patterns.json Structure

```json
{
  "task_patterns": {
    "auth": {
      "keywords": ["login", "authentication", "JWT", "OAuth"],
      "recommended_agents": ["security-checker"],
      "recommended_skills": ["test-runner"],
      "success_rate": 0.82,
      "sample_count": 12
    },
    "api": {
      "keywords": ["API", "endpoint", "REST", "route"],
      "recommended_agents": ["code-reviewer"],
      "recommended_skills": ["test-runner"],
      "success_rate": 0.78,
      "sample_count": 8
    }
  },
  "tool_dependencies": {
    "test-runner+code-reviewer": {
      "tools": ["test-runner", "code-reviewer"],
      "co_usage_count": 15,
      "first_seen": "2024-01-01T00:00:00Z",
      "last_seen": "2024-01-15T12:00:00Z"
    }
  }
}
```

### tool-usage.json Structure

```json
{
  "tools": [
    {
      "name": "test-runner",
      "lifecycle": "persistent",
      "usage_count": 25,
      "success_count": 22,
      "success_rate": 0.88,
      "last_used": "2024-01-15T12:00:00Z"
    }
  ],
  "last_updated": "2024-01-15T12:00:00Z"
}
```

### evolution.json Structure

```json
{
  "version": 5,
  "last_evolution": "2024-01-15T12:00:00Z",
  "template_improvements": [
    {
      "template": "executor",
      "improvement": "Add error handling section",
      "applied_version": 3
    }
  ],
  "learned_rules": [
    {
      "condition": "task_type == 'auth'",
      "action": "Include security validation step",
      "confidence": 0.85
    }
  ],
  "lifecycle_upgrades": [
    {
      "skill": "test-runner",
      "from": "task-scoped",
      "to": "persistent",
      "timestamp": "2024-01-10T00:00:00Z"
    }
  ]
}
```

---

## Safety Architecture

### 1. Pre-Execution Review Gate

Before any execution phase, mandatory validation:

```bash
# Checks performed:
1. Analysis file exists and is valid JSON
2. Generated skills have required frontmatter
3. No dangerous command patterns (rm -rf /, sudo, eval)
4. Acceptance criteria count > 0
```

### 2. Post-Execution Verification

After execution, verify real work was done:

```bash
# Verification checks:
1. Test output file exists and has content
2. Test output contains pass/fail indicators
3. Git diff shows actual changes
4. Output hash recorded for integrity
```

### 3. Checkpoint Validation

Before phase transitions:

```bash
# Required fields checked:
- version
- current_phase
- current_iteration
- status
- max_iterations

# Bounds checked:
- iteration <= max_iterations
```

### 4. Rollback Mechanism

```
Before risky operations:
1. Backup checkpoint.json
2. Archive generated skills
3. Create git stash

On failure:
1. Restore checkpoint
2. Restore skills
3. Pop git stash
```

### 5. Rate Limiting

```
Protections:
- Minimum 30 seconds between cycles
- Maximum 20 cycles per hour
- Context size guards (10KB checkpoint limit)
```

---

## Context Management

### The Context Problem

Traditional approach leads to context bloat:

```
User -> "analyze" -> 2000 tokens returned
User -> "generate" -> 3000 tokens returned
User -> "execute" -> 5000 tokens returned
...
Total: 15000+ tokens -> COMPACT triggered -> Information lost
```

### The Solution: Context Isolation

```
User -> /evolving-loop "task"
     -> Orchestrator (fork) handles everything
     -> Returns: "Complete! 3 iterations, 8 files"

Total: ~200 tokens -> No compact needed
```

### Context Budget Allocation

| Component | Token Budget | Purpose |
|-----------|-------------|---------|
| Main Context | ~500 | Status lines only |
| Orchestrator | ~2000 | Coordination |
| Each Phase | Full | Isolated, disposable |
| Memory Files | Unlimited | Persisted to disk |

### Output Trimming Rules

```python
MAX_PHASE_OUTPUT_CHARS = 500
MAX_CONTEXT_ITEMS = 10

# Never return to main context:
- Full analysis reports
- Complete skill content
- Detailed validation results
- Raw memory file contents

# Always return:
- Single-line status updates
- Counts and scores only
- Decision outcomes
```

---

## Implementation Details

### State Files

```
.self-evolving-loop/
+-- state/
|   +-- checkpoint.json      # Main state (essential only)
|   +-- stop                  # Stop signal file
|   +-- last_cycle.txt        # Rate limiting
+-- reports/
|   +-- context.json          # Context check result
|   +-- patterns.json         # Pattern lookup result
|   +-- analysis.json         # Full analysis
|   +-- validation.json       # Full validation
|   +-- decision.json         # Decision details
|   +-- learning.json         # Learning insights
|   +-- pre-execute-review.json
|   +-- post-execute-verify.json
+-- generated-skills/
|   +-- executor-v1.md
|   +-- validator-v1.md
|   +-- fixer-v1.md
+-- history/
|   +-- events.jsonl
|   +-- skill-evolution.jsonl
+-- backups/
|   +-- backup-iter-N-TIMESTAMP/
+-- templates/
    +-- executor-template.md
    +-- validator-template.md
    +-- fixer-template.md
```

### Checkpoint Schema

```json
{
  "version": "2.0.0",
  "request": "Implement user authentication",
  "task_type": "auth",
  "pattern_matched": "auth",
  "current_phase": "EXECUTE",
  "current_iteration": 2,
  "max_iterations": 50,
  "status": "in_progress",
  "started_at": "2024-01-15T10:00:00Z",
  "ac_total": 5,
  "ac_completed": 3,
  "skill_versions": {
    "executor": 1,
    "validator": 1,
    "fixer": 1
  },
  "skill_lifecycle": {
    "executor": "task-scoped",
    "validator": "task-scoped",
    "fixer": "task-scoped"
  },
  "last_score": 85,
  "tools_used": ["code-reviewer", "test-runner"],
  "feedback_collected": []
}
```

### Event Log Format

```json
{"timestamp": "2024-01-15T10:00:00Z", "type": "phase_start", "phase": "ANALYZE", "iteration": 1}
{"timestamp": "2024-01-15T10:01:00Z", "type": "phase_complete", "phase": "ANALYZE", "duration": 60}
{"timestamp": "2024-01-15T10:01:05Z", "type": "skill_generated", "skill": "executor", "version": 1}
{"timestamp": "2024-01-15T10:05:00Z", "type": "validation", "score": 72, "ac_complete": 3}
{"timestamp": "2024-01-15T10:05:10Z", "type": "decision", "action": "FIX", "reason": "Minor issues"}
```

---

## Usage Guide

### Basic Usage

```bash
# Start new session
/evolving-loop "Implement user authentication

Acceptance Criteria:
- [ ] Login endpoint with email/password
- [ ] JWT token generation
- [ ] Token validation middleware
- [ ] Error handling
"

# Check status
/evolving-status

# Resume interrupted session
/evolving-loop --resume

# Force restart
/evolving-loop --force "New task"

# Check memory system
/evolving-loop --memory

# Trigger manual evolution
/evolving-loop --evolve
```

### Writing Good Acceptance Criteria

**Good Examples**:
```markdown
- [ ] GET /users returns JSON array with id, name, email fields
- [ ] POST /users with valid data returns 201 and created user
- [ ] POST /users with invalid email returns 400 with error message
- [ ] Authentication middleware rejects requests without valid JWT
```

**Bad Examples**:
```markdown
- [ ] API should be fast (not measurable)
- [ ] Handle errors (too vague)
- [ ] Make it work (not specific)
```

### When to Use

| Scenario | Use evolving-loop | Use auto-loop |
|----------|------------------|---------------|
| Complex features | Yes | No |
| Multiple interdependent parts | Yes | No |
| Previous attempts failed | Yes | No |
| Simple, well-defined tasks | No | Yes |
| Standard TDD sufficient | No | Yes |

---

## Troubleshooting

### Common Issues

#### Session Stuck

```bash
# Check status
/evolving-status --detailed

# View recent events
tail -20 .self-evolving-loop/history/events.jsonl | jq

# Force restart if needed
/evolving-loop --force "task"
```

#### Skills Not Improving

```bash
# Check evolution history
cat .self-evolving-loop/history/skill-evolution.jsonl | jq

# View learning report
cat .self-evolving-loop/reports/learning.json | jq
```

#### Max Iterations Reached

```bash
# View accomplishments
/evolving-status --detailed

# Start fresh with higher limit
/evolving-loop --force "task" --max-iterations 100
```

#### State File Corruption

```bash
# Reset checkpoint
cat > .self-evolving-loop/state/checkpoint.json << 'EOF'
{
  "version": "2.0.0",
  "request": null,
  "current_phase": null,
  "current_iteration": 0,
  "max_iterations": 50,
  "status": "idle"
}
EOF
```

### Complete Reset

```bash
# Remove all state
rm -rf .self-evolving-loop/state/*
rm -rf .self-evolving-loop/reports/*
rm -rf .self-evolving-loop/generated-skills/*
rm -rf .self-evolving-loop/history/*

# Keep templates and hooks
# Recreate directories
mkdir -p .self-evolving-loop/{state,reports,generated-skills,history}
```

---

## Academic References

### Related Research Areas

1. **Meta-Learning**: "Learning to Learn" - systems that improve learning algorithms
2. **Genetic Programming**: Automated program synthesis through evolution
3. **Reinforcement Learning**: Decision making through reward optimization
4. **Knowledge Graphs**: Structured representation of domain knowledge
5. **Autonomic Computing**: Self-managing computer systems

### Conceptual Foundations

- **Reflection**: System's ability to reason about its own behavior
- **Adaptation**: Modifying behavior based on environmental feedback
- **Emergence**: Complex behaviors arising from simple rules
- **Homeostasis**: Maintaining stability through self-regulation

### Design Pattern Influences

- **Strategy Pattern**: Dynamic algorithm selection
- **Observer Pattern**: Phase completion notifications
- **State Pattern**: Phase-based behavior changes
- **Template Method**: Customizable execution framework

---

## Conclusion

The Self-Evolving Development Loop represents a significant advancement in AI-assisted development automation. By combining:

- **Dynamic skill generation** tailored to specific tasks
- **Continuous learning** from execution outcomes
- **Efficient context management** through isolation
- **Robust safety mechanisms** for reliable operation

The system achieves autonomous, adaptive, and efficient software development that improves with each iteration.

---

## See Also

- [DIRECTOR-MODE-CONCEPTS.md](DIRECTOR-MODE-CONCEPTS.md) - Core methodology
- [CLAUDE-TEMPLATE.md](CLAUDE-TEMPLATE.md) - Project configuration
- [FAQ.md](FAQ.md) - Common questions

---

*Documentation version: 2.0.0*
*Last updated: 2026-01-14*
*Part of [Director Mode Lite](https://github.com/claude-world/director-mode-lite)*
