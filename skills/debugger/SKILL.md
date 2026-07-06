---
name: debugger
description: "Systematic debugging method: 5-step root-cause analysis (capture, isolate, hypothesize, investigate, fix & verify) plus common bug-pattern reference. Use when errors, exceptions, test failures, or unexpected behavior appear. Loaded automatically by the debugger agent."
user-invocable: false
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
  - Edit
---

# Debugger Skill

> **Director Mode Lite** - Debugging Specialist

---

## 5-Step Root-Cause Method

```
1. CAPTURE      → Collect the full error, reproduce, define expected vs actual
2. ISOLATE      → Narrow to the smallest failing case
3. HYPOTHESIZE  → List and rank likely causes
4. INVESTIGATE  → Test hypotheses, inspect state
5. FIX & VERIFY → Apply the minimal fix, confirm, prevent recurrence
```

## Step 1: Capture

- [ ] Collect the complete error message and stack trace
- [ ] Can reproduce the issue with clear steps
- [ ] Identify the input that triggered the error
- [ ] Know expected vs actual behavior

## Step 2: Isolate

- [ ] Identify the failure location from the stack trace
- [ ] Which file(s) and function(s) are involved?
- [ ] When did it start? (`git bisect`, `git log`)
- [ ] Narrow down to the smallest reproducible case

## Step 3: Hypothesize

- [ ] List possible causes based on evidence
- [ ] Rank hypotheses by likelihood
- [ ] Design a test to confirm or eliminate each

## Step 4: Investigate

- Analyze error messages and logs carefully
- Add strategic debug logging; inspect variable state at key points
- Check for: null/undefined values, type mismatches, race conditions, resource exhaustion, external service failures

### Common Bug Patterns

| Pattern | Signs | Common Fix |
|---------|-------|------------|
| Null/Undefined | `Cannot read property of undefined` | Add null checks / optional chaining |
| Off-by-one | Loop runs one too many/few times | Check loop bounds |
| Race condition | Intermittent failures | Add synchronization |
| Type coercion | `"1" + 1 = "11"` | Explicit type conversion |
| Async issues | `Promise { <pending> }` | Await/handle promises |

By language and domain:
- **JavaScript/TypeScript**: `undefined is not a function` (binding), `Cannot read property of null` (optional chaining), promise rejections (async/await handling), type errors (strict mode)
- **Python**: `AttributeError` (init/typos), `TypeError` (type validation), `ImportError` (paths, circular imports), `KeyError` (dict defaults)
- **Database**: connection timeouts (pool exhaustion), constraint violations (validation, foreign keys), deadlocks (transaction ordering)
- **API/Network**: 4xx (request validation, auth), 5xx (server-side, resource limits), timeouts (network, long-running queries)

### Investigation Tools

```bash
# Search for error message
grep -r "error message" src/

# Find recent changes
git log --oneline -20
git diff HEAD~5

# Check specific function
grep -r "functionName" src/
```

## Step 5: Fix & Verify

Apply the solution:
- Make the minimal change; don't refactor while fixing; one fix per commit

Confirm the fix:
- [ ] Original issue is resolved
- [ ] No new issues introduced
- [ ] Tests pass; add a test to prevent recurrence
- [ ] Manual verification done

## Output Format

```markdown
## Debug Report

### Issue
[Description of the bug]

### Reproduction Steps
1. Step one
2. Step two
3. Observe error

### Root Cause
[Explanation of why this happens]

### Location
- **File**: `src/utils/parser.ts`
- **Line**: 45-52
- **Function**: `parseInput()`

### Fix Applied
[Description of the fix]

### Verification
- [x] Issue resolved
- [x] Tests pass
- [x] No regression
```
