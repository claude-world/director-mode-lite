# TypeScript Validation Library

A publishable npm library demonstrating Director Mode's Self-Evolving Loop.

## Tech Stack

- Language: TypeScript (strict mode)
- Testing: Jest with ts-jest
- Build: tsc (dual ESM + CJS output)
- Zero runtime dependencies

## Project Structure

```
ts-validator/
├── src/
│   ├── index.ts           # Main exports
│   ├── validators/        # Built-in validators
│   │   ├── email.ts
│   │   ├── url.ts
│   │   └── phone.ts
│   ├── factory.ts         # Custom validator factory
│   └── types.ts           # TypeScript definitions
├── tests/
│   ├── email.test.ts
│   ├── url.test.ts
│   ├── phone.test.ts
│   └── factory.test.ts
├── dist/                  # Built output (ESM + CJS + types)
└── package.json
```

## Development Policies

- Type-first design: define types before implementation
- TDD: write tests before code
- Zero dependencies: no runtime dependencies
- Dual format: support both ESM and CJS consumers
- 100% test coverage target
- Use conventional commits

## Commands

```bash
npm install     # Install dependencies
npm test        # Run tests
npm run build   # Build ESM + CJS + types
```
