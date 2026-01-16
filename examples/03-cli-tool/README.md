# Example 03: CLI Tool with Director Mode

Build a command-line tool using TDD and Director Mode's auto-loop.

## Scenario

Create a **file organizer CLI** that:
- Scans a directory for files
- Organizes files by extension into subdirectories
- Supports dry-run mode
- Provides verbose output

## Quick Start

```bash
# 1. Create project directory
mkdir file-organizer && cd file-organizer

# 2. Install Director Mode Lite
curl -fsSL https://raw.githubusercontent.com/claude-world/director-mode-lite/main/install.sh | bash -s .

# 3. Initialize npm project
npm init -y

# 4. Start Claude and run auto-loop
claude

/auto-loop "Create a file organizer CLI

Acceptance Criteria:
- [ ] CLI entry point with commander.js
- [ ] scan(dir) function that lists files recursively
- [ ] organize(dir, options) function that moves files by extension
- [ ] --dry-run flag to preview changes
- [ ] --verbose flag for detailed output
- [ ] Unit tests for all functions
- [ ] README with usage examples"
```

## Expected Output

After auto-loop completes, you should have:

```
file-organizer/
├── src/
│   ├── index.ts        # CLI entry point
│   ├── scanner.ts      # Directory scanning
│   └── organizer.ts    # File organization logic
├── tests/
│   ├── scanner.test.ts
│   └── organizer.test.ts
├── package.json
├── tsconfig.json
└── README.md
```

## Usage

```bash
# Install dependencies
npm install

# Run in dry-run mode
npx file-organizer ./downloads --dry-run

# Organize files
npx file-organizer ./downloads --verbose

# Show help
npx file-organizer --help
```

## What You'll Learn

1. **CLI Architecture** - How to structure a Node.js CLI tool
2. **TDD for CLIs** - Testing command-line interfaces
3. **Progressive Implementation** - Building features iteratively
4. **Error Handling** - Graceful error handling for file operations

## Tips

- The auto-loop will likely take 4-6 iterations
- Watch the TDD cycle: RED → GREEN → REFACTOR
- Check `.auto-loop/` for iteration history
- Use `touch .auto-loop/stop` to pause if needed

## Common Issues

**Q: Tests fail with permission errors**
A: Make sure you have write permissions in the test directory.

**Q: TypeScript compilation errors**
A: Run `npm install typescript @types/node --save-dev`

## Next Steps

- Add support for custom organization rules
- Add file type detection beyond extension
- Add undo functionality
- Publish to npm

---

*Part of [Director Mode Lite Examples](../README.md)*
