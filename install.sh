#!/bin/bash
# Director Mode Lite - Installation Script
# Guidance-first installation with native Claude Code, Codex, and Grok adapters.
#
# Usage: ./install.sh [--update] [--wizard] [--cli all|claude|codex|grok]
#                     [--hooks guide|none|automation] [target-dir]
#   --update   Overwrite distributed files (agents/skills/hooks + .self-evolving-loop
#              scaffolding) instead of skipping existing ones. CLAUDE.md is never
#              overwritten. target-dir defaults to the current directory.
#   --cli      Install native adapters for one CLI or all three (default: all).
#   --hooks    none (zero-interference default), guide (non-blocking Claude /
#              Codex context), or automation (legacy blocking Claude hooks,
#              explicit opt-in). Default: none.
#   --no-hooks Alias for --hooks none.
#   --wizard   Interactive CLI and guidance setup. Requires a TTY; otherwise
#              falls back to the guidance-first defaults.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse flags + optional target dir.
UPDATE_MODE=0
WIZARD_MODE=0
CLI_TARGETS="all"
HOOK_MODE="none"
TARGET_DIR="."
_target_set=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        --update)
            UPDATE_MODE=1
            ;;
        --wizard)
            WIZARD_MODE=1
            ;;
        --cli)
            [[ $# -ge 2 ]] || { echo "Error: --cli requires a value" >&2; exit 2; }
            CLI_TARGETS="$2"
            shift
            ;;
        --cli=*)
            CLI_TARGETS="${1#*=}"
            ;;
        --hooks)
            [[ $# -ge 2 ]] || { echo "Error: --hooks requires a value" >&2; exit 2; }
            HOOK_MODE="$2"
            shift
            ;;
        --hooks=*)
            HOOK_MODE="${1#*=}"
            ;;
        --no-hooks)
            HOOK_MODE="none"
            ;;
        -h|--help)
            sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        --*)
            echo "Error: unknown option: $1" >&2
            exit 2
            ;;
        *)
            if [[ $_target_set -eq 0 ]]; then
                TARGET_DIR="$1"
                _target_set=1
            else
                echo "Error: only one target directory may be provided" >&2
                exit 2
            fi
            ;;
    esac
    shift
done

case "$CLI_TARGETS" in
    all|claude|codex|grok) ;;
    *) echo "Error: --cli must be all, claude, codex, or grok" >&2; exit 2 ;;
esac
case "$HOOK_MODE" in
    guide|none|automation) ;;
    *) echo "Error: --hooks must be guide, none, or automation" >&2; exit 2 ;;
esac

BACKUP_DIR="$TARGET_DIR/.claude-backup-$(date +%Y%m%d-%H%M%S)"

echo "Director Mode Lite Installer"
echo "============================"
if [[ $UPDATE_MODE -eq 1 ]]; then
    echo "Mode: update (overwrite distributed files)"
else
    echo "Mode: install (skip existing files)"
fi
echo "CLIs: $CLI_TARGETS"
echo "Hooks: $HOOK_MODE"
echo ""

# Shared files are the default; active hooks are not. Legacy Stop-hook
# automation remains available only through an explicit choice.
ENABLE_STOP_AUTOLOOP=0
ENABLE_EVOLVING_LOOP=0
ENABLE_CHANGELOG=0
ENABLE_VALIDATOR=0
PROJECT_TYPE="unspecified"

if [[ "$HOOK_MODE" == "automation" ]]; then
    ENABLE_STOP_AUTOLOOP=1
    ENABLE_CHANGELOG=1
    ENABLE_VALIDATOR=1
fi

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
    case "$proj_choice" in
        2) PROJECT_TYPE="cli-or-library" ;;
        3) PROJECT_TYPE="exploring" ;;
        4) PROJECT_TYPE="dogfooding" ;;
        *) PROJECT_TYPE="web-or-api" ;;
    esac
    echo ""

    echo "Which CLI adapters should be installed?"
    echo "  1) Claude Code + Codex CLI + Grok Build (recommended)"
    echo "  2) Claude Code"
    echo "  3) Codex CLI"
    echo "  4) Grok Build"
    read -r -p "Choice [1-4, default 1]: " cli_choice
    case "$cli_choice" in
        2) CLI_TARGETS="claude" ;;
        3) CLI_TARGETS="codex" ;;
        4) CLI_TARGETS="grok" ;;
        *) CLI_TARGETS="all" ;;
    esac
    echo ""

    echo "Setup style:"
    echo "  1) Guidance only, no active hooks (recommended; zero interference)"
    echo "  2) Add a non-blocking SessionStart context hook for Claude/Codex"
    echo "  3) Legacy Claude automation (blocking Stop hook; explicit opt-in)"
    read -r -p "Choice [1-3, default 1]: " mode_choice
    case "$mode_choice" in
        2)
            HOOK_MODE="guide"
            ;;
        3)
            HOOK_MODE="automation"
            ENABLE_STOP_AUTOLOOP=1
            ENABLE_CHANGELOG=1
            ENABLE_VALIDATOR=1
            ;;
        *)
            HOOK_MODE="none"
            ENABLE_STOP_AUTOLOOP=0
            ENABLE_CHANGELOG=0
            ENABLE_VALIDATOR=0
            ;;
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
        echo "  Falling back to zero-hook guidance for all three CLIs."
        echo ""
    fi
