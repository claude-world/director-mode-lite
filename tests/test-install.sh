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

# Test: Uses absolute paths in settings
test_absolute_paths() {
    echo "Test: Uses absolute paths in settings"
    setup

    "$PROJECT_ROOT/install.sh" "$TEST_DIR" > /dev/null 2>&1

    if command -v jq &>/dev/null; then
        local hook_path=$(jq -r '.hooks.Stop[0].hooks[0].command // empty' "$TEST_DIR/.claude/settings.local.json")
        assert "Hook path is absolute" "[[ '$hook_path' == /* ]]"
        assert "Hook path contains target dir" "[[ '$hook_path' == *'$TEST_DIR'* ]]"
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

    # Modify an agent file
    echo "# Modified" >> "$TEST_DIR/.claude/agents/code-reviewer.md"
    local original_content=$(cat "$TEST_DIR/.claude/agents/code-reviewer.md")

    # Second install
    "$PROJECT_ROOT/install.sh" "$TEST_DIR" > /dev/null 2>&1

    # Check file was not overwritten
    local new_content=$(cat "$TEST_DIR/.claude/agents/code-reviewer.md")
    assert "Existing files not overwritten" "[[ '$original_content' == '$new_content' ]]"

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
test_absolute_paths
echo ""
test_backup_existing
echo ""
test_skip_existing
echo ""

# Exit with status
if [[ $FAILURES -gt 0 ]]; then
    echo -e "${RED}$FAILURES assertion(s) failed${NC}"
    exit 1
else
    echo -e "${GREEN}All assertions passed${NC}"
    exit 0
fi
