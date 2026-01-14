---
description: [Auto-generated] Validator for: {{TASK_NAME}}
context: fork
allowed-tools: [Read, Bash, Grep, Glob]
---

# Validator: {{TASK_NAME}}

> **Version**: v{{VERSION}}
> **Generated**: {{TIMESTAMP}}

## Purpose

Validate the implementation against acceptance criteria and quality standards.

## Validation Dimensions

### 1. Functional Correctness (40%)

Check each acceptance criterion:

{{#each ACCEPTANCE_CRITERIA}}
#### AC-{{id}}: {{description}}

- [ ] Implementation exists
- [ ] Test exists
- [ ] Test passes
- [ ] Edge cases handled

{{/each}}

### 2. Code Quality (25%)

#### Linting
```bash
# Run linter (detect project type)
if [ -f "package.json" ]; then
  npm run lint 2>/dev/null || npx eslint . --ext .ts,.js 2>/dev/null || echo "No JS/TS linter"
elif [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
  ruff check . 2>/dev/null || pylint **/*.py 2>/dev/null || echo "No Python linter"
fi
```

#### Code Smells
- [ ] No duplicate code
- [ ] Functions are focused (< 50 lines)
- [ ] Clear naming conventions
- [ ] Appropriate error handling

### 3. Test Coverage (25%)

```bash
# Check test coverage (detect project type)
if [ -f "package.json" ]; then
  npm test -- --coverage 2>/dev/null || echo "Coverage not configured"
elif [ -f "pyproject.toml" ]; then
  pytest --cov 2>/dev/null || echo "Coverage not configured"
fi
```

#### Coverage Criteria
- [ ] Overall coverage >= 80%
- [ ] All AC have corresponding tests
- [ ] Critical paths have tests

### 4. Security (10%)

{{#if HAS_SECURITY_CRITERIA}}
{{#each SECURITY_CRITERIA}}
- [ ] {{description}}
{{/each}}
{{else}}
- [ ] No hardcoded secrets
- [ ] Input validation at boundaries
- [ ] No obvious vulnerabilities
{{/if}}

## Validation Process

### Step 1: Run Tests
```bash
# Detect and run test framework
if [ -f "package.json" ]; then
  npm test
elif [ -f "pyproject.toml" ]; then
  pytest -v
elif [ -f "go.mod" ]; then
  go test ./...
else
  echo "Unknown project type"
fi
```

### Step 2: Run Linter
```bash
# Run appropriate linter
{{LINT_COMMAND}}
```

### Step 3: Check AC Status
For each AC, verify:
1. Code exists at expected location
2. Test exists at expected location
3. Test passes

### Step 4: Generate Report

## Output Format

Write validation report to `.self-evolving-loop/reports/validation.json`:

```json
{
  "validation_version": "1.0",
  "timestamp": "{{TIMESTAMP}}",
  "task": "{{TASK_NAME}}",
  "passed": true|false,
  "score": 0-100,
  "dimensions": {
    "functional": {
      "score": 0-100,
      "passed": true|false,
      "criteria_status": [
        {"id": "AC-F1", "implemented": true, "tested": true, "passing": true}
      ]
    },
    "quality": {
      "score": 0-100,
      "passed": true|false,
      "lint_errors": 0,
      "code_smells": []
    },
    "tests": {
      "score": 0-100,
      "passed": true|false,
      "coverage": "85%",
      "total": 10,
      "passing": 10,
      "failing": 0
    },
    "security": {
      "score": 0-100,
      "passed": true|false,
      "issues": []
    }
  },
  "failed_criteria": [],
  "suggestions": [],
  "details": "Human-readable summary"
}
```

## Scoring Formula

```
Total Score = (Functional × 0.4) + (Quality × 0.25) + (Tests × 0.25) + (Security × 0.1)

Pass Threshold: 80
```

## Guidelines

- Be objective - use measurable criteria
- Report specific issues with file:line references
- Suggest fixes for identified issues
- Don't pass if critical issues exist
