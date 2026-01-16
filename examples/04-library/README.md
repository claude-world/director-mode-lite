# Example 04: TypeScript Library with Director Mode

Build a publishable npm library using TDD and Director Mode's evolving-loop.

## Scenario

Create a **validation library** that:
- Validates common data types (email, URL, phone)
- Supports custom validation rules
- Provides TypeScript type safety
- Works in both Node.js and browsers

## Quick Start

```bash
# 1. Create project directory
mkdir ts-validator && cd ts-validator

# 2. Install Director Mode Lite
curl -fsSL https://raw.githubusercontent.com/claude-world/director-mode-lite/main/install.sh | bash -s .

# 3. Initialize npm project
npm init -y

# 4. Start Claude and run evolving-loop
claude

/evolving-loop "Create a TypeScript validation library

Acceptance Criteria:
- [ ] isEmail(value) - validates email format
- [ ] isURL(value) - validates URL format
- [ ] isPhone(value, country?) - validates phone numbers
- [ ] createValidator(rules) - custom validator factory
- [ ] TypeScript types with generics
- [ ] Zero dependencies
- [ ] ESM and CJS builds
- [ ] 100% test coverage
- [ ] README with API documentation"
```

## Expected Output

After evolving-loop completes:

```
ts-validator/
├── src/
│   ├── index.ts           # Main exports
│   ├── validators/
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
├── dist/                  # Built output
│   ├── index.js           # CJS
│   ├── index.mjs          # ESM
│   └── index.d.ts         # Types
├── package.json
├── tsconfig.json
└── README.md
```

## Usage

```typescript
import { isEmail, isURL, createValidator } from 'ts-validator';

// Built-in validators
isEmail('user@example.com');  // true
isURL('https://example.com'); // true
isPhone('+1-555-123-4567');   // true

// Custom validator
const isPositive = createValidator({
  validate: (n: number) => n > 0,
  message: 'Must be positive'
});

isPositive(5);   // { valid: true }
isPositive(-1);  // { valid: false, message: 'Must be positive' }
```

## What You'll Learn

1. **Library Architecture** - Structuring a publishable npm package
2. **TypeScript Generics** - Type-safe validation patterns
3. **Dual Package Format** - ESM and CJS support
4. **Evolving-Loop** - Self-improving development strategy

## Why Evolving-Loop?

Unlike auto-loop which uses fixed TDD cycles, evolving-loop:
- **Learns from failures** - Adapts strategy based on what works
- **Generates custom skills** - Creates task-specific helpers
- **Evolves over iterations** - Improves its own approach

This is ideal for library development where:
- API design may need iteration
- Type definitions require careful consideration
- Edge cases emerge during development

## Configuration

The evolving-loop uses these phases:
1. **ANALYZE** - Deep requirement analysis
2. **GENERATE** - Create custom skills for this task
3. **EXECUTE** - Implement with generated skills
4. **VALIDATE** - Check all criteria
5. **DECIDE** - Continue, evolve, or ship
6. **LEARN** - Extract patterns from success/failure
7. **EVOLVE** - Improve skills based on learning
8. **SHIP** - Finalize and clean up

## Tips

- Evolving-loop typically takes 5-8 iterations
- Check `/evolving-status` for progress
- Memory is preserved across iterations
- Generated skills are in `.claude/skills/generated/`

## Common Issues

**Q: Type errors in generated validators**
A: The loop will learn from these and adjust. Let it iterate.

**Q: Build fails for dual format**
A: Check tsconfig.json settings for ESM/CJS output.

**Q: Tests pass but types are wrong**
A: Add more specific type tests with `expectType` patterns.

## Next Steps

- Add more built-in validators
- Add async validation support
- Add validation schemas (like Zod)
- Publish to npm

---

*Part of [Director Mode Lite Examples](../README.md)*
