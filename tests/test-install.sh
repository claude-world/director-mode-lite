#!/bin/bash
# Test: install.sh functionality
# Verifies that the installation script works correctly

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Test directory
TEST_DIR="/tmp/director-mode-test-$$"
FAILURES=0

# Setup
setup() {
    rm -rf "$TEST_DIR"
    mkdir -p "$TEST_DIR"
}

# Teardown
teardown() {
    rm -rf "$TEST_DIR"
}

# Assert helper
assert() {
    local description="$1"
    local condition="$2"

    if eval "$condition"; then
        echo -e "  ${GREEN}✓${NC} $description"
    else
        echo -e "  ${RED}✗${NC} $description"
        ((FAILURES++))
    fi
}

# Test: Install creates .claude directory
test_creates_claude_dir() {
    echo "Test: Creates .claude directory"
    setup

    "$PROJECT_ROOT/install.sh" "$TEST_DIR" > /dev/null 2>&1

    assert ".claude directory exists" "[[ -d '$TEST_DIR/.claude' ]]"
    assert ".claude/agents exists" "[[ -d '$TEST_DIR/.claude/agents' ]]"
    assert ".claude/skills exists" "[[ -d '$TEST_DIR/.claude/skills' ]]"
    assert ".claude/hooks exists" "[[ -d '$TEST_DIR/.claude/hooks' ]]"

    teardown
}

# Test: Installs hook scripts
test_installs_hooks() {
    echo "Test: Installs hook scripts"
    setup

    "$PROJECT_ROOT/install.sh" "$TEST_DIR" > /dev/null 2>&1

    assert "_lib-changelog.sh exists" "[[ -f '$TEST_DIR/.claude/hooks/_lib-changelog.sh' ]]"
    assert "auto-loop-stop.sh exists" "[[ -f '$TEST_DIR/.claude/hooks/auto-loop-stop.sh' ]]"
    assert "log-file-change.sh exists" "[[ -f '$TEST_DIR/.claude/hooks/log-file-change.sh' ]]"
    assert "log-bash-event.sh exists" "[[ -f '$TEST_DIR/.claude/hooks/log-bash-event.sh' ]]"
    assert "pre-tool-validator.sh exists" "[[ -f '$TEST_DIR/.claude/hooks/pre-tool-validator.sh' ]]"
    assert "auto-loop-stop.sh is executable" "[[ -x '$TEST_DIR/.claude/hooks/auto-loop-stop.sh' ]]"

    teardown
}

# Test: Creates settings.local.json
test_creates_settings() {
    echo "Test: Creates settings.local.json"
    setup

    "$PROJECT_ROOT/install.sh" "$TEST_DIR" > /dev/null 2>&1

    assert "settings.local.json exists" "[[ -f '$TEST_DIR/.claude/settings.local.json' ]]"

    # Check JSON structure
    if command -v jq &>/dev/null; then
        assert "Has hooks section" "jq -e '.hooks' '$TEST_DIR/.claude/settings.local.json' > /dev/null 2>&1"
        assert "Has Stop hooks" "jq -e '.hooks.Stop' '$TEST_DIR/.claude/settings.local.json' > /dev/null 2>&1"
        assert "Has plansDirectory" "jq -e '.plansDirectory' '$TEST_DIR/.claude/settings.local.json' > /dev/null 2>&1"
    fi

    teardown
}

# Test: Uses $CLAUDE_PROJECT_DIR in settings
test_portable_paths() {
    echo "Test: Uses \$CLAUDE_PROJECT_DIR in settings"
    setup

    "$PROJECT_ROOT/install.sh" "$TEST_DIR" > /dev/null 2>&1

    if command -v jq &>/dev/null; then
        local hook_path=$(jq -r '.hooks.Stop[0].hooks[0].command // empty' "$TEST_DIR/.claude/settings.local.json")
        assert "Hook path uses CLAUDE_PROJECT_DIR" "[[ '$hook_path' == *'CLAUDE_PROJECT_DIR'* ]]"
        assert "Hook path has .claude/hooks" "[[ '$hook_path' == *'.claude/hooks/'* ]]"
    fi

    teardown
}

