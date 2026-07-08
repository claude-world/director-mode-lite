#!/bin/bash
# Test: install.sh --wizard functionality
# Verifies the interactive setup wizard selects the right hooks, and that
# plain (non-wizard) installs are unaffected.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

TEST_DIR="/tmp/director-mode-wizard-test-$$"
FAILURES=0

setup() {
    rm -rf "$TEST_DIR"
    mkdir -p "$TEST_DIR"
}

teardown() {
    rm -rf "$TEST_DIR"
}

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

# Feed wizard answers over stdin. DML_WIZARD_FORCE bypasses the `-t 0` TTY
# check so a non-interactive test runner can still exercise the prompts.
run_wizard() {
    local answers="$1"
    shift
    printf '%s' "$answers" | DML_WIZARD_FORCE=1 "$PROJECT_ROOT/install.sh" --wizard "$@" > /dev/null 2>&1
}

# Test: automation level 0 (none) wires no Stop hook and no evolving-loop hook
test_wizard_no_automation() {
    echo "Test: Wizard automation level 0 (none)"
    setup

    # Answers: project type=3 (exploring), automation=0 (explicit), obs hooks=Y
    run_wizard $'3\n0\nY\n' "$TEST_DIR"

    if command -v jq &>/dev/null; then
        assert "No Stop hook" "! jq -e '.hooks.Stop' '$TEST_DIR/.claude/settings.local.json' > /dev/null 2>&1"
        assert "Changelog hooks still present" "jq -e '.hooks.PostToolUse' '$TEST_DIR/.claude/settings.local.json' > /dev/null 2>&1"
        assert "Validator hook still present" "jq -e '.hooks.PreToolUse' '$TEST_DIR/.claude/settings.local.json' > /dev/null 2>&1"
    fi
    assert "No evolving-loop Stop hook merged" "! grep -q 'continue-loop.sh' '$TEST_DIR/.claude/settings.local.json' 2>/dev/null"

    teardown
}

# Test: automation level 1 (Auto-Loop only) — the common default path
test_wizard_autoloop_only() {
    echo "Test: Wizard automation level 1 (Auto-Loop only)"
    setup

    # Answers: project type=1 (web/api), automation=1, obs hooks=Y
    run_wizard $'1\n1\nY\n' "$TEST_DIR"

    if command -v jq &>/dev/null; then
        assert "Stop hook present" "jq -e '.hooks.Stop' '$TEST_DIR/.claude/settings.local.json' > /dev/null 2>&1"
    fi
    assert "Auto-loop-stop.sh wired" "grep -q 'auto-loop-stop.sh' '$TEST_DIR/.claude/settings.local.json'"
    assert "No evolving-loop Stop hook merged" "! grep -q 'continue-loop.sh' '$TEST_DIR/.claude/settings.local.json' 2>/dev/null"

    teardown
}

# Test: automation level 2 (Auto-Loop + Evolving-Loop)
test_wizard_evolving_loop() {
    echo "Test: Wizard automation level 2 (Auto-Loop + Evolving-Loop)"
    setup

    # Answers: project type=4 (dogfooding), automation=2, obs hooks=Y
    run_wizard $'4\n2\nY\n' "$TEST_DIR"

    assert "Auto-loop-stop.sh wired" "grep -q 'auto-loop-stop.sh' '$TEST_DIR/.claude/settings.local.json'"
    assert "Evolving-loop continue-loop.sh wired" "grep -q 'continue-loop.sh' '$TEST_DIR/.claude/settings.local.json'"
    assert "Evolving-loop log-event.sh wired" "grep -q 'log-event.sh' '$TEST_DIR/.claude/settings.local.json'"

    teardown
}

