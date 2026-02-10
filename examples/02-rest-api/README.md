# Example: REST API with TDD Workflow

Build a complete REST API using the 5-step Director Mode workflow.

## What You'll Learn

- How to use `/workflow` for structured development
- How to apply TDD with `/test-first`
- How agents collaborate during development
- Best practices for API development

## Prerequisites

- Claude Code v2.1.9+
- Director Mode Lite installed
- Node.js 18+ (for Express.js)

## The Project

We'll build a simple **Todo API** with:
- `GET /todos` - List all todos
- `POST /todos` - Create a todo
- `GET /todos/:id` - Get a specific todo
- `PUT /todos/:id` - Update a todo
- `DELETE /todos/:id` - Delete a todo

## Setup

```bash
cd examples/02-rest-api
claude
```

## Step 1: Start the Workflow

```
/workflow
```

Claude will guide you through:

### Phase 1: Focus Problem

Claude analyzes what we need:
- Express.js server
- In-memory storage (for simplicity)
- CRUD operations
- Proper error handling
- Input validation

### Phase 2: Prevent Overdev

We'll avoid:
- Database integration (keep it simple)
- Authentication (not in scope)
- Complex validation libraries

### Phase 3: Test First

```
/test-first
```

Claude writes tests BEFORE implementation:

```javascript
// Example test structure
describe('GET /todos', () => {
  it('returns empty array when no todos exist');
  it('returns all todos');
});

describe('POST /todos', () => {
  it('creates a new todo');
  it('returns 400 for invalid input');
});
```

### Phase 4: Implement

With failing tests in place, Claude implements:

```javascript
// todos.js
const express = require('express');
const router = express.Router();

let todos = [];
let nextId = 1;

router.get('/', (req, res) => {
  res.json(todos);
});

router.post('/', (req, res) => {
  const { title } = req.body;
  if (!title) {
    return res.status(400).json({ error: 'Title required' });
  }
  const todo = { id: nextId++, title, completed: false };
  todos.push(todo);
  res.status(201).json(todo);
});

// ... more routes
```

### Phase 5: Document & Commit

Claude auto-generates:
- API documentation
- Code comments
- Conventional commit

## Expected Output

```
02-rest-api/
├── app.js              # Express app
├── routes/
│   └── todos.js        # Todo routes
├── tests/
│   └── todos.test.js   # API tests
├── package.json
├── README.md           # API docs
└── CLAUDE.md
```

## Key Concepts

| Concept | How It's Used |
|---------|---------------|
| `/workflow` | Orchestrates 5 phases |
| `/test-first` | TDD for each endpoint |
| `code-reviewer` | Reviews before commit |
| `doc-writer` | Auto-generates API docs |
| `/smart-commit` | Conventional commits |

## Try It Yourself

After setup:

```bash
# Run tests
npm test

# Start server
npm start

# Test API
curl http://localhost:3000/todos
curl -X POST -H "Content-Type: application/json" \
     -d '{"title":"Learn Director Mode"}' \
     http://localhost:3000/todos
```

## Variations

### Add Validation

```
"Add input validation using Joi

Acceptance Criteria:
- [ ] Validate title length (1-100 chars)
- [ ] Validate completed is boolean
- [ ] Return detailed error messages"
```

### Add Pagination

```
"Add pagination to GET /todos

Acceptance Criteria:
- [ ] Support ?page=1&limit=10
- [ ] Return total count in response
- [ ] Default to 10 items per page"
```

## Next Steps

Try [Example 3: Bug Fix](../03-bug-fix/) for systematic debugging.

---

Questions? Join [Claude World](https://claude-world.com).
