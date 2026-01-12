---
description: Expert-guided project setup with 6 phases
---

# Project Initialization

Execute a comprehensive project setup. Each phase uses specialized knowledge from Expert Agents.

---

## Phase 1: Project Analysis

Analyze the project:

1. **Check existing setup**: `ls -la .claude/ 2>/dev/null`
2. **Detect language**:
   - `package.json` → Node.js/TypeScript
   - `requirements.txt` / `pyproject.toml` → Python
   - `Cargo.toml` → Rust
   - `go.mod` → Go
3. **Detect framework**: Check dependencies in config files
4. **Map structure**: `find . -type f -name "*.ts" -o -name "*.py" | head -20`

**Output**: Brief analysis report before proceeding.

---

## Phase 2: CLAUDE.md Setup

**Read the expert knowledge first**:
```
Read .claude/agents/claude-md-expert.md to understand best practices
```

**Then create CLAUDE.md** following the expert's template:

```markdown
# [Project Name] - Project Instructions

## Overview
[Detected purpose from package.json description or README]

## Tech Stack
- Language: [detected]
- Framework: [detected]
- Package Manager: [detected]

## Commands
\`\`\`bash
[detected dev command]
[detected test command]
[detected build command]
\`\`\`

## Conventions
- [Infer from existing code patterns]
- [Check for .eslintrc, .prettierrc, etc.]

## Key Files
| File | Purpose |
|------|---------|
| [entry point] | Main entry |
| [config] | Configuration |
```

---

## Phase 3: MCP Configuration

**Read the expert knowledge first**:
```
Read .claude/agents/mcp-expert.md to understand MCP setup
```

**Essential MCP setup**:

1. **Memory MCP** (always add):
```bash
claude mcp add --scope project memory -e MEMORY_FILE_PATH=./.claude/memory.json -- npx -y @modelcontextprotocol/server-memory
```

2. **GitHub MCP** (if .git exists and user has token):
```bash
# Ask user: "Do you want to add GitHub MCP? (requires GITHUB_PERSONAL_ACCESS_TOKEN)"
```

3. **Database MCP** (if DATABASE_URL in .env):
```bash
# Detect database type and suggest appropriate MCP
```

**Verify settings.json** has `"enableAllProjectMcpServers": true`

---

## Phase 4: Hooks Setup

**Read the expert knowledge first**:
```
Read .claude/agents/hooks-expert.md to understand hook patterns
```

**Create essential hooks**:

1. **Auto-Loop stop hook** - Create `.claude/hooks/auto-loop-stop.sh`:
```bash
#!/bin/bash
CHECKPOINT=".auto-loop/checkpoint.json"
if [[ ! -f "$CHECKPOINT" ]]; then
  echo '{"decision": "allow"}'
  exit 0
fi
if [[ -f ".auto-loop/stop" ]]; then
  echo '{"decision": "allow"}'
  exit 0
fi
# Continue logic...
```

2. **Update settings.json** with Stop hook configuration

---

## Phase 5: Review Expert Agents

**List available experts** for user reference:

```markdown
### Expert Agents Installed

These agents can help you anytime:

| Ask about... | Expert Agent |
|--------------|--------------|
| CLAUDE.md design | Read `.claude/agents/claude-md-expert.md` |
| MCP configuration | Read `.claude/agents/mcp-expert.md` |
| Custom agents | Read `.claude/agents/agents-expert.md` |
| Custom skills | Read `.claude/agents/skills-expert.md` |
| Automation hooks | Read `.claude/agents/hooks-expert.md` |

**Usage**: "Help me with MCP setup" → I'll read mcp-expert.md and assist
```

---

## Phase 6: Summary

```markdown
## ✅ Project Initialized

**Project**: [name]
**Tech Stack**: [stack]

### Completed
- [x] CLAUDE.md created
- [x] Memory MCP configured
- [x] Auto-Loop hook set up
- [x] Expert Agents available

### Files Created
- `CLAUDE.md`
- `.claude/settings.json`
- `.claude/hooks/auto-loop-stop.sh`

### Expert Agents
Ask me to read any expert for specialized help:
- "Read claude-md-expert and help me improve CLAUDE.md"
- "Read mcp-expert and add Notion MCP"
- "Read agents-expert and create a security-reviewer"

### Next Steps
1. Review and customize `CLAUDE.md`
2. Run `/workflow` to start developing
3. Use `/auto-loop` for autonomous TDD
```

---

## Quick Mode

If user wants minimal setup, only do:
1. Phase 1: Analysis
2. Phase 2: Basic CLAUDE.md
3. Phase 4: Auto-Loop hook

Skip MCP and expert review.
