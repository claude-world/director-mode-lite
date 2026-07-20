#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TARGET_DIR="."
TARGET_SET=0
ALLOW_NO_HOOKS=0
FAILURES=0
SETTINGS_JSON_VALID=0

EXPECTED_SKILLS=32
EXPECTED_COMMANDS=27
EXPECTED_AGENTS=14

usage() {
    cat <<'EOF'
Usage: verify-install.sh [--allow-no-hooks] [target-dir]

Verify a project-local Director Mode Lite installation.

  --allow-no-hooks  Verify an intentionally hook-free wizard setup. Hook files,
                    hook dependencies, settings, and registrations are skipped.
EOF
}

for arg in "$@"; do
    case "$arg" in
        --allow-no-hooks)
            ALLOW_NO_HOOKS=1
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            echo "Unknown option: $arg" >&2
            usage >&2
            exit 2
            ;;
        *)
            if [[ $TARGET_SET -eq 1 ]]; then
                echo "Only one target directory may be provided." >&2
                usage >&2
                exit 2
            fi
            TARGET_DIR="$arg"
            TARGET_SET=1
            ;;
    esac
done

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

pass() {
    printf "%bPASS%b %s\n" "$GREEN" "$NC" "$1"
}

fail() {
    printf "%bFAIL%b %s\n" "$RED" "$NC" "$1"
    FAILURES=$((FAILURES + 1))
}

check_file() {
    local path="$1"
    local label="$2"

    if [[ -f "$path" ]]; then
        pass "$label"
    else
        fail "$label ($path missing)"
    fi
}

check_dir() {
    local path="$1"
    local label="$2"

    if [[ -d "$path" ]]; then
        pass "$label"
    else
        fail "$label ($path missing)"
    fi
}

check_command() {
    local command_name="$1"
    local label="$2"

    if command -v "$command_name" > /dev/null 2>&1; then
        pass "$label"
    else
        fail "$label ($command_name not found on PATH)"
    fi
}

check_executable() {
    local path="$1"
    local label="$2"

    if [[ -x "$path" && -f "$path" ]]; then
        pass "$label"
    elif [[ -f "$path" ]]; then
        fail "$label ($path is not executable)"
    else
        fail "$label ($path missing)"
    fi
}

