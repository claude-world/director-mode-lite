---
name: focus-problem
description: "Deeply scope a problem before coding: parallel Explore agents map related files, similar implementations, and test patterns, producing a problem definition, boundaries, and minimal implementation plan. Use when planning a feature, investigating a bug, or entering an unfamiliar codebase area."
user-invocable: true
---

# Focus Problem Analysis

Analyze: $ARGUMENTS

## Explore Codebase First

Before diving in, use the Explore agent to understand the context:

Before dispatch, preserve the bounded exploration question and expected result.
If Claude's Agent tool is unavailable or withheld, or Codex's `spawn_agent`
interface is unavailable or withheld, the maximum depth is reached, or a
concurrency limit rejects the call, do not retry or invent exploration
findings. Return an incomplete `dispatch_request` and do not advance the plan.

Choose exactly one provider-native form:

- Claude Code: `Agent(subagent_type="Explore", model="haiku", prompt="<bounded prompt>")`
- Codex CLI: `spawn_agent(agent_type="explorer", task_name="focus_problem", message="<bounded prompt>")`

```markdown
Agent(subagent_type="Explore", model="haiku", prompt="""
Explore the codebase for: $ARGUMENTS (thoroughness: medium)
Focus on:
1. Relevant files and modules
2. Existing similar features
3. Test patterns
4. Architecture patterns
""")
```

In Codex, send the same exploration request through `spawn_agent(...)`; do not
invoke the Claude example as a second dispatch.

## Analysis Framework

### 1. Core Problem Identification
- **What is the real problem?**
- **Why does it need to be solved?**
- **What happens if we don't solve it?**

### 2. Minimal Solution Scope
- **What's the minimum change needed?**
- **Which features are essential?**
- **What can be deferred or omitted?**

### 3. Solution Evaluation
- **Option A (Simplest):**
- **Option B (Balanced):**
- **Option C (Complete):**
- **Recommendation:** Choose the simplest viable option

### 4. Implementation Plan
- **Step 1:** Write tests
- **Step 2:** Minimal implementation
- **Step 3:** Update documentation
- **Step 4:** Commit changes

## Output Template

```markdown
## Problem Definition

### Summary
[One sentence description]

### User Need
[Who needs this? What do they want to achieve?]

### Success Criteria
[How do we know it's done?]

### Scope
- In scope: [List]
- Out of scope: [List]

### Affected Files
- [file1.ts] - [why]
- [file2.ts] - [why]

### Risk Assessment
- [Potential risks and mitigations]
```

---

Follow this process strictly. Don't skip steps.