fi

# Check dependencies
MISSING_DEPS=0
if ! command -v python3 &>/dev/null; then
    echo "Error: python3 is required for native adapters and the session relay."
    echo "  Install: brew install python3 (macOS) or apt install python3 (Linux)"
    exit 1
fi
if [[ "$HOOK_MODE" == "automation" ]] && ! command -v jq &>/dev/null; then
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

# Snapshot which package paths already exist. Complete uninstall later removes
# only files this installation actually created and that remain unmodified.
python3 "$SCRIPT_DIR/scripts/install-ownership.py" begin \
    --source "$SCRIPT_DIR" \
    --target "$TARGET_DIR" \
    --cli "$CLI_TARGETS" \
    --hooks "$HOOK_MODE"

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

# Legacy hook automation is intentionally absent from a guidance-first install.
# The portable installer below owns the optional advisory hook.
if [[ "$HOOK_MODE" == "automation" ]]; then
echo "Installing legacy Claude automation hooks..."
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
else
    echo "Skipping legacy Auto-Loop, changelog, validator, and evolving-loop hooks."
fi

# Copy CLAUDE.md template (if target doesn't have one)
if [[ ! -f "$TARGET_DIR/CLAUDE.md" ]] && [[ -f "$SCRIPT_DIR/docs/CLAUDE-TEMPLATE.md" ]]; then
    echo "Copying CLAUDE.md template..."
    cp "$SCRIPT_DIR/docs/CLAUDE-TEMPLATE.md" "$TARGET_DIR/CLAUDE.md"
fi

# Install the shared guidance, portable relay, and native adapters. Optional
# guide hooks are registered only for CLIs that can consume their context.
PORTABLE_ARGS=(
    --source "$SCRIPT_DIR"
    --target "$TARGET_DIR"
    --cli "$CLI_TARGETS"
    --hooks "$HOOK_MODE"
)
if [[ $UPDATE_MODE -eq 1 ]]; then
    PORTABLE_ARGS+=(--update)
fi
echo "Installing cross-CLI guidance and adapters..."
python3 "$SCRIPT_DIR/scripts/install-portable.py" "${PORTABLE_ARGS[@]}"
python3 "$SCRIPT_DIR/scripts/install-ownership.py" finalize --target "$TARGET_DIR"

echo ""
if [[ $UPDATE_MODE -eq 1 ]]; then
    echo "Update complete!"
else
    echo "Installation complete!"
fi
echo ""
echo "Installed:"
echo "  - .director-mode/       (shared guidance + portable session relay)"
echo "  - director-open         (native full-capability launcher)"
echo "  - .claude/skills/       (Claude Code + Grok-compatible skills)"
echo "  - .claude/agents/       (14 specialized agents)"
if [[ "$CLI_TARGETS" == "all" || "$CLI_TARGETS" == "codex" ]]; then
    echo "  - .agents/skills/       (Codex-compatible shared skills)"
    echo "  - .codex/agents/        (14 generated Codex agent adapters)"
fi
if [[ "$CLI_TARGETS" == "all" || "$CLI_TARGETS" == "grok" ]]; then
    echo "  - .grok/agents/         (14 generated Grok agent adapters)"
fi
echo ""
echo "Guidance and automation:"
if [[ "$HOOK_MODE" == "guide" ]]; then
    echo "  - Claude/Codex context hook ON  (never denies; no Grok inert hook)"
elif [[ "$HOOK_MODE" == "none" ]]; then
    echo "  - Active hooks              off (zero-interference default)"
fi
if [[ $ENABLE_STOP_AUTOLOOP -eq 1 ]]; then
    echo "  - Legacy Auto-Loop hook     ON  (explicit opt-in)"
else
    echo "  - Legacy Auto-Loop hook     off"
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
echo "  claude | codex | grok"
echo "  .director-mode/bin/director-open claude|codex|grok  # trusted full access"
echo "  Read .director-mode/GUIDANCE.md"
echo "  Use the director-mode or session-relay skill"
echo ""