check_inventory() {
    local source_skill_dirs=()
    local source_agent_files=()
    local missing_skills=()
    local missing_commands=()
    local missing_agents=()
    local source_command_count=0
    local source_skill
    local source_agent
    local name

    shopt -s nullglob
    source_skill_dirs=("$PROJECT_ROOT"/skills/*)
    source_agent_files=("$PROJECT_ROOT"/agents/*.md)
    shopt -u nullglob

    if [[ ${#source_skill_dirs[@]} -eq $EXPECTED_SKILLS ]]; then
        pass "Verifier source inventory has $EXPECTED_SKILLS skills"
    else
        fail "Verifier source inventory has $EXPECTED_SKILLS skills (found ${#source_skill_dirs[@]})"
    fi

    for source_skill in "${source_skill_dirs[@]}"; do
        [[ -d "$source_skill" ]] || continue
        name="$(basename "$source_skill")"
        if [[ ! -f "$TARGET_DIR/.claude/skills/$name/SKILL.md" ]]; then
            missing_skills+=("$name")
        fi

        if grep -Eq '^user-invocable:[[:space:]]*true[[:space:]]*$' "$source_skill/SKILL.md"; then
            source_command_count=$((source_command_count + 1))
            if [[ ! -f "$TARGET_DIR/.claude/skills/$name/SKILL.md" ]] || \
               ! grep -Eq '^user-invocable:[[:space:]]*true[[:space:]]*$' "$TARGET_DIR/.claude/skills/$name/SKILL.md"; then
                missing_commands+=("$name")
            fi
        fi
    done

    if [[ ${#missing_skills[@]} -eq 0 ]]; then
        pass "$EXPECTED_SKILLS shipped skills present"
    else
        fail "$EXPECTED_SKILLS shipped skills present (missing: ${missing_skills[*]})"
    fi

    if [[ $source_command_count -ne $EXPECTED_COMMANDS ]]; then
        fail "Verifier source inventory has $EXPECTED_COMMANDS user-invocable commands (found $source_command_count)"
    elif [[ ${#missing_commands[@]} -eq 0 ]]; then
        pass "$EXPECTED_COMMANDS user-invocable commands present"
    else
        fail "$EXPECTED_COMMANDS user-invocable commands present (missing or not invocable: ${missing_commands[*]})"
    fi

    if [[ ${#source_agent_files[@]} -eq $EXPECTED_AGENTS ]]; then
        pass "Verifier source inventory has $EXPECTED_AGENTS agents"
    else
        fail "Verifier source inventory has $EXPECTED_AGENTS agents (found ${#source_agent_files[@]})"
    fi

    for source_agent in "${source_agent_files[@]}"; do
        name="$(basename "$source_agent")"
        if [[ ! -f "$TARGET_DIR/.claude/agents/$name" ]]; then
            missing_agents+=("$name")
        fi
    done

    if [[ ${#missing_agents[@]} -eq 0 ]]; then
        pass "$EXPECTED_AGENTS shipped agents present"
    else
        fail "$EXPECTED_AGENTS shipped agents present (missing: ${missing_agents[*]})"
    fi
}

check_settings_json() {
    local settings_file="$TARGET_DIR/.claude/settings.local.json"

    if [[ ! -f "$settings_file" ]]; then
        fail "settings.local.json is valid JSON ($settings_file missing)"
        return
    fi

    if ! command -v python3 > /dev/null 2>&1; then
        fail "settings.local.json is valid JSON (python3 is unavailable)"
        return
    fi

    if SETTINGS_FILE="$settings_file" python3 - <<'PYEOF' > /dev/null 2>&1
import json
import os

with open(os.environ["SETTINGS_FILE"]) as handle:
    settings = json.load(handle)

if not isinstance(settings, dict):
    raise TypeError("settings root must be an object")
PYEOF
    then
        SETTINGS_JSON_VALID=1
        pass "settings.local.json is valid JSON"
    else
        fail "settings.local.json is valid JSON"
    fi
}

check_hook_registration() {
    local settings_file="$TARGET_DIR/.claude/settings.local.json"
    local registered_hooks

    [[ $SETTINGS_JSON_VALID -eq 1 ]] || return

    if registered_hooks="$(SETTINGS_FILE="$settings_file" python3 - <<'PYEOF'
import json
import os
import sys

known_scripts = {
    "auto-loop-stop.sh",
    "log-bash-event.sh",
    "log-file-change.sh",
    "pre-tool-validator.sh",
    "continue-loop.sh",
    "log-event.sh",
    "phase-tracker.sh",
}

with open(os.environ["SETTINGS_FILE"]) as handle:
    settings = json.load(handle)

found = set()

def walk(node):
    if isinstance(node, dict):
        command = node.get("command")
        if isinstance(command, str):
            for script in known_scripts:
                if script in command:
                    found.add(script)
        for value in node.values():
            walk(value)
    elif isinstance(node, list):
        for value in node:
            walk(value)

walk(settings.get("hooks", {}))
if not found:
    sys.exit(1)

print(", ".join(sorted(found)))
PYEOF
)"; then
        pass "settings contains a registered DML hook ($registered_hooks)"
    elif [[ $ALLOW_NO_HOOKS -eq 1 ]]; then
        pass "No registered DML hook required (--allow-no-hooks)"
    else
        fail "settings contains a registered DML hook"
    fi
}

if [[ ! -d "$TARGET_DIR" ]]; then
    fail "Target directory exists ($TARGET_DIR)"
    printf "\n"
    printf "%bInstallation verification failed%b\n" "$RED" "$NC"
    exit 1
fi

printf "Verifying Director Mode Lite install in %s\n\n" "$TARGET_DIR"

check_file "$TARGET_DIR/CLAUDE.md" "CLAUDE.md exists (custom project structure is allowed)"
check_dir "$TARGET_DIR/.claude" ".claude directory exists"
check_dir "$TARGET_DIR/.claude/agents" ".claude/agents directory exists"
check_dir "$TARGET_DIR/.claude/skills" ".claude/skills directory exists"

check_inventory

if [[ $ALLOW_NO_HOOKS -eq 1 ]]; then
    pass "Hook files, dependencies, settings, and registrations skipped (--allow-no-hooks)"
else
    check_command "python3" "python3 hook dependency is available"
    check_command "jq" "jq hook dependency is available"

    check_dir "$TARGET_DIR/.claude/hooks" ".claude/hooks directory exists"
    check_dir "$TARGET_DIR/.self-evolving-loop/hooks" ".self-evolving-loop/hooks directory exists"

    for hook in \
        _lib-changelog.sh \
        auto-loop-stop.sh \
        log-bash-event.sh \
        log-file-change.sh \
        pre-tool-validator.sh; do
        check_executable "$TARGET_DIR/.claude/hooks/$hook" "$hook is executable"
    done

    for hook in continue-loop.sh log-event.sh phase-tracker.sh; do
        check_executable "$TARGET_DIR/.self-evolving-loop/hooks/$hook" "$hook is executable"
    done

    check_settings_json
    check_hook_registration
fi

printf "\n"
if [[ $FAILURES -eq 0 ]]; then
    printf "%bInstallation verification passed%b\n" "$GREEN" "$NC"
    exit 0
fi

printf "%bInstallation verification failed (%d check(s))%b\n" "$RED" "$FAILURES" "$NC"
exit 1
