---
description: Complete project health audit (7 checks)
---

# Project Health Check

Comprehensive audit to assess project health and identify areas for improvement.

---

## Why Health Checks Matter

```
Regular health checks ensure:
✅ Documentation stays accurate
✅ Tests remain comprehensive
✅ Security vulnerabilities are caught early
✅ Technical debt is managed
✅ Dependencies stay updated
✅ Code quality is maintained
```

---

## 7-Point Audit

### 1. Documentation Audit

**Check:**
- [ ] README is accurate and complete
- [ ] API documentation exists and is current
- [ ] Code comments explain "why" not "what"
- [ ] Architecture decisions are documented

**Actions:**
```bash
# Find markdown files
find . -name "*.md" -type f | head -20

# Check README exists and has content
wc -l README.md

# Look for API docs
ls -la docs/ 2>/dev/null
```

---

### 2. Test Coverage Audit

**Check:**
- [ ] Test coverage > 80% lines
- [ ] Critical paths have tests
- [ ] Edge cases are covered
- [ ] Tests run fast and reliably

**Actions:**
```bash
# Run tests with coverage
npm run test:coverage   # or equivalent

# Check for test files
find . -name "*.test.*" -o -name "*.spec.*" | wc -l
```

---

### 3. Security Audit

**Check:**
- [ ] No secrets in code
- [ ] Dependencies have no known vulnerabilities
- [ ] Input validation exists at boundaries
- [ ] Authentication/authorization is correct

**Actions:**
```bash
# Check for vulnerabilities
npm audit           # Node.js
pip-audit           # Python

# Search for potential secrets
grep -r "password\|secret\|api_key" --include="*.ts" --include="*.js" src/
```

---

### 4. Code Quality Audit

**Check:**
- [ ] Linting passes without errors
- [ ] No large files (> 500 lines)
- [ ] No overly complex functions
- [ ] Consistent naming conventions

**Actions:**
```bash
# Run linter
npm run lint

# Find large files
find src/ -name "*.ts" -exec wc -l {} + | sort -n | tail -10
```

---

### 5. Dependency Audit

**Check:**
- [ ] No outdated major versions
- [ ] No unused dependencies
- [ ] Licenses are compatible
- [ ] No duplicate dependencies

**Actions:**
```bash
# Check outdated packages
npm outdated

# Find unused dependencies
npx depcheck
```

---

### 6. Database Audit

**Check:**
- [ ] Schema documentation exists
- [ ] Migrations are properly versioned
- [ ] Indexes are documented
- [ ] Foreign keys are correct

**Actions:**
```bash
# List migrations
ls migrations/ 2>/dev/null

# Check schema docs
cat docs/database-schema.md 2>/dev/null | head -50
```

---

### 7. Build/Deploy Audit

**Check:**
- [ ] Build succeeds
- [ ] CI/CD pipeline exists
- [ ] Environment variables documented
- [ ] Production configuration is secure

**Actions:**
```bash
# Verify build
npm run build

# Check CI config
ls .github/workflows/ 2>/dev/null
cat .github/workflows/*.yml 2>/dev/null | head -30
```

---

## Health Score Template

```markdown
# Project Health Report - [Date]

## Overall Score: [X]/100

### Breakdown

| Area | Score | Status |
|------|-------|--------|
| Documentation | /15 | ✅/⚠️/❌ |
| Test Coverage | /15 | ✅/⚠️/❌ |
| Security | /20 | ✅/⚠️/❌ |
| Code Quality | /15 | ✅/⚠️/❌ |
| Dependencies | /15 | ✅/⚠️/❌ |
| Database | /10 | ✅/⚠️/❌ |
| Build/Deploy | /10 | ✅/⚠️/❌ |

### Critical Issues (Fix Immediately)
1. [Issue description]

### Warnings (Fix This Week)
1. [Issue description]

### Suggestions (Consider)
1. [Improvement idea]

### Action Plan
- [ ] [Action 1]
- [ ] [Action 2]
```

---

## Recommended Frequency

| Check | Frequency |
|-------|-----------|
| Quick (docs + tests) | Weekly |
| Standard (+ security) | Bi-weekly |
| Full (all 7 areas) | Monthly |

---

## Quick Commands

```bash
# Quick health check
npm audit && npm test && npm run lint

# Full health check
/project-health-check
```
