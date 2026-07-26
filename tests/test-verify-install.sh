#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VERIFY="$PROJECT_ROOT/scripts/verify-install.sh"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/director-mode-verify.XXXXXX")"
FAILURES=0

cleanup() { rm -rf "$TEST_ROOT"; }
trap cleanup EXIT

assert() {
    if eval "$2"; then printf '  PASS %s\n' "$1"; else printf '  FAIL %s\n' "$1"; FAILURES=$((FAILURES + 1)); fi
}

run_verify() {
    verify_status=0
    verify_output="$("$VERIFY" "$@" 2>&1)" || verify_status=$?
}

echo "Test: complete default install verifies"
mkdir -p "$TEST_ROOT/default"
"$PROJECT_ROOT/install.sh" "$TEST_ROOT/default" >/dev/null
run_verify "$TEST_ROOT/default"
assert "default verifier exits zero" "[[ $verify_status -eq 0 ]]"
assert "verifier reports 35 skills" "[[ '$verify_output' == *'all 35 shipped skills'* ]]"
assert "verifier reports 14 generated agents" "[[ '$verify_output' == *'14 generated agents'* ]]"
assert "success summary printed" "[[ '$verify_output' == *'Installation verification passed'* ]]"
assert "verifier checks the doctor" "[[ '$verify_output' == *'director-doctor is executable'* ]]"

echo "Test: hook-free install verifies with explicit mode"
mkdir -p "$TEST_ROOT/none"
"$PROJECT_ROOT/install.sh" --hooks none "$TEST_ROOT/none" >/dev/null
run_verify --hooks none "$TEST_ROOT/none"
assert "hook-free verifier exits zero" "[[ $verify_status -eq 0 ]]"
assert "hook-free state is actively verified" "[[ '$verify_output' == *'no Director Mode registrations or owned hook assets'* ]]"

echo "Test: stale Director hooks fail zero-hook verification"
mkdir -p "$TEST_ROOT/stale"
"$PROJECT_ROOT/install.sh" --hooks none "$TEST_ROOT/stale" >/dev/null
mkdir -p "$TEST_ROOT/stale/.director-mode/hooks"
printf '#!/usr/bin/env bash\nexit 0\n' > "$TEST_ROOT/stale/.director-mode/hooks/advisory.sh"
printf '%s\n' '{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"bash .director-mode/hooks/advisory.sh claude"}]}]}}' > "$TEST_ROOT/stale/.claude/settings.local.json"
run_verify --hooks none "$TEST_ROOT/stale"
assert "stale Director hooks exit one" "[[ $verify_status -eq 1 ]]"
assert "stale registration or asset is named" "[[ '$verify_output' == *'.director-mode/hooks/advisory.sh'* ]]"

echo "Test: Director registration in an arbitrary Grok hook file is detected"
target="$TEST_ROOT/stale-grok-file"
mkdir -p "$target"
"$PROJECT_ROOT/install.sh" --hooks none "$target" >/dev/null
mkdir -p "$target/.grok/hooks"
printf '%s\n' '{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"bash .director-mode/hooks/advisory.sh grok"}]}]}}' \
    > "$target/.grok/hooks/custom-name.json"
run_verify --hooks none "$target"
assert "arbitrary Grok Director registration exits one" "[[ $verify_status -eq 1 ]]"
assert "arbitrary Grok hook file is named" "[[ '$verify_output' == *'.grok/hooks/custom-name.json'* ]]"

echo "Test: selected Codex install verifies"
mkdir -p "$TEST_ROOT/codex"
"$PROJECT_ROOT/install.sh" --cli codex "$TEST_ROOT/codex" >/dev/null
run_verify --cli codex "$TEST_ROOT/codex"
assert "Codex-only verifier exits zero" "[[ $verify_status -eq 0 ]]"

echo "Test: missing portable asset fails"
mkdir -p "$TEST_ROOT/missing"
"$PROJECT_ROOT/install.sh" "$TEST_ROOT/missing" >/dev/null
rm -f "$TEST_ROOT/missing/.director-mode/handoff.schema.json"
run_verify "$TEST_ROOT/missing"
assert "missing schema exits one" "[[ $verify_status -eq 1 ]]"
assert "missing schema is named" "[[ '$verify_output' == *'handoff schema'* ]]"

echo "Test: malformed native hook config fails"
mkdir -p "$TEST_ROOT/malformed"
"$PROJECT_ROOT/install.sh" --hooks guide "$TEST_ROOT/malformed" >/dev/null
printf '{bad json\n' > "$TEST_ROOT/malformed/.codex/hooks.json"
run_verify --hooks guide "$TEST_ROOT/malformed"
assert "malformed config exits one" "[[ $verify_status -eq 1 ]]"
assert "Codex JSON failure is named" "[[ '$verify_output' == *'Codex hooks are valid JSON'* ]]"

echo "Test: missing generated agent fails"
mkdir -p "$TEST_ROOT/agent"
"$PROJECT_ROOT/install.sh" "$TEST_ROOT/agent" >/dev/null
rm -f "$TEST_ROOT/agent/.codex/agents/code-reviewer.toml"
run_verify "$TEST_ROOT/agent"
assert "missing agent exits one" "[[ $verify_status -eq 1 ]]"
assert "agent count failure is reported" "[[ '$verify_output' == *'.codex/agents count'* ]]"

if [[ $FAILURES -gt 0 ]]; then
    printf '%d assertion(s) failed\n' "$FAILURES"
    exit 1
fi
echo "All assertions passed"
