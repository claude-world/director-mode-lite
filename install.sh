#!/bin/bash
# Director Mode Lite - Installation Script
# Safe installation: backup existing config + merge hooks.json

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${1:-.}"
BACKUP_DIR="$TARGET_DIR/.claude-backup-$(date +%Y%m%d-%H%M%S)"

echo "Director Mode Lite Installer"
echo "============================"
echo ""

# Check target directory
if [[ ! -d "$TARGET_DIR" ]]; then
    echo "Error: Target directory does not exist: $TARGET_DIR"
    exit 1
fi

# Backup existing .claude directory
if [[ -d "$TARGET_DIR/.claude" ]]; then
    echo "Detected existing .claude directory, creating backup..."
    cp -r "$TARGET_DIR/.claude" "$BACKUP_DIR"
    echo "  Backup location: $BACKUP_DIR"
    echo ""
fi

# Ensure .claude directory exists
mkdir -p "$TARGET_DIR/.claude"

# Copy agents (skip existing files)
echo "Installing agents..."
mkdir -p "$TARGET_DIR/.claude/agents"
for file in "$SCRIPT_DIR/agents/"*.md; do
    if [[ -f "$file" ]]; then
        filename=$(basename "$file")
        if [[ -f "$TARGET_DIR/.claude/agents/$filename" ]]; then
            echo "  Skipped (exists): agents/$filename"
        else
            cp "$file" "$TARGET_DIR/.claude/agents/"
            echo "  Installed: agents/$filename"
        fi
    fi
done

# Copy skills (preserve directory structure: skills/<name>/SKILL.md)
echo "Installing skills..."
mkdir -p "$TARGET_DIR/.claude/skills"
for dir in "$SCRIPT_DIR/skills/"*/; do
    if [[ -d "$dir" ]]; then
        dirname=$(basename "$dir")
        if [[ -d "$TARGET_DIR/.claude/skills/$dirname" ]]; then
            echo "  Skipped (exists): skills/$dirname/"
        else
            cp -r "${dir%/}" "$TARGET_DIR/.claude/skills/"
            echo "  Installed: skills/$dirname/"
        fi
    fi
done

# Install hooks
echo "Installing hooks..."
mkdir -p "$TARGET_DIR/.claude/hooks"

# List of all hook scripts to install
# Note: log-bash-event.sh replaces separate log-test-result.sh and log-commit.sh
# to avoid stdin conflicts (only one hook can read stdin)
HOOK_SCRIPTS=(
    "_lib-changelog.sh"
    "auto-loop-stop.sh"
    "log-bash-event.sh"
    "log-file-change.sh"
    "pre-tool-validator.sh"
)

for hook in "${HOOK_SCRIPTS[@]}"; do
    if [[ -f "$SCRIPT_DIR/hooks/$hook" ]]; then
        cp "$SCRIPT_DIR/hooks/$hook" "$TARGET_DIR/.claude/hooks/"
        chmod +x "$TARGET_DIR/.claude/hooks/$hook"
        echo "  Installed: hooks/$hook"
    fi
done

# Remove deprecated/renamed hooks
DEPRECATED_HOOKS=(
    "log-commit.sh"
    "log-test-result.sh"
    "changelog-logger.sh"
)
for deprecated in "${DEPRECATED_HOOKS[@]}"; do
    if [[ -f "$TARGET_DIR/.claude/hooks/$deprecated" ]]; then
        rm -f "$TARGET_DIR/.claude/hooks/$deprecated"
        echo "  Removed deprecated: hooks/$deprecated"
    fi
done

# Handle settings.local.json merging (Claude Code reads hooks from here)
# IMPORTANT: This preserves all existing user settings and only adds/merges hooks
# Uses $CLAUDE_PROJECT_DIR for portable paths (resolved at runtime by Claude Code)
echo "Configuring hooks in settings.local.json..."

# Use Python to safely merge hooks into existing settings
if TARGET_DIR="$TARGET_DIR" SCRIPT_DIR="$SCRIPT_DIR" python3 -c "
import json
import os

target_dir = os.path.abspath(os.environ['TARGET_DIR'])
settings_file = os.path.join(target_dir, '.claude', 'settings.local.json')

# Read existing settings (or create empty)
existing = {}
if os.path.exists(settings_file):
    with open(settings_file, 'r') as f:
        existing = json.load(f)

# Read source hooks (uses \$CLAUDE_PROJECT_DIR for portable paths)
source_file = os.path.join(os.environ['SCRIPT_DIR'], 'hooks', 'settings-hooks.json')
with open(source_file, 'r') as f:
    source = json.load(f)

# Merge hooks (no path conversion needed - uses \$CLAUDE_PROJECT_DIR)
if 'hooks' not in existing:
    existing['hooks'] = {}

if 'Stop' in source.get('hooks', {}):
    if 'Stop' not in existing['hooks']:
        existing['hooks']['Stop'] = source['hooks']['Stop']
        print('  Merged: Stop hooks')

if 'PostToolUse' in source.get('hooks', {}):
    if 'PostToolUse' not in existing['hooks']:
        existing['hooks']['PostToolUse'] = source['hooks']['PostToolUse']
        print('  Merged: PostToolUse hooks (changelog)')

if 'PreToolUse' in source.get('hooks', {}):
    if 'PreToolUse' not in existing['hooks']:
        existing['hooks']['PreToolUse'] = source['hooks']['PreToolUse']
        print('  Merged: PreToolUse hooks (file validation)')

# Add plansDirectory setting
if 'plansDirectory' not in existing:
    existing['plansDirectory'] = '.claude/plans'
    print('  Added: plansDirectory setting')

# Write settings
os.makedirs(os.path.dirname(settings_file), exist_ok=True)
with open(settings_file, 'w') as f:
    json.dump(existing, f, indent=2)

print('  settings.local.json configured')
"; then
    :  # Success, Python already printed status
else
    echo "  Warning: Could not auto-configure hooks (exit code: $?)"
    echo "  Please manually add hooks from: $SCRIPT_DIR/hooks/settings-hooks.json"
fi

# Copy CLAUDE.md template (if target doesn't have one)
if [[ ! -f "$TARGET_DIR/CLAUDE.md" ]] && [[ -f "$SCRIPT_DIR/docs/CLAUDE-TEMPLATE.md" ]]; then
    echo "Copying CLAUDE.md template..."
    cp "$SCRIPT_DIR/docs/CLAUDE-TEMPLATE.md" "$TARGET_DIR/CLAUDE.md"
fi

echo ""
echo "Installation complete!"
echo ""
echo "Installed:"
echo "  - .claude/skills/       (25 slash commands + 4 internal skills)"
echo "  - .claude/agents/       (14 specialized agents)"
echo "  - .claude/hooks/        (5 hooks: Auto-Loop, Changelog, Validator)"
echo ""
echo "Features:"
echo "  - /auto-loop     TDD-based autonomous development"
echo "  - /changelog     Observability changelog (experimental)"
echo "  - /workflow      Complete 5-step development flow"
echo ""
if [[ -d "$BACKUP_DIR" ]]; then
    echo "Backup location: $BACKUP_DIR"
    echo ""
fi
echo "Get started:"
echo "  cd $TARGET_DIR"
echo "  claude"
echo "  /workflow"
echo ""
