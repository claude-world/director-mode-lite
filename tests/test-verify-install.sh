#!/bin/bash
# Test: scripts/verify-install.sh
# Verifies install validation passes for a fresh install and fails when files are missing

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/director-mode-verify.XXXXXX")"
FAILURES=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

cleanup() {
    rm -rf "$TEST_DIR"
}

trap cleanup EXIT

assert() {
    local description="$1"
    local condition="$2"

    if eval "$condition"; then
        echo -e "  ${GREEN}PASS${NC} $description"
    else
        echo -e "  ${RED}FAIL${NC} $description"
        FAILURES=$((FAILURES + 1))
    fi
}

echo "Test: verify-install.sh is executable"
assert "verify-install.sh is executable" "[[ -x '$PROJECT_ROOT/scripts/verify-install.sh' ]]"
echo ""

echo "Test: verify-install.sh passes after install"
"$PROJECT_ROOT/install.sh" "$TEST_DIR" > /dev/null 2>&1

if verify_output="$("$PROJECT_ROOT/scripts/verify-install.sh" "$TEST_DIR" 2>&1)"; then
    verify_status=0
else
    verify_status=$?
fi

assert "verify-install.sh exits with 0 for a valid install" "[[ $verify_status -eq 0 ]]"
assert "verify-install.sh reports PASS output" "[[ '$verify_output' == *'PASS'* ]]"
assert "verify-install.sh prints success summary" "[[ '$verify_output' == *'Installation verification passed'* ]]"
echo ""

echo "Test: verify-install.sh fails when required files are missing"
rm -f "$TEST_DIR/.claude/agents/code-reviewer.md"

if broken_output="$("$PROJECT_ROOT/scripts/verify-install.sh" "$TEST_DIR" 2>&1)"; then
    broken_status=0
else
    broken_status=$?
fi

assert "verify-install.sh exits with 1 for an invalid install" "[[ $broken_status -eq 1 ]]"
assert "verify-install.sh reports FAIL output" "[[ '$broken_output' == *'FAIL'* ]]"
assert "verify-install.sh reports the missing file" "[[ '$broken_output' == *'code-reviewer'* ]]"
echo ""

if [[ $FAILURES -gt 0 ]]; then
    echo -e "${RED}$FAILURES assertion(s) failed${NC}"
    exit 1
fi

echo -e "${GREEN}All assertions passed${NC}"
exit 0
