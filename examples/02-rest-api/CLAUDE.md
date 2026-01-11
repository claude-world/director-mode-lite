# Todo API Project

A REST API demonstrating Director Mode's 5-step workflow.

## Tech Stack

- Runtime: Node.js 18+
- Framework: Express.js
- Testing: Jest + Supertest
- Storage: In-memory (array)

## Project Structure

```
02-rest-api/
├── app.js              # Express app setup
├── routes/
│   └── todos.js        # Todo CRUD routes
├── tests/
│   └── todos.test.js   # API integration tests
└── package.json
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /todos | List all todos |
| POST | /todos | Create a todo |
| GET | /todos/:id | Get a todo |
| PUT | /todos/:id | Update a todo |
| DELETE | /todos/:id | Delete a todo |

## Development Policies

- Always write tests before implementation (TDD)
- Use conventional commits
- Handle errors gracefully
- Validate input
- Keep it simple (no database, no auth)

## Commands

```bash
npm install     # Install dependencies
npm test        # Run tests
npm start       # Start server on port 3000
```

## Response Format

```json
// Success
{
  "id": 1,
  "title": "Learn Director Mode",
  "completed": false
}

// Error
{
  "error": "Title required"
}
```
