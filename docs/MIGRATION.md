# Migration Guide

How to upgrade Director Mode Lite between versions.

---

## Important: install.sh Skips Existing Files

The install script uses **skip-existing** logic: it will NOT overwrite files that already exist in your `.claude/` directory. This means upgrading requires manual steps.

---

## Upgrading to v1.7.1 (Current)

### From v1.4.x or Earlier

Agent files changed significantly in v1.5.0-v1.7.0:
- Tools format changed from bracket array to YAML list
- New fields added: `color`, `model`, `skills`, `hooks`, `permissionMode`
- `memory` and `maxTurns` were removed in v1.5.1 then restored in v1.7.0

**Recommended: Full re-install**

```bash
# 1. Backup your customizations
cp -r .claude/ .claude-backup-manual/

# 2. Remove old installation
rm -rf .claude/agents/ .claude/skills/ .claude/hooks/

# 3. Re-run install
/path/to/director-mode-lite/install.sh .

# 4. Restore any custom agents/skills you added
# Copy back only YOUR custom files from .claude-backup-manual/
```

### From v1.5.x-v1.6.x

Mainly frontmatter refinements. Safe to re-install:

```bash
# Remove only the distributed files (keep your custom ones)
rm -rf .claude/agents/ .claude/skills/ .claude/hooks/
/path/to/director-mode-lite/install.sh .
```

### From v1.7.0

Only security fix and verification script added. Safe to update in-place:

```bash
/path/to/director-mode-lite/install.sh .
# New files will be added, existing ones skipped
```

---

## Breaking Changes by Version

| Version | Breaking Change | Action |
|---------|----------------|--------|
| v1.7.0 | Agent `memory`/`maxTurns` restored | Re-install agents |
| v1.5.1 | Agent `tools` changed to YAML list | Re-install agents |
| v1.5.0 | Agent frontmatter format upgrade | Re-install agents |
| v1.4.1 | Hook paths changed to `$CLAUDE_PROJECT_DIR` | Re-install hooks |
| v1.3.0 | Commands migrated to `.claude/skills/` | Re-install skills |

---

## Checking Your Version

The installed version is not tracked in the project directory. Check what you have:

```bash
# Check agent format (should have YAML list tools)
head -15 .claude/agents/code-reviewer.md

# If you see "tools: [Read, Write]" → you need to upgrade
# If you see "tools:\n  - Read\n  - Write" → you're on v1.5.0+

# Check if newer skills exist
ls .claude/skills/getting-started/   # Added in v1.7.2
ls .claude/skills/interop-router/    # Added in v1.6.0
```

---

## Questions?

- [Discord](https://discord.com/invite/rBtHzSD288)
- [GitHub Issues](https://github.com/claude-world/director-mode-lite/issues)