# Test: declining observability hooks skips changelog + validator
test_wizard_declines_observability() {
    echo "Test: Wizard declining changelog/validator hooks"
    setup

    # Answers: project type=1, automation=1, obs hooks=n
    run_wizard $'1\n1\nn\n' "$TEST_DIR"

    if command -v jq &>/dev/null; then
        assert "No PostToolUse (changelog) hooks" "! jq -e '.hooks.PostToolUse' '$TEST_DIR/.claude/settings.local.json' > /dev/null 2>&1"
        assert "No PreToolUse (validator) hooks" "! jq -e '.hooks.PreToolUse' '$TEST_DIR/.claude/settings.local.json' > /dev/null 2>&1"
        assert "Stop hook (Auto-Loop) still present" "jq -e '.hooks.Stop' '$TEST_DIR/.claude/settings.local.json' > /dev/null 2>&1"
    fi

    teardown
}

# Test: pressing enter for every prompt takes the recommended defaults
test_wizard_defaults_on_blank_answers() {
    echo "Test: Wizard blank answers fall back to recommended defaults"
    setup

    # Answers: all blank -> project type default (1, web/api), automation default (1), obs default (Y)
    run_wizard $'\n\n\n' "$TEST_DIR"

    assert "Auto-loop-stop.sh wired (recommended default)" "grep -q 'auto-loop-stop.sh' '$TEST_DIR/.claude/settings.local.json'"
    if command -v jq &>/dev/null; then
        assert "Changelog/validator hooks present by default" "jq -e '.hooks.PostToolUse' '$TEST_DIR/.claude/settings.local.json' > /dev/null 2>&1"
    fi

    teardown
}

# Test: --wizard without a TTY and without the test escape hatch falls back
# to the exact same defaults as a plain install (no hang, no crash).
test_wizard_noninteractive_fallback() {
    echo "Test: --wizard falls back safely with no TTY"
    setup

    # No DML_WIZARD_FORCE, no stdin answers provided (closed stdin) — must not hang.
    "$PROJECT_ROOT/install.sh" --wizard "$TEST_DIR" < /dev/null > /dev/null 2>&1

    if command -v jq &>/dev/null; then
        assert "Falls back to default Stop hook" "jq -e '.hooks.Stop' '$TEST_DIR/.claude/settings.local.json' > /dev/null 2>&1"
        assert "Falls back to default changelog hooks" "jq -e '.hooks.PostToolUse' '$TEST_DIR/.claude/settings.local.json' > /dev/null 2>&1"
    fi
    assert "No evolving-loop hook merged (opt-in stays off)" "! grep -q 'continue-loop.sh' '$TEST_DIR/.claude/settings.local.json' 2>/dev/null"

    teardown
}

# Test: plain install (no --wizard) is unaffected by the new flags/defaults
test_plain_install_unaffected() {
    echo "Test: Plain install (no --wizard) behavior is unchanged"
    setup

    "$PROJECT_ROOT/install.sh" "$TEST_DIR" > /dev/null 2>&1

    if command -v jq &>/dev/null; then
        assert "Stop hook present" "jq -e '.hooks.Stop' '$TEST_DIR/.claude/settings.local.json' > /dev/null 2>&1"
        assert "PostToolUse hooks present" "jq -e '.hooks.PostToolUse' '$TEST_DIR/.claude/settings.local.json' > /dev/null 2>&1"
        assert "PreToolUse hooks present" "jq -e '.hooks.PreToolUse' '$TEST_DIR/.claude/settings.local.json' > /dev/null 2>&1"
    fi
    assert "No evolving-loop hook merged (opt-in stays off)" "! grep -q 'continue-loop.sh' '$TEST_DIR/.claude/settings.local.json' 2>/dev/null"

    teardown
}

# Run all tests
echo ""
test_wizard_no_automation
echo ""
test_wizard_autoloop_only
echo ""
test_wizard_evolving_loop
echo ""
test_wizard_declines_observability
echo ""
test_wizard_defaults_on_blank_answers
echo ""
test_wizard_noninteractive_fallback
echo ""
test_plain_install_unaffected
echo ""

# Exit with status
if [[ $FAILURES -gt 0 ]]; then
    echo -e "${RED}$FAILURES assertion(s) failed${NC}"
    exit 1
else
    echo -e "${GREEN}All assertions passed${NC}"
    exit 0
fi
