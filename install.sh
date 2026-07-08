#!/bin/bash
# Director Mode Lite - Installation Script
# Safe installation: backup existing config + merge hooks.json
#
# Usage: ./install.sh [--update] [--wizard] [target-dir]
#   --update   Overwrite distributed files (agents/skills/hooks + .self-evolving-loop
#              scaffolding) instead of skipping existing ones. CLAUDE.md is never
#              overwritten. target-dir defaults to the current directory.
#   --wizard   Interactive setup: ask a few questions about the project and pick
#              which Stop-hook automation (Auto-Loop / Evolving-Loop) and
#              observability/safety hooks to wire into settings.local.json.
#              Requires a TTY; falls back to defaults otherwise. Agents and
#              skills are always installed in full either way — the wizard
#              only chooses which *hooks* get activated. Run /project-init
#              afterwards for deep language/framework-aware CLAUDE.md setup.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse args: optional --update/--wizard flags (anywhere) + optional target dir (first non-flag arg)
UPDATE_MODE=0
WIZARD_MODE=0
TARGET_DIR="."
_target_set=0
for arg in "$@"; do
    case "$arg" in
        --update)
            UPDATE_MODE=1
            ;;
        --wizard)
            WIZARD_MODE=1
            ;;
        *)
            if [[ $_target_set -eq 0 ]]; then
                TARGET_DIR="$arg"
                _target_set=1
            fi
            ;;
    esac
done

BACKUP_DIR="$TARGET_DIR/.claude-backup-$(date +%Y%m%d-%H%M%S)"

echo "Director Mode Lite Installer"
echo "============================"
if [[ $UPDATE_MODE -eq 1 ]]; then
    echo "Mode: update (overwrite distributed files)"
else
    echo "Mode: install (skip existing files)"
fi
echo ""

# Hook activation flags. Defaults match the plugin's historical behavior
# (Auto-Loop + changelog + validator on, Evolving-Loop off/opt-in) so a plain
# `./install.sh` is unaffected. --wizard lets the user override them.
ENABLE_STOP_AUTOLOOP=1
ENABLE_EVOLVING_LOOP=0
ENABLE_CHANGELOG=1
ENABLE_VALIDATOR=1
PROJECT_TYPE="unspecified"

run_setup_wizard() {
    echo "Setup Wizard"
    echo "------------"
    echo ""
    echo "What best describes this project?"
    echo "  1) Web app / API service"
    echo "  2) CLI tool / library"
    echo "  3) Exploring or prototyping"
    echo "  4) Dogfooding Director Mode itself"
    read -r -p "Choice [1-4, default 1]: " proj_choice
    local recommended_auto
    case "$proj_choice" in
        2) PROJECT_TYPE="cli-or-library"; recommended_auto=1 ;;
        3) PROJECT_TYPE="exploring"; recommended_auto=0 ;;
        4) PROJECT_TYPE="dogfooding"; recommended_auto=2 ;;
        *) PROJECT_TYPE="web-or-api"; recommended_auto=1 ;;
    esac
    echo ""

    echo "Automation level (Stop-hook driven continuation):"
    echo "  0) None       - commands/agents/skills only, no autonomous loop"
    echo "  1) Auto-Loop  - TDD red-green-refactor continuation on Stop"
    echo "  2) Auto-Loop + Evolving-Loop - also self-evolve skills across sessions"
    read -r -p "Choice [0-2, default $recommended_auto]: " auto_choice
    auto_choice="${auto_choice:-$recommended_auto}"
    case "$auto_choice" in
        0) ENABLE_STOP_AUTOLOOP=0; ENABLE_EVOLVING_LOOP=0 ;;
        2) ENABLE_STOP_AUTOLOOP=1; ENABLE_EVOLVING_LOOP=1 ;;
        *) ENABLE_STOP_AUTOLOOP=1; ENABLE_EVOLVING_LOOP=0 ;;
    esac
    echo ""

    read -r -p "Enable changelog + pre-write safety hooks? [Y/n]: " obs_choice
    case "$obs_choice" in
        [Nn]*) ENABLE_CHANGELOG=0; ENABLE_VALIDATOR=0 ;;
        *) ENABLE_CHANGELOG=1; ENABLE_VALIDATOR=1 ;;
    esac
    echo ""
}

if [[ $WIZARD_MODE -eq 1 ]]; then
    # DML_WIZARD_FORCE lets tests feed prompt answers over a piped stdin,
    # where -t 0 is false even though a script deliberately provided answers.
    if [[ -t 0 || -n "${DML_WIZARD_FORCE:-}" ]]; then
        run_setup_wizard
    else
        echo "Warning: --wizard requires an interactive terminal (no TTY on stdin)."
        echo "  Falling back to defaults (Auto-Loop + changelog + validator enabled)."
        echo ""
    fi