# Test: Backup existing .claude
test_backup_existing() {
    echo "Test: Backup existing .claude"
    setup

    # Create existing .claude with content
    mkdir -p "$TEST_DIR/.claude"
    echo "existing content" > "$TEST_DIR/.claude/test-file.txt"

    "$PROJECT_ROOT/install.sh" "$TEST_DIR" > /dev/null 2>&1

    # Check backup was created
    local backup_count=$(ls -d "$TEST_DIR"/.claude-backup-* 2>/dev/null | wc -l)
    assert "Backup directory created" "[[ $backup_count -gt 0 ]]"

    # Check backup has content
    if [[ $backup_count -gt 0 ]]; then
        local backup_dir=$(ls -d "$TEST_DIR"/.claude-backup-* | head -1)
        assert "Backup contains original file" "[[ -f '$backup_dir/test-file.txt' ]]"
    fi

    teardown
}

# Test: Skip existing files
test_skip_existing() {
    echo "Test: Skip existing files"
    setup

    # First install
    "$PROJECT_ROOT/install.sh" "$TEST_DIR" > /dev/null 2>&1

    # Modify an agent file, then snapshot it. Compare via files (diff), not by
    # embedding content into the assert condition — agent files may contain
    # quotes/apostrophes that would break an inline [[ '...' == '...' ]] eval.
    echo "# Modified" >> "$TEST_DIR/.claude/agents/code-reviewer.md"
    cp "$TEST_DIR/.claude/agents/code-reviewer.md" "$TEST_DIR/skip-snapshot.md"

    # Second install (default mode: should skip existing files)
    "$PROJECT_ROOT/install.sh" "$TEST_DIR" > /dev/null 2>&1

    # Check file was not overwritten (still matches the modified snapshot)
    assert "Existing files not overwritten" "diff -q '$TEST_DIR/skip-snapshot.md' '$TEST_DIR/.claude/agents/code-reviewer.md' > /dev/null 2>&1"

    teardown
}

# Test: Installs .self-evolving-loop scaffolding
test_installs_evolving_scaffolding() {
    echo "Test: Installs .self-evolving-loop scaffolding"
    setup

    "$PROJECT_ROOT/install.sh" "$TEST_DIR" > /dev/null 2>&1

    assert "continue-loop.sh exists" "[[ -f '$TEST_DIR/.self-evolving-loop/hooks/continue-loop.sh' ]]"
    assert "continue-loop.sh is executable" "[[ -x '$TEST_DIR/.self-evolving-loop/hooks/continue-loop.sh' ]]"
    assert "executor-template.md exists" "[[ -f '$TEST_DIR/.self-evolving-loop/templates/executor-template.md' ]]"

    teardown
}

# Test: --update overwrites modified files
test_update_overwrites() {
    echo "Test: --update overwrites modified files"
    setup

    # First install
    "$PROJECT_ROOT/install.sh" "$TEST_DIR" > /dev/null 2>&1

    # Modify an installed skill file
    local skill_file="$TEST_DIR/.claude/skills/evolving-loop/SKILL.md"
    echo "# LOCAL MODIFICATION" >> "$skill_file"

    # Re-run in update mode
    "$PROJECT_ROOT/install.sh" --update "$TEST_DIR" > /dev/null 2>&1

    # File should be restored to distributed content (matches source, modification gone)
    assert "Update restored skill to distributed content" "diff -q '$PROJECT_ROOT/skills/evolving-loop/SKILL.md' '$skill_file' > /dev/null 2>&1"

    teardown
}

# Run all tests
echo ""
test_creates_claude_dir
echo ""
test_installs_hooks
echo ""
test_creates_settings
echo ""
test_portable_paths
echo ""
test_backup_existing
echo ""
test_skip_existing
echo ""
test_installs_evolving_scaffolding
echo ""
test_update_overwrites
echo ""

# Exit with status
if [[ $FAILURES -gt 0 ]]; then
    echo -e "${RED}$FAILURES assertion(s) failed${NC}"
    exit 1
else
    echo -e "${GREEN}All assertions passed${NC}"
    exit 0
fi
