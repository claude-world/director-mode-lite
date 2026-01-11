---
description: Verify development environment is ready
---

# Environment Check

> **Director Mode Lite** - Verify your development environment

---

## Overview

This command checks if your environment is ready for Director Mode development.

## Checks Performed

### 1. Essential Tools

Check for these required tools:

| Tool | Purpose | Check Command |
|------|---------|---------------|
| git | Version control | `git --version` |
| node | JavaScript runtime | `node --version` |
| npm/pnpm/yarn | Package manager | `npm --version` |

### 2. Claude Code Version

Verify Claude Code is up to date:
```bash
claude --version
```

Minimum recommended: **2.0.0+**

### 3. Project Structure

Check for proper project setup:
- [ ] `package.json` or equivalent exists
- [ ] `.gitignore` exists
- [ ] Source directory exists (`src/`, `lib/`, etc.)

### 4. Git Status

Check repository status:
- [ ] Inside a git repository
- [ ] No uncommitted changes (clean working tree)
- [ ] On a feature branch (not main/master)

## Output Format

```markdown
## Environment Check Results

### Essential Tools
- [x] git: 2.39.0
- [x] node: 20.10.0
- [x] pnpm: 8.12.0

### Claude Code
- [x] Version: 2.1.3 (up to date)

### Project Structure
- [x] package.json found
- [x] .gitignore found
- [x] src/ directory found

### Git Status
- [x] Git repository initialized
- [ ] Warning: 3 uncommitted changes
- [x] On branch: feature/new-feature

### Summary
**Status**: Ready (with warnings)

**Warnings**:
- Uncommitted changes detected. Consider committing or stashing before major work.

**Recommendations**:
- Run `git status` to review changes
- Run `/project-init` if CLAUDE.md doesn't exist
```

## Follow-up Actions

Based on check results:

| Issue | Recommended Action |
|-------|-------------------|
| Missing git | Install git |
| Missing node | Install Node.js LTS |
| No package.json | Run `npm init` or equivalent |
| Uncommitted changes | Commit or stash changes |
| Old Claude Code | Update Claude Code |
