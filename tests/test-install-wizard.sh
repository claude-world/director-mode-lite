#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/director-mode-wizard.XXXXXX")"
FAILURES=0

cleanup() { rm -rf "$TEST_ROOT"; }
trap cleanup EXIT

assert() {
    if eval "$2"; then printf '  PASS %s\n' "$1"; else printf '  FAIL %s\n' "$1"; FAILURES=$((FAILURES + 1)); fi
}

run_wizard() {
    local answers="$1" target="$2"
    mkdir -p "$target"
    printf '%s' "$answers" | DML_WIZARD_FORCE=1 "$PROJECT_ROOT/install.sh" --wizard "$target" >/dev/null
}

echo "Test: blank wizard answers select all CLIs and zero-hook guidance"
run_wizard $'\n\n\n' "$TEST_ROOT/default"
assert "Claude hook config absent" "[[ ! -f '$TEST_ROOT/default/.claude/settings.local.json' ]]"
assert "Codex adapters generated" "[[ -f '$TEST_ROOT/default/.codex/agents/code-reviewer.toml' ]]"
assert "Grok adapters generated" "[[ -f '$TEST_ROOT/default/.grok/agents/code-reviewer.md' ]]"
assert "Grok passive hook omitted" "[[ ! -f '$TEST_ROOT/default/.grok/hooks/director-mode.json' ]]"
assert "Stop automation remains off" "[[ ! -f '$TEST_ROOT/default/.claude/hooks/auto-loop-stop.sh' ]]"

echo "Test: wizard supports Codex-only hook adapters with no active hooks"
run_wizard $'2\n3\n1\n' "$TEST_ROOT/codex-none"
assert "Codex agents exist" "[[ -f '$TEST_ROOT/codex-none/.codex/agents/code-reviewer.toml' ]]"
assert "Codex hook config absent" "[[ ! -f '$TEST_ROOT/codex-none/.codex/hooks.json' ]]"
assert "Claude hook config absent" "[[ ! -f '$TEST_ROOT/codex-none/.claude/settings.local.json' ]]"
assert "Grok hook config absent" "[[ ! -f '$TEST_ROOT/codex-none/.grok/hooks/director-mode.json' ]]"

echo "Test: wizard legacy automation is an explicit third choice"
run_wizard $'4\n1\n3\n' "$TEST_ROOT/automation"
assert "legacy hook installed" "[[ -x '$TEST_ROOT/automation/.claude/hooks/auto-loop-stop.sh' ]]"
assert "legacy hook registered" "grep -q 'auto-loop-stop.sh' '$TEST_ROOT/automation/.claude/settings.local.json'"
assert "advisory remains registered" "grep -q 'advisory.sh' '$TEST_ROOT/automation/.claude/settings.local.json'"
assert "Grok passive hook remains absent" "[[ ! -f '$TEST_ROOT/automation/.grok/hooks/director-mode.json' ]]"

echo "Test: non-interactive wizard fallback remains guidance-first"
mkdir -p "$TEST_ROOT/noninteractive"
"$PROJECT_ROOT/install.sh" --wizard "$TEST_ROOT/noninteractive" </dev/null >/dev/null
assert "fallback installs Codex adapter" "[[ -f '$TEST_ROOT/noninteractive/.codex/agents/code-reviewer.toml' ]]"
assert "fallback installs no active hook" "[[ ! -f '$TEST_ROOT/noninteractive/.claude/settings.local.json' ]]"
assert "fallback does not install Auto-Loop" "[[ ! -e '$TEST_ROOT/noninteractive/.claude/hooks/auto-loop-stop.sh' ]]"

if [[ $FAILURES -gt 0 ]]; then
    printf '%d assertion(s) failed\n' "$FAILURES"
    exit 1
fi
echo "All assertions passed"
