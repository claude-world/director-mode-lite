# Director Mode Concepts

> Understanding the mindset shift that makes AI-assisted development 10x more effective.

---

## The Core Idea

Most developers use AI coding assistants like a junior programmer:

```
"Write a function that validates email"
"Add error handling to this code"
"Fix this bug"
```

**Director Mode** flips this relationship:

```
"I need user authentication. Analyze the codebase, design the approach,
implement it with tests, and create a PR when ready."
```

You become the **Director** - setting vision, making decisions, reviewing results.
Claude becomes the **Executor** - handling implementation details autonomously.

---

## Key Principles

### 1. Efficiency First

**Traditional:**
```
You: "Should I create a new file?"
AI: "Yes, that would be appropriate."
You: "What should I name it?"
AI: "auth.ts would be good."
You: "Should I add tests?"
AI: "Yes, tests are important."
```

**Director Mode:**
```
You: "Add authentication"
AI: [Creates auth.ts, writes implementation, adds tests, updates docs]
AI: "Done. Created auth.ts with JWT authentication. Tests passing. Ready for review."
```

**Rule:** Local operations are safe (git can recover). Execute directly.

### 2. Parallel Processing

**Traditional (Sequential):**
```
Search for auth files → wait
Read auth config → wait
Check tests → wait
Review docs → wait
Total: 4 × wait time
```

**Director Mode (Parallel):**
```
Agent 1: Search auth files ─┐
Agent 2: Read config       ─┼─→ Aggregate results
Agent 3: Check tests       ─┤
Agent 4: Review docs       ─┘
Total: 1 × wait time
```

Use parallel agents whenever tasks are independent.

### 3. Strategic Oversight

**What you do:**
- Define the goal ("add user login")
- Make architectural decisions ("use JWT, not sessions")
- Review results ("looks good, but add rate limiting")
- Approve commits and PRs

**What Claude does:**
- Explore the codebase
- Design implementation
- Write code and tests
- Update documentation
- Create commits

---

## The 5-Step Workflow

### Step 1: Focus Problem

Before coding, understand:
- What is the actual need?
- What defines success?
- What's out of scope?
- What existing code is relevant?

Use Explore agents to quickly understand the codebase.

### Step 2: Prevent Overdev (YAGNI)

Red flags to avoid:
- "We might need this later" → Don't build it
- "Let's make it generic" → Solve current problem only
- "Just in case" → YAGNI

Build the simplest thing that works.

### Step 3: Test First (TDD)

1. **Red**: Write a failing test
2. **Green**: Write minimal code to pass
3. **Refactor**: Clean up while tests stay green

Tests ensure Claude's implementation actually works.

### Step 4: Document

- Code should be self-explanatory
- Comments explain "why", not "what"
- README stays current

### Step 5: Smart Commit

- One logical change per commit
- Conventional Commits format
- No sensitive data

---

## Director Mode in Practice

### Example: Adding a Feature

**You say:**
```
"Add password reset functionality via email"
```

**Claude does:**
1. Explores codebase for existing auth patterns
2. Designs reset flow (token generation, email, verification)
3. Writes failing tests for each step
4. Implements minimal code to pass tests
5. Updates API documentation
6. Creates commit with proper message

**You review:**
- Does the flow make sense?
- Are there security concerns?
- Is anything missing?

**You approve:**
```
"Looks good. Push it."
```

### Example: Fixing a Bug

**You say:**
```
"Users report login fails intermittently"
```

**Claude does:**
1. Analyzes error logs and stack traces
2. Forms hypotheses about root cause
3. Investigates systematically
4. Identifies race condition in session handling
5. Implements fix with test
6. Documents the issue and solution

**You review:**
- Does the analysis make sense?
- Is the fix correct?
- Will it cause regressions?

---

## Common Mistakes to Avoid

### 1. Micromanaging

**Wrong:**
```
"Create a file called auth.ts"
"Add an import for bcrypt"
"Write a function called hashPassword"
```

**Right:**
```
"Implement password hashing using bcrypt"
```

### 2. Not Reviewing

Director Mode doesn't mean blind trust. Always review:
- Security-sensitive code
- Database changes
- API changes
- Architectural decisions

### 3. Skipping Tests

Tests are your safety net. They verify:
- Claude understood the requirement
- The implementation actually works
- Future changes don't break it

### 4. Ignoring Context

Always provide context:
- Project constraints
- Existing patterns to follow
- Performance requirements
- Security considerations

---

## Getting Started

1. **Set up CLAUDE.md** - Configure Claude's behavior
2. **Use `/workflow`** - Start with the 5-step process
3. **Trust but verify** - Review results, especially at first
4. **Iterate** - Refine your directing style over time

---

## The Payoff

With Director Mode:
- **Faster development** - Parallel execution, less back-and-forth
- **Higher quality** - Consistent testing and documentation
- **Better focus** - You think about "what" and "why", not "how"
- **Scalable** - Same approach works for simple tasks and complex features

---

*"Stop writing code. Start directing its creation."*

Learn more at [claude-world.com](https://claude-world.com)
