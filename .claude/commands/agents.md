---
description: List available agents
---

# Available Agents

Director Mode Lite includes 3 core agents for common development tasks.

## Core Agents

### code-reviewer

**Purpose:** Expert code review for quality, security, and best practices.

**Triggers automatically when:**
- Code has been written or modified
- User mentions "review", "check code"
- Before committing changes

**Capabilities:**
- Code quality assessment
- Security vulnerability detection
- Best practices validation
- Performance review
- Test coverage check

**Usage:**
```
"Review the authentication code"
"Check this PR for issues"
```

---

### debugger

**Purpose:** Systematic debugging for errors and unexpected behavior.

**Triggers automatically when:**
- Error messages appear
- Tests fail unexpectedly
- User mentions "bug", "error", "debug"

**Methodology:**
1. Capture error information
2. Isolate the problem
3. Form hypotheses
4. Investigate systematically
5. Fix and verify

**Usage:**
```
"Debug why login is failing"
"This test keeps timing out"
```

---

### doc-writer

**Purpose:** Documentation creation and maintenance.

**Triggers automatically when:**
- New features are added
- Code structure changes
- User mentions "document", "README"

**Creates:**
- README files
- API documentation
- Code comments
- Architecture docs

**Usage:**
```
"Document the API endpoints"
"Update the README with new features"
```

---

## How Agents Work

Agents are specialized personas that Claude adopts based on the task. They:

1. **Auto-activate** based on context and keywords
2. **Follow specific methodologies** for their domain
3. **Provide structured output** appropriate to the task
4. **Can be explicitly invoked** when needed

## Using Agents

Agents activate automatically, but you can also invoke them:

```
"Use the code-reviewer agent to check src/auth/"
"I need the debugger - tests are failing"
"Have doc-writer update the API documentation"
```

---

## Extending Agents

To add custom agents, create `.md` files in `.claude/agents/`:

```markdown
---
name: my-agent
description: Description of what this agent does
tools: Read, Grep, Glob, Bash
---

# Agent Name

You are a specialist in [domain].

## When to Activate
- Trigger condition 1
- Trigger condition 2

## Process
1. Step 1
2. Step 2

## Output Format
[Describe expected output]
```

---

*Questions or suggestions? Join [Claude World](https://claude-world.com) community.*
