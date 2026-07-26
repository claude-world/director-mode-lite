#!/bin/bash
# Director Mode Lite - Uninstall Script
# Remove hooks (optionally keep agents/skills)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
echo "  2) Remove Director Mode Lite completely (including local handoff packets)"
echo "  3) Cancel"
echo ""
read -p "Choice (1/2/3): " -n 1 -r choice
echo ""

remove_owned_hook_files() {
    local manifest="$TARGET_DIR/.director-mode/install-ownership.json"
    if [[ -f "$manifest" ]]; then
        python3 "$SCRIPT_DIR/scripts/install-ownership.py" remove \
            --target "$TARGET_DIR" --hooks-only
    else
        echo "  No ownership manifest; preserved hook executables and removed registrations only."
    fi
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
    '.director-mode/hooks/advisory.sh',
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

remove_portable_hook_adapters() {
    local hook_file
    for hook_file in \
        "$TARGET_DIR/.codex/hooks.json" \
        "$TARGET_DIR/.grok/hooks/director-mode.json"; do
        [[ -f "$hook_file" ]] || continue
        if ! command -v python3 &>/dev/null; then
            echo "  Warning: python3 unavailable; remove advisory.sh from $hook_file manually."
            continue
        fi
        SETTINGS_FILE="$hook_file" python3 - <<'PYEOF'
import json
import os

path = os.environ["SETTINGS_FILE"]
with open(path) as handle:
    data = json.load(handle)

def is_director(entry):
    return any(
        ".director-mode/hooks/advisory.sh" in hook.get("command", "")
        for hook in entry.get("hooks", [])
        if isinstance(hook, dict)
    ) if isinstance(entry, dict) else False

hooks = data.get("hooks", {})
for event in list(hooks):
    hooks[event] = [entry for entry in hooks[event] if not is_director(entry)]
    if not hooks[event]:
        del hooks[event]
if not hooks:
    data.pop("hooks", None)

if data:
    with open(path, "w") as handle:
        json.dump(data, handle, indent=2)
        handle.write("\n")
else:
    os.remove(path)
PYEOF
        echo "  Removed Director Mode advisory from ${hook_file#$TARGET_DIR/}"
    done
}

remove_guidance_blocks() {
    command -v python3 &>/dev/null || return 0
    for guide in "$TARGET_DIR/CLAUDE.md" "$TARGET_DIR/AGENTS.md"; do
        [[ -f "$guide" ]] || continue
        GUIDE_FILE="$guide" python3 - <<'PYEOF'
import os
import pathlib
import re

path = pathlib.Path(os.environ["GUIDE_FILE"])
text = path.read_text(encoding="utf-8")
text = re.sub(
    r"\n?<!-- director-mode-lite:start -->.*?<!-- director-mode-lite:end -->\n?",
    "\n",
    text,
    flags=re.DOTALL,
).strip()
if path.name == "AGENTS.md" and text == "# Repository guidance":
    path.unlink()
else:
    path.write_text(text + "\n", encoding="utf-8")
PYEOF
    done
}

remove_installed_assets() {
    remove_injected_settings 1
    remove_portable_hook_adapters
    if [[ -f "$TARGET_DIR/.director-mode/install-ownership.json" ]]; then
        python3 "$SCRIPT_DIR/scripts/install-ownership.py" remove --target "$TARGET_DIR"
    else
        echo "  No ownership manifest; preserving agents, skills, and runtime files."
        echo "  Remove legacy files manually after confirming ownership."
    fi
    remove_guidance_blocks

    for directory in \
        "$TARGET_DIR/.claude/agents" \
        "$TARGET_DIR/.claude/skills" \
        "$TARGET_DIR/.claude/hooks" \
        "$TARGET_DIR/.codex/agents" \
        "$TARGET_DIR/.agents/skills" \
        "$TARGET_DIR/.grok/agents" \
        "$TARGET_DIR/.grok/hooks" \
        "$TARGET_DIR/.director-mode/hooks" \
        "$TARGET_DIR/.director-mode/bin"; do
        if [[ -d "$directory" ]] && [[ -z "$(ls -A "$directory")" ]]; then
            rmdir "$directory"
        fi
    done
}

case $choice in
    1)
        echo "Removing Director Mode hook registrations and owned hook files..."
        remove_injected_settings 0
        remove_portable_hook_adapters
        remove_owned_hook_files
        echo ""
        echo "Removed:"
        echo "  - Unmodified Director-owned files from hook directories"
        echo "  - Director Mode hooks in .claude/settings.local.json"
        echo "  - Director Mode advisory adapters for Codex and Grok"
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
        remove_installed_assets

        # Option 2 explicitly includes portable handoff packets. Preserve
        # other unknown or modified runtime state instead of deleting broad
        # directories that may also contain user files.
        if [[ -d "$TARGET_DIR/.director-mode/handoffs" ]]; then
            rm -rf -- "$TARGET_DIR/.director-mode/handoffs"
            echo "  Removed: .director-mode/handoffs/"
        fi
        for directory in \
            "$TARGET_DIR/.director-mode" \
            "$TARGET_DIR/.auto-loop" \
            "$TARGET_DIR/.self-evolving-loop"; do
            if [[ -d "$directory" ]] && [[ -z "$(ls -A "$directory")" ]]; then
                rmdir "$directory"
            fi
        done

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
