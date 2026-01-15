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

# Copy commands (skip existing files)
echo "Installing commands..."
mkdir -p "$TARGET_DIR/.claude/commands"

# Copy top-level command files
for file in "$SCRIPT_DIR/commands/"*.md; do
    if [[ -f "$file" ]]; then
        filename=$(basename "$file")
        if [[ -f "$TARGET_DIR/.claude/commands/$filename" ]]; then
            echo "  Skipped (exists): commands/$filename"
        else
            cp "$file" "$TARGET_DIR/.claude/commands/"
            echo "  Installed: commands/$filename"
        fi
    fi
done

# Copy command subdirectories
for dir in "$SCRIPT_DIR/commands/"*/; do
    if [[ -d "$dir" ]]; then
        dirname=$(basename "$dir")
        if [[ -d "$TARGET_DIR/.claude/commands/$dirname" ]]; then
            echo "  Skipped (exists): commands/$dirname/"
        else
            cp -r "${dir%/}" "$TARGET_DIR/.claude/commands/"
            echo "  Installed: commands/$dirname/"
        fi
    fi
done

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
    "auto-loop-stop.sh"
    "changelog-logger.sh"
    "log-file-change.sh"
    "log-bash-event.sh"
)

for hook in "${HOOK_SCRIPTS[@]}"; do
    if [[ -f "$SCRIPT_DIR/hooks/$hook" ]]; then
        cp "$SCRIPT_DIR/hooks/$hook" "$TARGET_DIR/.claude/hooks/"
        chmod +x "$TARGET_DIR/.claude/hooks/$hook"
        echo "  Installed: hooks/$hook"
    fi
done

# Remove deprecated hooks (replaced by log-bash-event.sh in v1.1.0)
DEPRECATED_HOOKS=(
    "log-commit.sh"
    "log-test-result.sh"
)
for deprecated in "${DEPRECATED_HOOKS[@]}"; do
    if [[ -f "$TARGET_DIR/.claude/hooks/$deprecated" ]]; then
        rm -f "$TARGET_DIR/.claude/hooks/$deprecated"
        echo "  Removed deprecated: hooks/$deprecated"
    fi
done

# Handle settings.local.json merging (Claude Code reads hooks from here)
# IMPORTANT: This preserves all existing user settings and only adds/merges hooks
echo "Configuring hooks in settings.local.json..."

# Use Python to safely merge hooks into existing settings
# Converts relative paths to absolute paths
if TARGET_DIR="$TARGET_DIR" SCRIPT_DIR="$SCRIPT_DIR" python3 -c "
import json
import os

settings_file = os.path.join(os.environ['TARGET_DIR'], '.claude', 'settings.local.json')
source_file = os.path.join(os.environ['SCRIPT_DIR'], 'hooks', 'settings-hooks.json')
target_dir = os.environ['TARGET_DIR']

# Read existing settings (or create empty)
existing = {}
if os.path.exists(settings_file):
    try:
        with open(settings_file, 'r') as f:
            existing = json.load(f)
        print('  Found existing settings.local.json')
    except:
        existing = {}

# Read source hooks
with open(source_file, 'r') as f:
    source = json.load(f)

# Convert relative paths to absolute paths
def convert_relative_to_absolute(obj, target_dir):
    """Convert .claude/hooks/* paths to absolute paths"""
    if isinstance(obj, dict):
        if 'command' in obj and isinstance(obj['command'], str):
            command = obj['command']
            if command.startswith('.claude/hooks/'):
                hook_name = command.replace('.claude/hooks/', '')
                obj['command'] = os.path.join(target_dir, '.claude', 'hooks', hook_name)
        for key, value in obj.items():
            obj[key] = convert_relative_to_absolute(value, target_dir)
    elif isinstance(obj, list):
        obj = [convert_relative_to_absolute(item, target_dir) for item in obj]
    return obj

source = convert_relative_to_absolute(source, target_dir)

if 'hooks' not in existing:
    existing['hooks'] = {}

# Merge Stop hooks
if 'Stop' in source.get('hooks', {}):
    if 'Stop' not in existing['hooks']:
        existing['hooks']['Stop'] = source['hooks']['Stop']
        print('  Merged: Stop hooks')
    else:
        print('  Skipped: Stop hooks (already exists)')

# Merge PostToolUse hooks
if 'PostToolUse' in source.get('hooks', {}):
    if 'PostToolUse' not in existing['hooks']:
        existing['hooks']['PostToolUse'] = source['hooks']['PostToolUse']
        print('  Merged: PostToolUse hooks (changelog)')
    else:
        # Append new PostToolUse hooks if not already present
        existing_commands = set()
        for hook_group in existing['hooks']['PostToolUse']:
            for hook in hook_group.get('hooks', []):
                existing_commands.add(hook.get('command', ''))

        added = 0
        for hook_group in source['hooks']['PostToolUse']:
            for hook in hook_group.get('hooks', []):
                if hook.get('command', '') not in existing_commands:
                    existing['hooks']['PostToolUse'].append(hook_group)
                    added += 1
                    break

        if added > 0:
            print(f'  Merged: {added} PostToolUse hook(s)')
        else:
            print('  Skipped: PostToolUse hooks (already exists)')

# Write merged settings (preserves all other user settings)
with open(settings_file, 'w') as f:
    json.dump(existing, f, indent=2)

print('  settings.local.json configured')
" 2>/dev/null; then
    :  # Success, Python already printed status
else
    echo "  Warning: Could not auto-configure hooks"
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
echo "  - .claude/commands/     (slash commands)"
echo "  - .claude/agents/       (specialized agents)"
echo "  - .claude/skills/       (reusable skills)"
echo "  - .claude/hooks/        (Auto-Loop + Changelog hooks)"
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
