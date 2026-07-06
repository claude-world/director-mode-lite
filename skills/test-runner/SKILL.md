---
name: test-runner
description: "Test execution reference: framework detection (pytest/jest/vitest/go/cargo/junit) and correct run/coverage commands, plus failure-analysis steps. Use when running tests, analyzing test failures, or verifying coverage after code changes."
user-invocable: false
allowed-tools:
  - Read
  - Bash
  - Grep
  - Glob
---

# Test Runner Skill

> **Director Mode Lite** - Test Execution Reference

---

## Supported Frameworks

Detect the project's test framework, then use its runner:

| Language | Frameworks |
|----------|------------|
| JavaScript/TypeScript | Jest, Vitest, Mocha, Playwright |
| Python | pytest, unittest |
| Go | go test |
| Rust | cargo test |
| Java | JUnit, Maven, Gradle |

## Test Workflow

### Step 1: Detect Framework

Check for configuration files:
- `jest.config.*` → Jest
- `vitest.config.*` → Vitest
- `pytest.ini` or `pyproject.toml` → pytest
- `go.mod` → go test
- `Cargo.toml` → cargo test

### Step 2: Run Tests

Run tests with the detected framework's command:

```bash
# JavaScript/TypeScript
npm test        # or pnpm test / yarn test

# Python
pytest -v

# Go
go test ./...

# Rust
cargo test
```

For coverage, add the framework's coverage flag (for example `pytest --cov`, `jest --coverage`, `go test -cover ./...`, `cargo tarpaulin`).

### Step 3: Analyze Results

For each failure, capture:
1. **Test name** and file location
2. **Expected** vs **Actual** result
3. **Root cause** analysis
4. **Suggested fix**

## Output Format

```markdown
## Test Results

**Status**: 2 failed, 18 passed (90% pass rate)

### Failed Tests

#### 1. `user.test.ts` - should validate email format
- **Location**: `src/tests/user.test.ts:45`
- **Expected**: `false` for invalid email
- **Actual**: `true`
- **Root Cause**: Regex pattern missing check for domain
- **Fix**: Update regex in `validateEmail()` function

#### 2. `api.test.ts` - should return 401 for unauthorized
- **Location**: `src/tests/api.test.ts:78`
- **Expected**: Status 401
- **Actual**: Status 500
- **Root Cause**: Auth middleware throwing unhandled error
- **Fix**: Add try-catch in auth middleware

### Coverage Summary
- Statements: 85%
- Branches: 72%
- Functions: 90%
- Lines: 84%
```

## TDD Support

When working with the `/test-first` command:

1. **Red**: Write a failing test first
2. **Green**: Implement the minimum code to pass
3. **Refactor**: Improve without changing behavior

```
Cycle: Write Test → Run (Fail) → Implement → Run (Pass) → Refactor → Run (Pass)
```
