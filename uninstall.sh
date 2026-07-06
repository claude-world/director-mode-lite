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

# Surgically remove only the hooks/settings that install.sh injected,
# preserving any user-defined settings in settings.local.json.
remove_injected_settings() {
    local settings_file="$TARGET_DIR/.claude/settings.local.json"
    [[ -f "$settings_file" ]] || return 0

    if command -v python3 &>/dev/null; then
        SETTINGS_FILE="$settings_file" python3 - << 'PYEOF'
import json, os

path = os.environ['SETTINGS_FILE']
with open(path) as f:
    settings = json.load(f)

OUR_SCRIPTS = (
    'auto-loop-stop.sh', 'log-bash-event.sh',
    'log-file-change.sh', 'pre-tool-validator.sh',
)

def is_ours(entry):
    return any(s in h.get('command', '') for h in entry.get('hooks', []) for s in OUR_SCRIPTS)

hooks = settings.get('hooks', {})
for event in list(hooks.keys()):
    hooks[event] = [e for e in hooks[event] if not is_ours(e)]
    if not hooks[event]:
        del hooks[event]
if not hooks:
    settings.pop('hooks', None)

if settings.get('plansDirectory') == '.claude/plans':
    del settings['plansDirectory']

if settings:
    with open(path, 'w') as f:
        json.dump(settings, f, indent=2)
    print('  Removed Director Mode hooks from settings.local.json (other settings kept)')
else:
    os.remove(path)
    print('  Removed settings.local.json (contained only Director Mode settings)')
PYEOF
    else
        echo "  Warning: python3 not found - please remove Director Mode hooks"
        echo "  from .claude/settings.local.json manually."
    fi
}

case $choice in
    1)
        echo "Removing hooks..."
        rm -f "$TARGET_DIR/.claude/hooks.json"
        remove_injected_settings
        rm -rf "$TARGET_DIR/.claude/hooks/"
        rm -rf "$TARGET_DIR/.auto-loop/"
        rm -rf "$TARGET_DIR/.director-mode/"
        rm -rf "$TARGET_DIR/.self-evolving-loop/"
        echo ""
        echo "Removed:"
        echo "  - .claude/hooks/"
        echo "  - Director Mode hooks in .claude/settings.local.json"
        echo "  - .auto-loop/"
        echo "  - .director-mode/"
        echo "  - .self-evolving-loop/"
        echo ""
        echo "Kept:"
        echo "  - .claude/agents/"
        echo "  - .claude/skills/"
        echo "  - Your other settings in .claude/settings.local.json"
        ;;
    2)
        echo "Removing Director Mode Lite completely..."
        rm -rf "$TARGET_DIR/.claude/agents/"
        rm -rf "$TARGET_DIR/.claude/skills/"
        rm -rf "$TARGET_DIR/.claude/hooks/"
        rm -rf "$TARGET_DIR/.claude/plans/"
        rm -f "$TARGET_DIR/.claude/hooks.json"
        remove_injected_settings
        rm -rf "$TARGET_DIR/.auto-loop/"
        rm -rf "$TARGET_DIR/.director-mode/"
        rm -rf "$TARGET_DIR/.self-evolving-loop/"

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
