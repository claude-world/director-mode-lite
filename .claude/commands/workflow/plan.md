---
description: Create detailed execution plan with task breakdown
---

# Task Planning

Create a detailed execution plan for the current task:

## Process

1. **Analyze Requirements**
   - What is the goal?
   - What are the constraints?
   - What resources are available?

2. **Break Down Tasks**
   - Decompose into specific, actionable steps
   - Each task should be completable independently
   - Estimate relative complexity (small/medium/large)

3. **Create Task List**
   - Use TodoWrite tool to track progress
   - Mark priorities and dependencies
   - Keep tasks granular

4. **Identify Risks**
   - What could go wrong?
   - What are the unknowns?
   - What needs clarification?

## Task Template

```markdown
## Task: [Task Name]

### Goal
[What this task achieves]

### Steps
1. [ ] [Step 1]
2. [ ] [Step 2]
3. [ ] [Step 3]

### Dependencies
- Requires: [other tasks]
- Blocks: [dependent tasks]

### Acceptance Criteria
- [ ] [Criterion 1]
- [ ] [Criterion 2]

### Notes
[Any additional context]
```

## Example

```markdown
## Task: Add User Authentication

### Goal
Users can log in with email/password and receive JWT token.

### Steps
1. [ ] Create users table migration
2. [ ] Implement password hashing
3. [ ] Create login endpoint
4. [ ] Add JWT token generation
5. [ ] Write integration tests
6. [ ] Update API documentation

### Dependencies
- Requires: Database setup
- Blocks: Protected routes

### Acceptance Criteria
- [ ] Login returns JWT on valid credentials
- [ ] Returns 401 on invalid credentials
- [ ] Token expires after 24 hours
- [ ] Password is never logged or returned

### Notes
- Use bcrypt for password hashing
- Store JWT secret in environment variable
```

## Guidelines

- Keep tasks small (completable in one session)
- Be specific about acceptance criteria
- Identify dependencies early
- Update plan as you learn more
