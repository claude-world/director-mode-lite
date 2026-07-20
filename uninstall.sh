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

# These are the only files option 1 owns inside the shared .claude/hooks/
# directory. Never remove that directory wholesale: projects may keep their
# own hook scripts beside Director Mode Lite.
DML_HOOK_SCRIPTS=(
    "_lib-changelog.sh"
    "auto-loop-stop.sh"
    "log-bash-event.sh"
    "log-file-change.sh"
    "pre-tool-validator.sh"
)

remove_dml_hook_files() {
    local hook
    for hook in "${DML_HOOK_SCRIPTS[@]}"; do
        local path="$TARGET_DIR/.claude/hooks/$hook"
        if [[ -e "$path" || -L "$path" ]]; then
            rm -f -- "$path"
            echo "  Removed: .claude/hooks/$hook"
        fi
    done
}

# Surgically remove only the hooks/settings that install.sh injected,
# preserving any user-defined settings in settings.local.json.
remove_injected_settings() {
    local settings_file="$TARGET_DIR/.claude/settings.local.json"
    local remove_plans_setting="${1:-0}"
    [[ -f "$settings_file" ]] || return 0

    if command -v python3 &>/dev/null; then
        SETTINGS_FILE="$settings_file" REMOVE_PLANS_SETTING="$remove_plans_setting" python3 - << 'PYEOF'
import json, os

path = os.environ['SETTINGS_FILE']
with open(path) as f:
    settings = json.load(f)

OUR_HOOK_PATHS = (
    '.claude/hooks/auto-loop-stop.sh',
    '.claude/hooks/log-bash-event.sh',
    '.claude/hooks/log-file-change.sh',
    '.claude/hooks/pre-tool-validator.sh',
    '.self-evolving-loop/hooks/continue-loop.sh',
    '.self-evolving-loop/hooks/log-event.sh',
    '.self-evolving-loop/hooks/phase-tracker.sh',
)

def is_ours(entry):
    if not isinstance(entry, dict):
        return False
    return any(
        path_fragment in hook.get('command', '')
        for hook in entry.get('hooks', [])
        if isinstance(hook, dict)
        for path_fragment in OUR_HOOK_PATHS
    )

hooks = settings.get('hooks', {})
for event in list(hooks.keys()):
    hooks[event] = [e for e in hooks[event] if not is_ours(e)]
    if not hooks[event]:
        del hooks[event]
if not hooks:
    settings.pop('hooks', None)

if os.environ.get('REMOVE_PLANS_SETTING') == '1' and settings.get('plansDirectory') == '.claude/plans':
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
        echo "Removing Director Mode hook registrations and owned hook files..."
        remove_injected_settings 0
        remove_dml_hook_files
        echo ""
        echo "Removed:"
        echo "  - Director Mode files from .claude/hooks/"
        echo "  - Director Mode hooks in .claude/settings.local.json"
        echo ""
        echo "Kept:"
        echo "  - Other files in .claude/hooks/"
        echo "  - .claude/agents/"
        echo "  - .claude/skills/"
        echo "  - Your other settings in .claude/settings.local.json"
        echo "  - Runtime state in .auto-loop/, .director-mode/, and .self-evolving-loop/"
        ;;
    2)
        echo "Removing Director Mode Lite completely..."
        rm -rf "$TARGET_DIR/.claude/agents/"
        rm -rf "$TARGET_DIR/.claude/skills/"
        rm -rf "$TARGET_DIR/.claude/hooks/"
        rm -rf "$TARGET_DIR/.claude/plans/"
        rm -f "$TARGET_DIR/.claude/hooks.json"
        remove_injected_settings 1
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
