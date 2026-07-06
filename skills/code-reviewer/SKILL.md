---
name: code-reviewer
description: "Code review knowledge base: quality, security (OWASP Top 10), error-handling, performance, and test-coverage checklists with severity-ranked output format. Use when reviewing code changes, PRs, or before commits. Loaded automatically by the code-reviewer agent."
user-invocable: false
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
---

# Code Reviewer Skill

> **Director Mode Lite** - Code Review Specialist

---

## Review Checklist

Canonical checklist for reviewing code changes. Work through every section.

### 1. Code Quality
- [ ] Clear, descriptive naming for functions and variables
- [ ] Proper function/method length (< 30 lines), focused and single-purpose
- [ ] Single responsibility principle
- [ ] No code duplication (DRY)
- [ ] Code is simple, readable, and self-documenting
- [ ] Comments explain "why", not "what"

### 2. Security (OWASP Top 10)
- [ ] Input validation at system boundaries
- [ ] SQL injection prevention (parameterized queries)
- [ ] XSS prevention
- [ ] Command injection prevention
- [ ] No exposed secrets, API keys, or credentials
- [ ] Authentication/Authorization checks
- [ ] Sensitive data handled securely (no data exposure)

### 3. Error Handling
- [ ] Appropriate error handling for edge cases
- [ ] Meaningful error messages
- [ ] Graceful degradation where appropriate
- [ ] No silent failures

### 4. Performance
- [ ] No N+1 queries; efficient database queries
- [ ] Efficient algorithms
- [ ] Proper caching where beneficial
- [ ] Memory leak prevention
- [ ] No unnecessary loops or computations

### 5. Testing
- [ ] Tests exist for new code
- [ ] Happy path and edge cases covered
- [ ] Test names clearly describe what is being tested

### 6. Documentation
- [ ] Complex logic is commented
- [ ] Public APIs are documented
- [ ] README updated if needed

## Review Process

```
Step 1: Read the code changes
Step 2: Run through the checklist
Step 3: Provide feedback with:
        - Category (Quality/Security/Error Handling/Performance/Testing/Docs)
        - Severity (Critical/Major/Minor/Suggestion)
        - Specific line reference
        - Suggested fix
```

## Output Format

```markdown
## Code Review Summary

### Critical Issues
- [Security] Line 45: SQL injection vulnerability
  - Suggested fix: Use parameterized queries

### Major Issues
- [Quality] Line 78-120: Function too long (42 lines)
  - Suggested fix: Extract into smaller functions

### Minor Issues
- [Docs] Line 10: Missing JSDoc for public function

### Suggestions
- Consider adding input validation at line 23

### Approved
- [ ] Ready to merge (no critical/major issues)
```
