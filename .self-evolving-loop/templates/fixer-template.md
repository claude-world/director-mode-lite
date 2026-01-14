---
description: [Auto-generated] Fixer for: {{TASK_NAME}}
context: fork
allowed-tools: [Read, Write, Edit, Bash, Grep, Glob]
---

# Fixer: {{TASK_NAME}}

> **Version**: v{{VERSION}}
> **Generated**: {{TIMESTAMP}}

## Purpose

Automatically fix issues identified by the Validator to bring the implementation to passing state.

## Input

Read validation report from `.self-evolving-loop/reports/validation.json`

## Fix Strategies

### 1. Functional Issues

#### Missing Implementation
If code doesn't exist for an AC:
1. Locate the expected file
2. Generate minimal implementation
3. Verify test now passes

#### Failing Tests
If test exists but fails:
1. Read test to understand expectation
2. Read implementation to find mismatch
3. Adjust implementation to match spec
4. Re-run test to verify

### 2. Quality Issues

#### Linting Errors
```bash
# Auto-fix linting (project-specific)
if [ -f "package.json" ]; then
  npx eslint . --fix --ext .ts,.js
  npx prettier --write "**/*.{ts,js,json}"
elif [ -f "pyproject.toml" ]; then
  ruff check . --fix
  black .
fi
```

#### Code Smells
- Long functions → Extract helper functions
- Duplicate code → Create shared utilities
- Poor naming → Rename with descriptive names

### 3. Test Issues

#### Missing Tests
Generate test using pattern:
```typescript
describe('[Feature]', () => {
  it('should [expected behavior]', () => {
    // Arrange
    const input = ...;

    // Act
    const result = feature(input);

    // Assert
    expect(result).toBe(expected);
  });
});
```

#### Low Coverage
1. Identify untested code paths
2. Generate tests for critical paths
3. Focus on edge cases

### 4. Security Issues

#### Hardcoded Secrets
1. Find hardcoded values
2. Move to environment variables
3. Update code to read from env

#### Input Validation
1. Identify unvalidated inputs
2. Add validation at boundaries
3. Add sanitization where needed

## Fix Process

### Step 1: Prioritize Issues

```python
priority_order = [
    'security_critical',  # Fix first - blocks everything
    'test_failing',       # Core functionality broken
    'implementation_missing',  # AC not met
    'lint_errors',        # Quality issues
    'coverage_low',       # Nice to have
]
```

### Step 2: Apply Fixes

For each issue in priority order:
1. Read issue details from validation report
2. Locate affected file(s)
3. Apply appropriate fix strategy
4. Verify fix (run test/lint)
5. Move to next issue

### Step 3: Re-validate

After all fixes applied:
```bash
# Run validation again
# (Will be done by the loop, not this skill)
```

## Fix Templates

### Template: Missing Test
```javascript
// {{TEST_FILE}}
import { {{FUNCTION}} } from '{{IMPL_FILE}}';

describe('{{FEATURE}}', () => {
  describe('{{FUNCTION}}', () => {
    it('should {{EXPECTED_BEHAVIOR}}', () => {
      const result = {{FUNCTION}}({{INPUT}});
      expect(result).{{MATCHER}}({{EXPECTED}});
    });

    it('should handle edge case: {{EDGE_CASE}}', () => {
      const result = {{FUNCTION}}({{EDGE_INPUT}});
      expect(result).{{MATCHER}}({{EDGE_EXPECTED}});
    });
  });
});
```

### Template: Environment Variable
```typescript
// Before
const apiKey = 'sk-hardcoded-key';

// After
const apiKey = process.env.API_KEY;
if (!apiKey) {
  throw new Error('API_KEY environment variable is required');
}
```

## Output

Write fix report to `.self-evolving-loop/reports/fix-result.json`:

```json
{
  "fix_version": "1.0",
  "timestamp": "{{TIMESTAMP}}",
  "issues_found": 5,
  "issues_fixed": 4,
  "issues_remaining": 1,
  "fixes_applied": [
    {
      "issue": "Missing test for AC-F1",
      "action": "Generated test file",
      "file": "tests/feature.test.ts",
      "success": true
    }
  ],
  "remaining_issues": [
    {
      "issue": "Complex refactoring needed",
      "reason": "Requires architectural decision",
      "suggestion": "Manual intervention recommended"
    }
  ]
}
```

## Guidelines

- Fix one issue at a time
- Verify each fix before moving on
- Don't introduce new issues
- If fix fails 3 times, mark as manual-required
- Log all changes for rollback capability
