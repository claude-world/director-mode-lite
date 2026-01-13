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

# Handle hooks.json merging
echo "Configuring hooks.json..."
if [[ -f "$TARGET_DIR/.claude/hooks.json" ]]; then
    echo "  Detected existing hooks.json, attempting to merge..."
    
    # Use Python to merge hooks.json (handles both Stop and PostToolUse)
    # Pass paths via environment variables to avoid shell injection
    if TARGET_DIR="$TARGET_DIR" SCRIPT_DIR="$SCRIPT_DIR" python3 -c "
import json
import sys
import os

hooks_file = os.path.join(os.environ['TARGET_DIR'], '.claude', 'hooks.json')
source_file = os.path.join(os.environ['SCRIPT_DIR'], 'hooks', 'hooks.json')

# Read existing hooks
with open(hooks_file, 'r') as f:
    existing = json.load(f)

# Read source hooks
with open(source_file, 'r') as f:
    source = json.load(f)

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

# Write merged hooks
with open(hooks_file, 'w') as f:
    json.dump(existing, f, indent=2)

print('  hooks.json merge complete')
" 2>/dev/null; then
        :  # Success, Python already printed status
    else
        echo "  Warning: Could not auto-merge hooks.json"
        echo "  Please manually merge from: $SCRIPT_DIR/hooks/hooks.json"
    fi
else
    # No existing hooks.json, copy directly
    cp "$SCRIPT_DIR/hooks/hooks.json" "$TARGET_DIR/.claude/"
    echo "  Installed: hooks.json (fresh)"
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
