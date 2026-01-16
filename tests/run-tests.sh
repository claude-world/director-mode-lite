#!/bin/bash
# Director Mode Lite - Test Runner
# Runs all test suites and reports results

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Counters
PASSED=0
FAILED=0
SKIPPED=0

echo ""
echo "================================"
echo "Director Mode Lite Test Suite"
echo "================================"
echo ""

# Run a test file and track results
run_test_file() {
    local test_file="$1"
    local test_name="$(basename "$test_file" .sh)"

    echo -e "${YELLOW}Running: $test_name${NC}"

    if [[ -x "$test_file" ]]; then
        if "$test_file"; then
            echo -e "${GREEN}PASSED: $test_name${NC}"
            ((PASSED++))
        else
            echo -e "${RED}FAILED: $test_name${NC}"
            ((FAILED++))
        fi
    else
        echo -e "${YELLOW}SKIPPED: $test_name (not executable)${NC}"
        ((SKIPPED++))
    fi
    echo ""
}

# Find and run all test files
for test_file in "$SCRIPT_DIR"/test-*.sh; do
    if [[ -f "$test_file" ]]; then
        run_test_file "$test_file"
    fi
done

# Summary
echo "================================"
echo "Test Summary"
echo "================================"
echo -e "Passed:  ${GREEN}$PASSED${NC}"
echo -e "Failed:  ${RED}$FAILED${NC}"
echo -e "Skipped: ${YELLOW}$SKIPPED${NC}"
echo ""

# Exit with failure if any tests failed
if [[ $FAILED -gt 0 ]]; then
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
else
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
fi
