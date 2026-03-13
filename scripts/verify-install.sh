#!/usr/bin/env bash

set -u

TARGET_DIR="${1:-.}"
FAILURES=0

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

check_contains() {
    local file_path="$1"
    local pattern="$2"
    local label="$3"

    if [[ -f "$file_path" ]] && grep -Fq "$pattern" "$file_path"; then
        pass "$label"
    else
        fail "$label"
    fi
}

check_dir_has_content() {
    local dir_path="$1"
    local label="$2"
    local entries=()

    shopt -s nullglob
    entries=("$dir_path"/*)
    shopt -u nullglob

    if (( ${#entries[@]} > 0 )); then
        pass "$label"
    else
        fail "$label"
    fi
}

if [[ ! -d "$TARGET_DIR" ]]; then
    fail "Target directory exists ($TARGET_DIR)"
    printf "\n"
    printf "%bInstallation verification failed%b\n" "$RED" "$NC"
    exit 1
fi

printf "Verifying Director Mode Lite install in %s\n\n" "$TARGET_DIR"

check_file "$TARGET_DIR/CLAUDE.md" "CLAUDE.md exists"
check_dir "$TARGET_DIR/.claude" ".claude directory exists"
check_dir "$TARGET_DIR/.claude/agents" ".claude/agents directory exists"
check_dir "$TARGET_DIR/.claude/skills" ".claude/skills directory exists"
check_dir "$TARGET_DIR/.claude/hooks" ".claude/hooks directory exists"
check_file "$TARGET_DIR/.claude/settings.local.json" "settings.local.json exists"
check_file "$TARGET_DIR/.claude/hooks/auto-loop-stop.sh" "auto-loop-stop hook exists"

check_file "$TARGET_DIR/.claude/agents/code-reviewer.md" "Key agent exists: code-reviewer"
check_file "$TARGET_DIR/.claude/agents/debugger.md" "Key agent exists: debugger"
check_file "$TARGET_DIR/.claude/agents/doc-writer.md" "Key agent exists: doc-writer"

check_file "$TARGET_DIR/.claude/skills/workflow/SKILL.md" "Key skill exists: workflow"
check_file "$TARGET_DIR/.claude/skills/test-first/SKILL.md" "Key skill exists: test-first"
check_file "$TARGET_DIR/.claude/skills/plan/SKILL.md" "Key skill exists: plan"

check_contains "$TARGET_DIR/CLAUDE.md" "## Project Overview" "CLAUDE.md contains: Project Overview"
check_contains "$TARGET_DIR/CLAUDE.md" "## Directory Structure" "CLAUDE.md contains: Directory Structure"
check_contains "$TARGET_DIR/CLAUDE.md" "## Core Policies" "CLAUDE.md contains: Core Policies"
check_contains "$TARGET_DIR/CLAUDE.md" "## Code Standards" "CLAUDE.md contains: Code Standards"
check_contains "$TARGET_DIR/CLAUDE.md" "## Project-Specific Rules" "CLAUDE.md contains: Project-Specific Rules"
check_contains "$TARGET_DIR/CLAUDE.md" "## Forbidden Actions" "CLAUDE.md contains: Forbidden Actions"
check_contains "$TARGET_DIR/CLAUDE.md" "## Quick Reference" "CLAUDE.md contains: Quick Reference"
check_contains "$TARGET_DIR/CLAUDE.md" "## Notes" "CLAUDE.md contains: Notes"

check_dir_has_content "$TARGET_DIR/.claude/skills" ".claude/skills has content"
check_dir_has_content "$TARGET_DIR/.claude/agents" ".claude/agents has content"

printf "\n"
if [[ $FAILURES -eq 0 ]]; then
    printf "%bInstallation verification passed%b\n" "$GREEN" "$NC"
    exit 0
fi

printf "%bInstallation verification failed (%d check(s))%b\n" "$RED" "$FAILURES" "$NC"
exit 1
