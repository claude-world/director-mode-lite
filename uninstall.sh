#!/bin/bash
# Director Mode Lite - Uninstall Script
# Remove Auto-Loop hooks (optionally keep commands/agents/skills)

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
echo "  1) Remove Auto-Loop hooks only (keep commands/agents/skills)"
echo "  2) Remove Director Mode Lite completely"
echo "  3) Cancel"
echo ""
read -p "Choice (1/2/3): " -n 1 -r choice
echo ""

case $choice in
    1)
        echo "Removing Auto-Loop hooks..."
        rm -f "$TARGET_DIR/.claude/hooks.json"
        rm -rf "$TARGET_DIR/.claude/hooks/"
        rm -rf "$TARGET_DIR/.auto-loop/"
        echo ""
        echo "Removed:"
        echo "  - .claude/hooks.json"
        echo "  - .claude/hooks/"
        echo "  - .auto-loop/"
        echo ""
        echo "Kept:"
        echo "  - .claude/commands/"
        echo "  - .claude/agents/"
        echo "  - .claude/skills/"
        ;;
    2)
        echo "Removing Director Mode Lite completely..."
        rm -rf "$TARGET_DIR/.claude/commands/"
        rm -rf "$TARGET_DIR/.claude/agents/"
        rm -rf "$TARGET_DIR/.claude/skills/"
        rm -f "$TARGET_DIR/.claude/hooks.json"
        rm -rf "$TARGET_DIR/.claude/hooks/"
        rm -rf "$TARGET_DIR/.auto-loop/"

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

# Anonymous usage tracking (opt-out with DISABLE_ANALYTICS=1)
if [[ "${DISABLE_ANALYTICS:-0}" != "1" ]]; then
    VERSION="1.0.0"
    OS_NAME=$(uname -s 2>/dev/null || echo "unknown")
    ARCH=$(uname -m 2>/dev/null || echo "unknown")
    SHELL_NAME=$(basename "$SHELL" 2>/dev/null || echo "unknown")

    curl -s -X POST "https://claude-world.com/api/analytics/install" \
        -H "Content-Type: application/json" \
        -d "{\"project\":\"director-mode-lite\",\"version\":\"$VERSION\",\"action\":\"uninstall\",\"os\":\"$OS_NAME\",\"arch\":\"$ARCH\",\"shell\":\"$SHELL_NAME\"}" \
        > /dev/null 2>&1 &
fi
