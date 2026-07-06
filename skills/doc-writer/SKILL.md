---
name: doc-writer
description: "Documentation templates and standards: README structure, API reference format, changelog (Keep a Changelog), and comment guidelines. Use when creating or updating documentation. Loaded automatically by the doc-writer agent."
user-invocable: false
allowed-tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
---

# Doc Writer Skill

> **Director Mode Lite** - Documentation Specialist

---

## Documentation Types

### 1. README.md

Essential sections:
```markdown
# Project Name

Brief description (1-2 sentences)

## Quick Start
\`\`\`bash
npm install   # Installation
npm start     # Run
\`\`\`

## Features
- Feature 1

## Documentation
- [Getting Started](docs/getting-started.md)
- [API Reference](docs/api.md)

## Contributing
See [CONTRIBUTING.md](CONTRIBUTING.md)

## License
MIT
```

### 2. API Documentation

For each endpoint/function:
```markdown
## `functionName(param1, param2)`

Brief description.

**Parameters:**
- `param1` (string): Description
- `param2` (number, optional): Description. Default: `10`

**Returns:**
- `ResultType`: Description

**Example:**
\`\`\`javascript
const result = functionName('hello', 5);
// => { success: true }
\`\`\`

**Throws:**
- `ValidationError`: When param1 is empty
```

For REST endpoints, document the method and path, request headers/body, success and error responses, and a runnable `curl` example.

### 3. Code Comments

Comment complex algorithms, non-obvious business logic, workarounds (and why), and TODOs with context. Do NOT comment self-explanatory code or restate what the code already says.

```javascript
// Calculate compound interest using continuous compounding formula
// This matches the bank's calculation method (see SPEC-123)
const interest = principal * Math.exp(rate * time);
```

### 4. CHANGELOG.md

Follow Keep a Changelog format:
```markdown
# Changelog

## [1.2.0] - 2025-01-15
### Added
- New feature X
### Changed
- Improved performance of Y
### Fixed
- Bug in Z
### Removed
- Deprecated API endpoint
```

### 5. Architecture Docs

Cover the system overview, component relationships, data flow, and design decisions with their rationale.

## Documentation Standards

### Style
- Use active voice; keep sentences concise
- Define acronyms on first use; use consistent terminology
- Write for scanning: H1 for the title, H2/H3 for sections, lists, and bold key terms

### Code Examples
- Make examples complete and runnable; include expected output
- Show both basic and advanced usage; handle errors

### Principles
- **Keep it current**: update docs in the same PR as the code change
- **Write for the reader**: assume minimal context, lead with the common case
- **Test your docs**: follow your own instructions; verify every example runs

## Output Format

```markdown
## Documentation Update

### Files Created/Updated
- `README.md` - Added Quick Start section

### Summary
[What documentation was added/changed and why]
```
