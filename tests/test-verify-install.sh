#!/bin/bash
# Test: scripts/verify-install.sh
# Covers valid installs, shared-project compatibility, JSON/config validation,
# complete shipped inventory, executable hook requirements, and hook-free mode.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VERIFY_SCRIPT="$PROJECT_ROOT/scripts/verify-install.sh"
TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/director-mode-verify.XXXXXX")"
FAILURES=0

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# shellcheck disable=SC2329  # Invoked indirectly by the EXIT trap.
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

reset_target() {
    rm -rf "$TEST_DIR"
    mkdir -p "$TEST_DIR"
}

install_target() {
    reset_target
    "$PROJECT_ROOT/install.sh" "$TEST_DIR" > /dev/null 2>&1
}

run_verify() {
    verify_status=0
    if verify_output="$("$VERIFY_SCRIPT" "$TEST_DIR" 2>&1)"; then
        :
    else
        verify_status=$?
    fi
}

echo "Test: verify-install.sh is executable"
assert "verify-install.sh is executable" "[[ -x '$VERIFY_SCRIPT' ]]"
echo ""

echo "Test: verifier passes a complete installation"
install_target
run_verify
assert "valid install exits 0" "[[ $verify_status -eq 0 ]]"
assert "success summary is printed" "[[ '$verify_output' == *'Installation verification passed'* ]]"
assert "32-skill inventory is reported" "[[ '$verify_output' == *'32 shipped skills'* ]]"
assert "27-command inventory is reported" "[[ '$verify_output' == *'27 user-invocable commands'* ]]"
assert "14-agent inventory is reported" "[[ '$verify_output' == *'14 shipped agents'* ]]"
echo ""

echo "Test: custom CLAUDE.md is accepted and preserved"
reset_target
printf '# Existing project instructions\n\nKeep this custom structure.\n' > "$TEST_DIR/CLAUDE.md"
cp "$TEST_DIR/CLAUDE.md" "$TEST_DIR/custom-claude.snapshot"
"$PROJECT_ROOT/install.sh" "$TEST_DIR" > /dev/null 2>&1
run_verify
assert "custom CLAUDE.md install exits 0" "[[ $verify_status -eq 0 ]]"
assert "custom CLAUDE.md is unchanged" "diff -q '$TEST_DIR/custom-claude.snapshot' '$TEST_DIR/CLAUDE.md' > /dev/null 2>&1"
echo ""

echo "Test: additional user agents and skills do not break inventory verification"
install_target
mkdir -p "$TEST_DIR/.claude/skills/custom-user-skill"
printf '%s\n' '---' 'name: custom-user-skill' 'user-invocable: true' '---' > "$TEST_DIR/.claude/skills/custom-user-skill/SKILL.md"
printf '%s\n' '---' 'name: custom-user-agent' '---' > "$TEST_DIR/.claude/agents/custom-user-agent.md"
run_verify
assert "valid install with user extensions exits 0" "[[ $verify_status -eq 0 ]]"
echo ""

echo "Test: malformed settings JSON fails validation"
install_target
printf '{invalid json\n' > "$TEST_DIR/.claude/settings.local.json"
run_verify
assert "malformed settings exits 1" "[[ $verify_status -eq 1 ]]"
assert "malformed settings reports JSON failure" "[[ '$verify_output' == *'valid JSON'* ]]"
echo ""

echo "Test: missing shipped inventory fails validation"
install_target
rm -rf "$TEST_DIR/.claude/skills/handoff-claude"
rm -f "$TEST_DIR/.claude/agents/completion-judge.md"
run_verify
assert "missing shipped inventory exits 1" "[[ $verify_status -eq 1 ]]"
assert "missing skill is named" "[[ '$verify_output' == *'handoff-claude'* ]]"
assert "missing agent is named" "[[ '$verify_output' == *'completion-judge.md'* ]]"
echo ""

echo "Test: non-executable hook fails validation"
install_target
chmod -x "$TEST_DIR/.claude/hooks/log-file-change.sh"
run_verify
assert "non-executable hook exits 1" "[[ $verify_status -eq 1 ]]"
assert "non-executable hook is named" "[[ '$verify_output' == *'log-file-change.sh is executable'* ]]"
echo ""

echo "Test: valid settings without a registered DML hook fail validation"
install_target
SETTINGS_FILE="$TEST_DIR/.claude/settings.local.json" python3 - <<'PYEOF'
import json
import os

path = os.environ["SETTINGS_FILE"]
with open(path) as handle:
    settings = json.load(handle)

settings["hooks"] = {
    "PostToolUse": [{
        "matcher": "Write",
        "hooks": [{"type": "command", "command": "./custom-hook.sh"}],
    }],
}

with open(path, "w") as handle:
    json.dump(settings, handle, indent=2)
PYEOF
run_verify
assert "missing DML registration exits 1" "[[ $verify_status -eq 1 ]]"
assert "missing registration is explained" "[[ '$verify_output' == *'registered DML hook'* ]]"
echo ""

echo "Test: explicit hook-free mode skips hook files, settings, and dependencies"
install_target
rm -rf "$TEST_DIR/.claude/hooks" "$TEST_DIR/.self-evolving-loop/hooks"
rm -f "$TEST_DIR/.claude/settings.local.json"
verify_status=0
if verify_output="$("$VERIFY_SCRIPT" --allow-no-hooks "$TEST_DIR" 2>&1)"; then
    :
else
    verify_status=$?
fi
assert "explicit hook-free verification exits 0" "[[ $verify_status -eq 0 ]]"
assert "hook-free skipped checks are reported" "[[ '$verify_output' == *'Hook files, dependencies, settings, and registrations skipped (--allow-no-hooks)'* ]]"
assert "hook-free mode does not check jq" "[[ '$verify_output' != *'jq hook dependency'* ]]"
assert "hook-free mode does not check python3" "[[ '$verify_output' != *'python3 hook dependency'* ]]"
echo ""

if [[ $FAILURES -gt 0 ]]; then
    echo -e "${RED}$FAILURES assertion(s) failed${NC}"
    exit 1
fi

echo -e "${GREEN}All assertions passed${NC}"
exit 0
