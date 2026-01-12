---
description: Validate MCP configuration and suggest improvements
---

# MCP Configuration Validator

Validate the project's MCP setup for correctness and completeness.

## Validation Steps

### Step 1: Check Configuration Files

```bash
# Check project settings
cat .claude/settings.json 2>/dev/null

# Check user settings (for reference)
cat ~/.claude.json 2>/dev/null | head -50
```

### Step 2: Validate Structure

Check `.claude/settings.json`:
- [ ] Valid JSON format
- [ ] `mcpServers` object exists
- [ ] `enableAllProjectMcpServers: true` is set

### Step 3: Validate Each MCP

For each configured MCP, check:
- [ ] `command` is valid (npx, node, python, etc.)
- [ ] `args` array is properly formatted
- [ ] `env` variables are set (not empty placeholders)

### Step 4: Check Essential MCPs

| MCP | Required? | Status |
|-----|-----------|--------|
| memory | Recommended | Check if configured with project-scoped path |
| filesystem | Optional | Check if path is appropriate |
| github | If .git exists | Check if token is set |

### Step 5: Security Check

- [ ] No hardcoded secrets in settings.json
- [ ] Sensitive values use environment variables
- [ ] settings.json is not gitignored (should be shared)

## Output Format

```markdown
## MCP Configuration Report

### Status: ✅ VALID / ⚠️ ISSUES / ❌ INVALID

### Configuration Summary
| MCP Server | Status | Notes |
|------------|--------|-------|
| memory | ✅/❌ | [details] |
| [other] | ✅/❌ | [details] |

### Issues Found
1. [Issue and fix]

### Missing Recommended MCPs
- [ ] memory - Add with: `claude mcp add --scope project memory -e MEMORY_FILE_PATH=./.claude/memory.json -- npx -y @modelcontextprotocol/server-memory`

### Suggestions
1. [Suggestion]
```

## Common Issues

| Issue | Fix |
|-------|-----|
| Invalid JSON | Check for trailing commas, missing quotes |
| MCP not loading | Run `claude mcp reset-project-choices` |
| Missing env vars | Add with `-e KEY=value` flag |

## Reference

For MCP setup help, read `.claude/agents/mcp-expert.md`