fi

# Check dependencies
MISSING_DEPS=0
if ! command -v python3 &>/dev/null; then
    echo "Warning: python3 not found. Hook configuration will be skipped."
    echo "  Install: brew install python3 (macOS) or apt install python3 (Linux)"
    MISSING_DEPS=1
fi
if ! command -v jq &>/dev/null; then
    echo "Warning: jq not found. Some hooks may not work correctly."
    echo "  Install: brew install jq (macOS) or apt install jq (Linux)"
    MISSING_DEPS=1
fi
if [[ $MISSING_DEPS -gt 0 ]]; then
    echo ""
fi

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

# Copy agents (skip existing, or overwrite in --update mode)
echo "Installing agents..."
mkdir -p "$TARGET_DIR/.claude/agents"
for file in "$SCRIPT_DIR/agents/"*.md; do
    if [[ -f "$file" ]]; then
        filename=$(basename "$file")
        if [[ -f "$TARGET_DIR/.claude/agents/$filename" ]]; then
            if [[ $UPDATE_MODE -eq 1 ]]; then
                cp -f "$file" "$TARGET_DIR/.claude/agents/"
                echo "  Updated: agents/$filename"
            else
                echo "  Skipped (exists): agents/$filename"
            fi
        else
            cp "$file" "$TARGET_DIR/.claude/agents/"
            echo "  Installed: agents/$filename"
        fi
    fi
done

# Copy skills (skip existing, or overwrite in --update mode)
echo "Installing skills..."
mkdir -p "$TARGET_DIR/.claude/skills"
for dir in "$SCRIPT_DIR/skills/"*/; do
    if [[ -d "$dir" ]]; then
        dirname=$(basename "$dir")
        if [[ -d "$TARGET_DIR/.claude/skills/$dirname" ]]; then
            if [[ $UPDATE_MODE -eq 1 ]]; then
                rm -rf "$TARGET_DIR/.claude/skills/$dirname"
                cp -r "${dir%/}" "$TARGET_DIR/.claude/skills/"
                echo "  Updated: skills/$dirname/"
            else
                echo "  Skipped (exists): skills/$dirname/"
            fi
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
        cp -f "$SCRIPT_DIR/hooks/$hook" "$TARGET_DIR/.claude/hooks/"
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
if TARGET_DIR="$TARGET_DIR" SCRIPT_DIR="$SCRIPT_DIR" \
   ENABLE_STOP_AUTOLOOP="$ENABLE_STOP_AUTOLOOP" ENABLE_EVOLVING_LOOP="$ENABLE_EVOLVING_LOOP" \
   ENABLE_CHANGELOG="$ENABLE_CHANGELOG" ENABLE_VALIDATOR="$ENABLE_VALIDATOR" \
   python3 -c "
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

existing.setdefault('hooks', {})

enable_stop = os.environ.get('ENABLE_STOP_AUTOLOOP', '1') == '1'
enable_post = os.environ.get('ENABLE_CHANGELOG', '1') == '1'
enable_pre = os.environ.get('ENABLE_VALIDATOR', '1') == '1'
enable_evolving = os.environ.get('ENABLE_EVOLVING_LOOP', '0') == '1'

if enable_stop and 'Stop' in source.get('hooks', {}) and 'Stop' not in existing['hooks']:
    existing['hooks']['Stop'] = source['hooks']['Stop']
    print('  Merged: Stop hook (Auto-Loop TDD continuation)')

if enable_post and 'PostToolUse' in source.get('hooks', {}) and 'PostToolUse' not in existing['hooks']:
    existing['hooks']['PostToolUse'] = source['hooks']['PostToolUse']
    print('  Merged: PostToolUse hooks (changelog)')

if enable_pre and 'PreToolUse' in source.get('hooks', {}) and 'PreToolUse' not in existing['hooks']:
    existing['hooks']['PreToolUse'] = source['hooks']['PreToolUse']
    print('  Merged: PreToolUse hooks (file validation)')

# Evolving-Loop hooks ship separately under .self-evolving-loop/ and are only
# merged here when explicitly requested (wizard automation level 2) — see
# the evolving-loop skill's 'Hook-Driven Continuation' section for the
# equivalent manual activation snippet.
if enable_evolving:
    evolving_source_file = os.path.join(os.environ['SCRIPT_DIR'], '.self-evolving-loop', 'hooks', 'settings-hooks.json')
    if os.path.exists(evolving_source_file):
        with open(evolving_source_file, 'r') as f:
            evolving_source = json.load(f)
        merged_any = False
        for event, entries in evolving_source.get('hooks', {}).items():
            existing_list = existing['hooks'].setdefault(event, [])
            for entry in entries:
                if entry not in existing_list:
                    existing_list.append(entry)
                    merged_any = True
        if merged_any:
            print('  Merged: Evolving-Loop hooks (self-evolution continuation)')

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

