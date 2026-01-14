---
description: [Auto-generated] Executor for: {{TASK_NAME}}
context: fork
allowed-tools: [Read, Write, Edit, Bash, Grep, Glob]
---

# Executor: {{TASK_NAME}}

> **Version**: v{{VERSION}}
> **Generated**: {{TIMESTAMP}}
> **Based on**: Analysis v{{ANALYSIS_VERSION}}

## Context

{{PARSED_GOAL}}

### Background
{{CODEBASE_CONTEXT}}

## Acceptance Criteria

{{#each ACCEPTANCE_CRITERIA}}
- [ ] {{id}}: {{description}} ({{priority}})
{{/each}}

## Implementation Strategy

**Approach**: {{STRATEGY_APPROACH}}

### Execution Order
{{#each STRATEGY_ORDER}}
{{@index}}. {{this}}
{{/each}}

### Risk Mitigations
{{#each RISKS}}
- **{{risk}}**: {{mitigation}}
{{/each}}

## Implementation Steps

### Step 1: Setup & Preparation
1. Verify project structure exists
2. Check for required dependencies
3. Create necessary directories/files

### Step 2: Core Implementation
{{#each ACCEPTANCE_CRITERIA}}
#### AC-{{id}}: {{description}}

**Approach**:
1. Write failing test for this criterion
2. Implement minimal code to pass
3. Refactor if needed

**Test Location**: `{{suggested_test_path}}`
**Implementation Location**: `{{suggested_impl_path}}`

{{/each}}

### Step 3: Integration
1. Ensure all components work together
2. Run full test suite
3. Check for regressions

### Step 4: Cleanup
1. Remove debug code
2. Format code
3. Update documentation if needed

## Constraints

{{#each CONSTRAINTS}}
- {{this}}
{{/each}}

## Success Criteria

All acceptance criteria must be:
1. Implemented with working code
2. Covered by passing tests
3. Free of linter errors

## Output

After execution, update:
- Checkpoint status
- Files changed list
- Test results
