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

# Surgically remove only registrations proven to reference Director-owned hook
# assets. Generic legacy hook names require manifest ownership, so a user-owned
# same-name hook is not claimed during uninstall.
remove_injected_settings() {
    local settings_file="$TARGET_DIR/.claude/settings.local.json"
    local remove_plans_setting="${1:-0}"

    if ! command -v python3 &>/dev/null; then
        echo "  Warning: python3 not found - please remove Director Mode hooks"
        echo "  from .claude/settings.local.json manually."
        return 0
    fi

    python3 "$SCRIPT_DIR/scripts/director-hooks.py" prune --target "$TARGET_DIR"
    [[ "$remove_plans_setting" == "1" && -f "$settings_file" ]] || return 0

    SETTINGS_FILE="$settings_file" python3 - <<'PYEOF'
import json
import os
from pathlib import Path

path = Path(os.environ["SETTINGS_FILE"])
settings = json.loads(path.read_text(encoding="utf-8"))
if settings.get("plansDirectory") != ".claude/plans":
    raise SystemExit(0)
del settings["plansDirectory"]
if settings:
    path.write_text(json.dumps(settings, indent=2) + "\n", encoding="utf-8")
else:
    path.unlink()
PYEOF
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
