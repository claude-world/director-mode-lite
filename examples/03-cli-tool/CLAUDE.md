# File Organizer CLI

A command-line tool demonstrating Director Mode's Auto-Loop with TDD.

## Tech Stack

- Runtime: Node.js 18+
- Language: TypeScript
- CLI Framework: commander.js
- Testing: Jest
- Build: tsc

## Project Structure

```
file-organizer/
├── src/
│   ├── index.ts        # CLI entry point
│   ├── scanner.ts      # Directory scanning
│   └── organizer.ts    # File organization logic
├── tests/
│   ├── scanner.test.ts
│   └── organizer.test.ts
└── package.json
```

## Development Policies

- Always write tests before implementation (TDD)
- Use conventional commits
- Handle file system errors gracefully
- Support dry-run mode for safe previews
- Keep it simple (no external dependencies beyond commander.js)

## Commands

```bash
npm install     # Install dependencies
npm test        # Run tests
npm run build   # Compile TypeScript
```
