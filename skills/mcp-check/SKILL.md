---
name: mcp-check
description: Validate MCP configuration and suggest improvements. Use when MCP servers fail to load, after editing .mcp.json, or when the user runs /mcp-check.
user-invocable: true
---

# MCP Configuration Validator

Validate the project's MCP setup for correctness and completeness.

---

## Validation Steps

### 1. Check Configuration Files

| File | Scope | What lives here |
|------|-------|-----------------|
| `.mcp.json` (project root) | Project | `mcpServers` — the server definitions, written by `claude mcp add --scope project` |
| `.claude/settings.json` | Project | Toggles only: `enableAllProjectMcpServers`, `enabledMcpjsonServers` |
| `~/.claude.json` | User | User-scope `mcpServers`, available across all projects |

**The source of truth for project servers is `.mcp.json` at the project root.** Read `mcpServers` from there — `.claude/settings.json` never holds server definitions, only approval toggles.

### 2. Validate Structure
- [ ] `.mcp.json` is valid JSON (no trailing commas)
- [ ] `mcpServers` object exists in `.mcp.json`
- [ ] Project servers are approved via `.claude/settings.json`: either `enableAllProjectMcpServers: true`, or each server named in `enabledMcpjsonServers`

### 3. Validate Each MCP
- [ ] `command` is valid
- [ ] `args` properly formatted
- [ ] `env` variables set

### 4. Check Essential MCPs
| MCP | Required? |
|-----|-----------|
| memory | Recommended |
| filesystem | Optional |
| github | If .git exists |

### 5. Security Check
- [ ] No hardcoded secrets
- [ ] Sensitive values use env vars

---

## Output Format

```markdown
## MCP Configuration Report

### Status: VALID / ISSUES / INVALID

### Configuration Summary
| MCP Server | Status | Notes |
|------------|--------|-------|
| memory | OK/FAIL | details |

### Issues Found
1. [Issue and fix]

### Missing Recommended MCPs
- memory: `claude mcp add --scope project memory...`
```

---

## Common Issues

| Issue | Fix |
|-------|-----|
| Invalid JSON | Check trailing commas |
| MCP not loading | `claude mcp reset-project-choices` |
| Missing env vars | Add with `-e KEY=value` |
