---
description: Quick project setup with CLAUDE.md
---

# Project Initialization

> **Director Mode Lite** - Quick project setup for Director Mode workflow

---

## Overview

This command helps you set up a new project with Director Mode Lite basics.

## Setup Steps

### Step 1: Detect Project Type

First, analyze the project to detect:
- Programming language (check file extensions, package files)
- Framework (check config files, dependencies)
- Package manager (npm, pnpm, yarn, pip, cargo, etc.)

### Step 2: Create CLAUDE.md

Create a `CLAUDE.md` file in the project root with this template:

```markdown
# [Project Name] - Project Instructions

> **Purpose**: [Brief description of the project]
> **Tech Stack**: [Detected tech stack]

---

## Project Structure

\`\`\`
[Auto-generated project structure]
\`\`\`

---

## Development Commands

\`\`\`bash
# Install dependencies
[detected package manager install command]

# Run development server
[detected dev command]

# Run tests
[detected test command]

# Build
[detected build command]
\`\`\`

---

## Coding Standards

- Follow existing code style
- Write tests for new features
- Keep functions focused and small
- Use meaningful variable names

---

## Key Files

| File | Purpose |
|------|---------|
| [main entry] | Application entry point |
| [config file] | Configuration |
| [test dir] | Test files |

---

## Notes

[Add project-specific notes here]
```

### Step 3: Verify Setup

After creating CLAUDE.md:
1. Read the file to confirm it was created
2. Suggest any additional customizations
3. Remind about Director Mode workflow commands

## Output

```markdown
## Project Initialized

**Project**: [name]
**Type**: [language/framework]
**Package Manager**: [detected]

### Created Files
- `CLAUDE.md` - Project instructions

### Next Steps
1. Review and customize `CLAUDE.md`
2. Run `/workflow` to start development
3. Use `/focus-problem` for bug fixes
4. Use `/test-first` for TDD workflow

### Available Commands
- `/workflow` - 5-step development workflow
- `/focus-problem` - Problem analysis
- `/test-first` - TDD Red-Green-Refactor
- `/smart-commit` - Conventional commits
- `/plan` - Task breakdown
- `/project-health-check` - 7-point audit
```

## Notes

- This is a basic setup. Customize `CLAUDE.md` for your specific needs.
- For questions or suggestions, join [Claude World](https://claude-world.com).