# Copy .self-evolving-loop scaffolding (evolving-loop hooks + templates, opt-in)
# Only hooks/ and templates/ are distributed; state dirs are created at runtime.
# The Stop hook is only merged into settings.local.json above when
# ENABLE_EVOLVING_LOOP=1 (--wizard automation level 2); otherwise it stays
# opt-in — see the evolving-loop skill's "Hook-Driven Continuation" section
# for the manual activation snippet.
echo "Installing .self-evolving-loop scaffolding..."
SEL_SRC="$SCRIPT_DIR/.self-evolving-loop"
if [[ -d "$SEL_SRC" ]]; then
    for sub in hooks templates; do
        mkdir -p "$TARGET_DIR/.self-evolving-loop/$sub"
        for file in "$SEL_SRC/$sub/"*; do
            [[ -f "$file" ]] || continue
            filename=$(basename "$file")
            dest="$TARGET_DIR/.self-evolving-loop/$sub/$filename"
            if [[ -f "$dest" ]] && [[ $UPDATE_MODE -eq 0 ]]; then
                echo "  Skipped (exists): .self-evolving-loop/$sub/$filename"
            else
                if [[ -f "$dest" ]]; then
                    cp -f "$file" "$dest"
                    echo "  Updated: .self-evolving-loop/$sub/$filename"
                else
                    cp "$file" "$dest"
                    echo "  Installed: .self-evolving-loop/$sub/$filename"
                fi
                if [[ "$filename" == *.sh ]]; then
                    chmod +x "$dest"
                fi
            fi
        done
    done
fi

# Copy CLAUDE.md template (if target doesn't have one)
if [[ ! -f "$TARGET_DIR/CLAUDE.md" ]] && [[ -f "$SCRIPT_DIR/docs/CLAUDE-TEMPLATE.md" ]]; then
    echo "Copying CLAUDE.md template..."
    cp "$SCRIPT_DIR/docs/CLAUDE-TEMPLATE.md" "$TARGET_DIR/CLAUDE.md"
fi

echo ""
if [[ $UPDATE_MODE -eq 1 ]]; then
    echo "Update complete!"
else
    echo "Installation complete!"
fi
echo ""
echo "Installed:"
echo "  - .claude/skills/       (27 slash commands + 5 internal skills = 32 total)"
echo "  - .claude/agents/       (14 specialized agents)"
echo "  - .claude/hooks/        (5 hooks: Auto-Loop, Changelog, Validator)"
echo "  - .self-evolving-loop/  (evolving-loop scaffolding: hooks + templates, opt-in)"
echo ""
echo "Automation active in settings.local.json:"
if [[ $ENABLE_STOP_AUTOLOOP -eq 1 ]]; then
    echo "  - Auto-Loop Stop hook       ON  (TDD continuation)"
else
    echo "  - Auto-Loop Stop hook       off"
fi
if [[ $ENABLE_EVOLVING_LOOP -eq 1 ]]; then
    echo "  - Evolving-Loop Stop hook   ON  (self-evolution continuation)"
else
    echo "  - Evolving-Loop Stop hook   off (opt-in — see /evolving-loop)"
fi
if [[ $ENABLE_CHANGELOG -eq 1 ]]; then
    echo "  - Changelog hooks           ON"
else
    echo "  - Changelog hooks           off"
fi
if [[ $ENABLE_VALIDATOR -eq 1 ]]; then
    echo "  - Pre-write validator hook  ON"
else
    echo "  - Pre-write validator hook  off"
fi
if [[ $WIZARD_MODE -eq 1 && -t 0 ]]; then
    echo "  (project type: $PROJECT_TYPE — re-run ./install.sh --update --wizard anytime to change)"
fi
echo ""
if [[ -d "$BACKUP_DIR" ]]; then
    echo "Backup location: $BACKUP_DIR"
    echo ""
fi
echo "Get started:"
echo "  cd $TARGET_DIR"
echo "  claude"
echo "  /getting-started    # Guided 5-minute onboarding"
echo ""
echo "Or jump right in:"
echo "  /project-init       # Auto-detect project and configure"
echo "  /workflow            # Start developing with 5-step flow"
echo ""
