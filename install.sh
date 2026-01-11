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
for file in "$SCRIPT_DIR/.claude/commands/"*.md; do
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
for dir in "$SCRIPT_DIR/.claude/commands/"*/; do
    if [[ -d "$dir" ]]; then
        dirname=$(basename "$dir")
        if [[ -d "$TARGET_DIR/.claude/commands/$dirname" ]]; then
            echo "  Skipped (exists): commands/$dirname/"
        else
            cp -r "$dir" "$TARGET_DIR/.claude/commands/"
            echo "  Installed: commands/$dirname/"
        fi
    fi
done

# Copy agents (skip existing files)
echo "Installing agents..."
mkdir -p "$TARGET_DIR/.claude/agents"
for file in "$SCRIPT_DIR/.claude/agents/"*.md; do
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
for dir in "$SCRIPT_DIR/.claude/skills/"*/; do
    if [[ -d "$dir" ]]; then
        dirname=$(basename "$dir")
        if [[ -d "$TARGET_DIR/.claude/skills/$dirname" ]]; then
            echo "  Skipped (exists): skills/$dirname/"
        else
            cp -r "$dir" "$TARGET_DIR/.claude/skills/"
            echo "  Installed: skills/$dirname/"
        fi
    fi
done

# Install hooks (merge instead of overwrite)
echo "Installing Auto-Loop hooks..."
mkdir -p "$TARGET_DIR/.claude/hooks"
cp "$SCRIPT_DIR/.claude/hooks/auto-loop-stop.sh" "$TARGET_DIR/.claude/hooks/"
chmod +x "$TARGET_DIR/.claude/hooks/auto-loop-stop.sh"

if [[ -f "$TARGET_DIR/.claude/hooks.json" ]]; then
    echo "  Detected existing hooks.json, attempting to merge..."

    # Check if Stop hook already exists
    if grep -q '"Stop"' "$TARGET_DIR/.claude/hooks.json" 2>/dev/null; then
        echo "  Warning: Stop hook already exists. Please manually merge:"
        echo ""
        echo '    "Stop": ['
        echo '      {'
        echo '        "hooks": ['
        echo '          {'
        echo '            "type": "command",'
        echo '            "command": ".claude/hooks/auto-loop-stop.sh"'
        echo '          }'
        echo '        ]'
        echo '      }'
        echo '    ]'
        echo ""
    else
        # Use Python to merge JSON (more reliable)
        if python3 -c "
import json
import sys

hooks_file = '$TARGET_DIR/.claude/hooks.json'

with open(hooks_file, 'r') as f:
    existing = json.load(f)

if 'hooks' not in existing:
    existing['hooks'] = {}

existing['hooks']['Stop'] = [
    {
        'hooks': [
            {
                'type': 'command',
                'command': '.claude/hooks/auto-loop-stop.sh'
            }
        ]
    }
]

with open(hooks_file, 'w') as f:
    json.dump(existing, f, indent=2)
" 2>/dev/null; then
            echo "  Merged Stop hook into hooks.json"
        else
            echo "  Warning: Could not auto-merge. Please manually add Stop hook."
        fi
    fi
else
    # No existing hooks.json, copy directly
    cp "$SCRIPT_DIR/.claude/hooks/hooks.json" "$TARGET_DIR/.claude/"
    echo "  Installed: hooks.json"
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
echo "  - .claude/commands/     (13 commands)"
echo "  - .claude/agents/       (3 agents)"
echo "  - .claude/skills/       (4 skills)"
echo "  - .claude/hooks/        (Auto-Loop Stop Hook)"
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
