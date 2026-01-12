---
description: Validate CLAUDE.md structure and completeness
---

# CLAUDE.md Validator

Validate the project's CLAUDE.md file for completeness and best practices.

## Validation Checklist

Read `CLAUDE.md` (or `CLAUDE.local.md`) and check:

### Required Sections (Must Have)
- [ ] **Project Overview** - Brief description of what the project does
- [ ] **Tech Stack** - Languages, frameworks, tools listed
- [ ] **Commands** - At least dev, test, build commands documented

### Recommended Sections (Should Have)
- [ ] **Conventions** - Coding standards, naming patterns
- [ ] **Key Files** - Important files and their purposes
- [ ] **Architecture** - Directory structure or design patterns

### Quality Checks
- [ ] **No secrets** - No API keys, passwords, tokens in file
- [ ] **Correct commands** - Listed commands actually work
- [ ] **Up to date** - Tech stack matches actual dependencies

## Output Format

```markdown
## CLAUDE.md Validation Report

### Status: ✅ PASS / ⚠️ NEEDS IMPROVEMENT / ❌ MISSING

### Required Sections
| Section | Status | Notes |
|---------|--------|-------|
| Project Overview | ✅/❌ | [details] |
| Tech Stack | ✅/❌ | [details] |
| Commands | ✅/❌ | [details] |

### Recommended Sections
| Section | Status | Notes |
|---------|--------|-------|
| Conventions | ✅/⚠️/❌ | [details] |
| Key Files | ✅/⚠️/❌ | [details] |
| Architecture | ✅/⚠️/❌ | [details] |

### Issues Found
1. [Issue description and how to fix]

### Suggestions
1. [Improvement suggestion]
```

## Auto-Fix Option

If issues found, offer to fix:
- Add missing sections with placeholders
- Update tech stack from package.json/requirements.txt
- Verify and correct commands

## Reference

For best practices, read `.claude/agents/claude-md-expert.md`
