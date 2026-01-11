# Contributing to Director Mode Lite

First off, thank you for considering contributing to Director Mode Lite! 🎉

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Style Guidelines](#style-guidelines)
- [Submitting Changes](#submitting-changes)

## Code of Conduct

This project adheres to a Code of Conduct. By participating, you are expected to uphold this code. Please be respectful and constructive in all interactions.

## How Can I Contribute?

### Reporting Bugs

- Check if the bug has already been reported in [Issues](https://github.com/claude-world/director-mode-lite/issues)
- If not, create a new issue using the Bug Report template
- Include as much detail as possible

### Suggesting Features

- Check existing [feature requests](https://github.com/claude-world/director-mode-lite/issues?q=label%3Aenhancement)
- Create a new issue using the Feature Request template
- Explain the use case and potential implementation

### Contributing Code

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test locally with `./demo.sh`
5. Commit with conventional commits (`feat:`, `fix:`, `docs:`, etc.)
6. Push to your branch
7. Open a Pull Request

## Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/director-mode-lite.git
cd director-mode-lite

# Test installation
./demo.sh ~/test-project

# Make changes and test
./install.sh ~/test-project
```

## Style Guidelines

### Commands (`.md` files)

```markdown
---
description: Short description (required)
---

# Command Name

Clear instructions for Claude...
```

### Agents (`.md` files)

```markdown
---
name: agent-name
description: What this agent does
tools: Read, Grep, Glob, Bash
---

# Agent Name

You are a specialist in...
```

### Skills (`SKILL.md` files)

```markdown
---
description: What this skill does
---

# Skill Name

Instructions...
```

### Shell Scripts

- Use `set -euo pipefail`
- Add comments for complex logic
- Support `--help` flag when appropriate

## Submitting Changes

### Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add new command for X
fix: resolve issue with Y
docs: update README
refactor: improve Z
```

### Pull Request Process

1. Update documentation if needed
2. Test your changes locally
3. Ensure your PR description clearly describes the changes
4. Link related issues

## Questions?

- 💬 [Discord](https://discord.com/invite/rBtHzSD288)
- 🐛 [GitHub Issues](https://github.com/claude-world/director-mode-lite/issues)
- 🌐 [claude-world.com](https://claude-world.com)

---

Thank you for contributing! 🙏
