#!/bin/bash
# Director Mode Lite - Uninstall Script
# Remove hooks (optionally keep agents/skills)

set -euo pipefail

TARGET_DIR="${1:-.}"

echo "Director Mode Lite Uninstaller"
echo "=============================="
echo ""

# Check target directory
if [[ ! -d "$TARGET_DIR/.claude" ]]; then
    echo "Error: .claude directory not found: $TARGET_DIR/.claude"
    exit 1
fi

echo "Choose uninstall option:"
echo ""
echo "  1) Remove hooks only (keep agents/skills)"
echo "  2) Remove Director Mode Lite completely"
echo "  3) Cancel"
echo ""
read -p "Choice (1/2/3): " -n 1 -r choice
echo ""

case $choice in
    1)
        echo "Removing hooks..."
        rm -f "$TARGET_DIR/.claude/hooks.json"
        rm -f "$TARGET_DIR/.claude/settings.local.json"
        rm -rf "$TARGET_DIR/.claude/hooks/"
        rm -rf "$TARGET_DIR/.auto-loop/"
        rm -rf "$TARGET_DIR/.director-mode/"
        echo ""
        echo "Removed:"
        echo "  - .claude/hooks/"
        echo "  - .claude/settings.local.json"
        echo "  - .auto-loop/"
        echo "  - .director-mode/"
        echo ""
        echo "Kept:"
        echo "  - .claude/agents/"
        echo "  - .claude/skills/"
        ;;
    2)
        echo "Removing Director Mode Lite completely..."
        rm -rf "$TARGET_DIR/.claude/agents/"
        rm -rf "$TARGET_DIR/.claude/skills/"
        rm -rf "$TARGET_DIR/.claude/hooks/"
        rm -rf "$TARGET_DIR/.claude/plans/"
        rm -f "$TARGET_DIR/.claude/hooks.json"
        rm -f "$TARGET_DIR/.claude/settings.local.json"
        rm -rf "$TARGET_DIR/.auto-loop/"
        rm -rf "$TARGET_DIR/.director-mode/"

        # Remove .claude if empty
        if [[ -d "$TARGET_DIR/.claude" ]] && [[ -z "$(ls -A "$TARGET_DIR/.claude")" ]]; then
            rmdir "$TARGET_DIR/.claude"
        fi

        echo ""
        echo "Director Mode Lite completely removed"
        ;;
    3)
        echo "Cancelled"
        exit 0
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "Uninstall complete!"
