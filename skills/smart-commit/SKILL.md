---
name: smart-commit
description: "Create clean Conventional Commits: inspect the diff, group related changes, run quality checks, and write type(scope) messages. Use when committing work, or when the user runs /smart-commit or asks to commit changes."
user-invocable: true
---

# Smart Commit

Create a high-quality commit for current changes.

## Execution

1. Inventory changes: run `git status` and `git diff` (plus `git diff --staged` for already-staged work) to see everything that changed.
2. Group related changes into logical commits — list the files that belong to each group so one commit maps to one concern.
3. Run available quality gates (test suite, linter, formatter) if the project configures them, and fix failures before committing.
4. Stage each group in turn with `git add <files>`.
5. Craft a Conventional Commits message — `type(scope): description`, with a body that explains why the change was made.
6. Commit the staged group.
7. Confirm the result with `git log --oneline -n` (choose `n` to cover the commits you just made).

Repeat steps 4-6 for each group so unrelated changes land in separate commits. The format and type reference below is your guide for steps 5-6.

## Pre-Commit Checklist

### Scope Check
- [ ] Solves one problem only
- [ ] No unrelated changes
- [ ] No debug code
- [ ] No temporary files

### Quality Check
- [ ] All tests pass
- [ ] Code is formatted
- [ ] No linting errors
- [ ] Documentation updated

---

## Commit Message Format

```
<type>(<scope>): <description>

<body>

<footer>
```

### Type (Required)
| Type | Use When |
|------|----------|
| `feat` | New feature (user-visible) |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `test` | Adding/updating tests |
| `refactor` | Code restructure (no behavior change) |
| `style` | Formatting (no logic change) |
| `chore` | Maintenance, dependencies |
| `perf` | Performance improvement |

### Scope (Optional)
Module, component, or file affected:
- `feat(auth): add login endpoint`
- `fix(api): handle null response`
- `docs(readme): update installation steps`

### Description (Required)
- 50 characters or less
- Present tense, imperative mood
- Lowercase first letter
- No period at end
- Describe WHAT, not HOW

---

## Examples

### Feature
```
feat(user): add email verification

Implement email verification flow for new user registration.
Users must verify email before accessing protected features.

Closes #42
```

### Bug Fix
```
fix(api): handle null response in user endpoint

Previously threw uncaught exception when user not found.
Now returns 404 with proper error message.

Fixes #67
```

---

## Commit Checklist

Before committing:
- [ ] Follows Conventional Commits format
- [ ] Subject clearly describes the change
- [ ] One commit = one logical change
- [ ] No sensitive information (.env, credentials)
- [ ] All tests pass
