#!/bin/bash
# Test: Hook scripts functionality
# Verifies that hook scripts work correctly

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
HOOKS_DIR="$PROJECT_ROOT/hooks"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Test directory
TEST_DIR="/tmp/director-mode-hooks-test-$$"
FAILURES=0

# Setup
setup() {
    rm -rf "$TEST_DIR"
    mkdir -p "$TEST_DIR/.director-mode"
    mkdir -p "$TEST_DIR/.claude/hooks"
    cp "$HOOKS_DIR"/*.sh "$TEST_DIR/.claude/hooks/"
    chmod +x "$TEST_DIR/.claude/hooks"/*.sh
    cd "$TEST_DIR"
}

# Teardown
teardown() {
    cd "$PROJECT_ROOT"
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

# Test: _lib-changelog.sh functions
test_changelog_logger() {
    echo "Test: _lib-changelog.sh functions"
    setup

    # Source the logger library
    source "$TEST_DIR/.claude/hooks/_lib-changelog.sh"

    # Test ensure_dir
    ensure_dir
    assert "ensure_dir creates directory" "[[ -d '.director-mode' ]]"

    # Test generate_id
    local id=$(generate_id)
    assert "generate_id returns value" "[[ -n '$id' ]]"
    assert "generate_id starts with evt_" "[[ '$id' == evt_* ]]"

    # Test get_timestamp
    local ts=$(get_timestamp)
    assert "get_timestamp returns value" "[[ -n '$ts' ]]"
    assert "get_timestamp is ISO format" "[[ '$ts' =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T ]]"

    # Test log_event
    log_event "test_event" "Test summary" "test_agent" "[]"
    assert "log_event creates changelog" "[[ -f '.director-mode/changelog.jsonl' ]]"

    # Verify JSON structure
    local last_line=$(tail -1 .director-mode/changelog.jsonl)
    assert "Event has id field" "[[ '$last_line' == *'\"id\":'* ]]"
    assert "Event has event_type field" "[[ '$last_line' == *'\"event_type\":\"test_event\"'* ]]"
    assert "Event has session_id field" "[[ '$last_line' == *'\"session_id\":'* ]]"

    teardown
}

# Test: log-file-change.sh with Write tool
test_log_file_change_write() {
    echo "Test: log-file-change.sh with Write tool"
    setup

    # Simulate PostToolUse input for Write
    local input='{"tool_name":"Write","tool_input":{"file_path":"/test/path/file.ts"}}'

    echo "$input" | "$TEST_DIR/.claude/hooks/log-file-change.sh"

    assert "Changelog file created" "[[ -f '.director-mode/changelog.jsonl' ]]"

    if [[ -f '.director-mode/changelog.jsonl' ]]; then
        local content=$(cat .director-mode/changelog.jsonl)
        assert "Event type is file_write" "[[ '$content' == *'file_write'* ]]"
        assert "File path logged" "[[ '$content' == *'file.ts'* ]]"
    fi

    teardown
}

# Test: log-file-change.sh with Edit tool
test_log_file_change_edit() {
    echo "Test: log-file-change.sh with Edit tool"
    setup

    # Simulate PostToolUse input for Edit
    local input='{"tool_name":"Edit","tool_input":{"file_path":"/test/path/component.tsx"}}'

    echo "$input" | "$TEST_DIR/.claude/hooks/log-file-change.sh"

    assert "Changelog file created" "[[ -f '.director-mode/changelog.jsonl' ]]"

    if [[ -f '.director-mode/changelog.jsonl' ]]; then
        local content=$(cat .director-mode/changelog.jsonl)
        assert "Event type is file_edit" "[[ '$content' == *'file_edit'* ]]"
    fi

    teardown
}

# Test: log-bash-event.sh with test command
test_log_bash_test() {
    echo "Test: log-bash-event.sh with test command"
    setup

    # Simulate test command with pass output
    local input='{"tool_name":"Bash","tool_input":{"command":"npm test"},"tool_output":"5 passing"}'

    echo "$input" | "$TEST_DIR/.claude/hooks/log-bash-event.sh"

    assert "Changelog file created" "[[ -f '.director-mode/changelog.jsonl' ]]"

    if [[ -f '.director-mode/changelog.jsonl' ]]; then
        local content=$(cat .director-mode/changelog.jsonl)
        assert "Event type is test_pass" "[[ '$content' == *'test_pass'* ]]"
    fi

    teardown
}

# Test: log-bash-event.sh with git commit
test_log_bash_commit() {
    echo "Test: log-bash-event.sh with git commit"
    setup

    # Simulate git commit
    local input='{"tool_name":"Bash","tool_input":{"command":"git commit -m \"feat: add feature\""},"tool_output":"[main abc1234] feat: add feature"}'

    echo "$input" | "$TEST_DIR/.claude/hooks/log-bash-event.sh"

    assert "Changelog file created" "[[ -f '.director-mode/changelog.jsonl' ]]"

    if [[ -f '.director-mode/changelog.jsonl' ]]; then
        local content=$(cat .director-mode/changelog.jsonl)
        assert "Event type is commit" "[[ '$content' == *'\"event_type\":\"commit\"'* ]]"
    fi

    teardown
}

# Test: pre-tool-validator.sh with .env file
test_pre_tool_validator_env() {
    echo "Test: pre-tool-validator.sh with .env file"
    setup

    # Simulate Write to .env
    local input='{"tool_name":"Write","tool_input":{"file_path":"/project/.env"}}'

    local output=$(echo "$input" | "$TEST_DIR/.claude/hooks/pre-tool-validator.sh")

    assert "Returns JSON with hookSpecificOutput" "[[ '$output' == *'hookSpecificOutput'* ]]"
    assert "Has hookEventName PreToolUse" "[[ '$output' == *'PreToolUse'* ]]"
    assert "Has additionalContext" "[[ '$output' == *'additionalContext'* ]]"
    assert "Mentions secrets" "[[ '$output' == *'secret'* ]]"

    teardown
}

# Test: pre-tool-validator.sh with regular file
test_pre_tool_validator_regular() {
    echo "Test: pre-tool-validator.sh with regular file"
    setup

    # Simulate Write to regular file
    local input='{"tool_name":"Write","tool_input":{"file_path":"/project/src/app.ts"}}'

    local output=$(echo "$input" | "$TEST_DIR/.claude/hooks/pre-tool-validator.sh")

    # Per Hooks guide: allow without context = exit 0, no output
    assert "Returns empty for regular files (allow)" "[[ -z '$output' ]]"

    teardown
}

# Test: Hook scripts don't block on errors
test_hooks_dont_block() {
    echo "Test: Hook scripts don't block on errors"
    setup

    # Send invalid input
    local output
    local exit_code

    output=$(echo "invalid json" | "$TEST_DIR/.claude/hooks/log-file-change.sh" 2>&1) || exit_code=$?
    assert "log-file-change.sh exits 0 on invalid input" "[[ ${exit_code:-0} -eq 0 ]]"

    output=$(echo "" | "$TEST_DIR/.claude/hooks/log-bash-event.sh" 2>&1) || exit_code=$?
    assert "log-bash-event.sh exits 0 on empty input" "[[ ${exit_code:-0} -eq 0 ]]"

    teardown
}

# Run all tests
echo ""
test_changelog_logger
echo ""
test_log_file_change_write
echo ""
test_log_file_change_edit
echo ""
test_log_bash_test
echo ""
test_log_bash_commit
echo ""
test_pre_tool_validator_env
echo ""
test_pre_tool_validator_regular
echo ""
test_hooks_dont_block
echo ""

# Exit with status
if [[ $FAILURES -gt 0 ]]; then
    echo -e "${RED}$FAILURES assertion(s) failed${NC}"
    exit 1
else
    echo -e "${GREEN}All assertions passed${NC}"
    exit 0
fi
