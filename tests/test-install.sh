#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/director-mode-install.XXXXXX")"
FAILURES=0

cleanup() { rm -rf "$TEST_ROOT"; }
trap cleanup EXIT

assert() {
    local description="$1" condition="$2"
    if eval "$condition"; then
        printf '  PASS %s\n' "$description"
    else
        printf '  FAIL %s\n' "$description"
        FAILURES=$((FAILURES + 1))
    fi
}

fresh_target() {
    local name="$1"
    mkdir -p "$TEST_ROOT/$name"
    printf '%s' "$TEST_ROOT/$name"
}

echo "Test: default install creates three-CLI adapters with zero active hooks"
target="$(fresh_target default)"
"$PROJECT_ROOT/install.sh" "$target" >/dev/null
assert "shared guidance installed" "[[ -f '$target/.director-mode/GUIDANCE.md' ]]"
assert "relay executable installed" "[[ -x '$target/.director-mode/bin/director-relay' ]]"
assert "open permission launcher installed" "[[ -x '$target/.director-mode/bin/director-open' ]]"
assert "35 Claude/Grok-compatible skills installed" "[[ \$(find '$target/.claude/skills' -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ') -eq 35 ]]"
assert "35 Codex skills installed" "[[ \$(find '$target/.agents/skills' -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ') -eq 35 ]]"
assert "14 Codex agents generated" "[[ \$(find '$target/.codex/agents' -name '*.toml' | wc -l | tr -d ' ') -eq 14 ]]"
assert "14 Grok agents generated" "[[ \$(find '$target/.grok/agents' -name '*.md' | wc -l | tr -d ' ') -eq 14 ]]"
assert "Claude hook settings absent" "[[ ! -f '$target/.claude/settings.local.json' ]]"
assert "Codex hook settings absent" "[[ ! -f '$target/.codex/hooks.json' ]]"
assert "Grok hook settings absent" "[[ ! -e '$target/.grok/hooks/director-mode.json' ]]"
assert "unused advisory executable absent" "[[ ! -e '$target/.director-mode/hooks/advisory.sh' ]]"
assert "Grok skill tree is not duplicated" "[[ ! -d '$target/.grok/skills' ]]"
assert "legacy Claude hooks are absent by default" "[[ ! -e '$target/.claude/hooks/auto-loop-stop.sh' ]]"
assert "legacy evolving-loop is absent by default" "[[ ! -d '$target/.self-evolving-loop' ]]"
assert "Claude open mode uses native bypass" "[[ \"\$('$target/.director-mode/bin/director-open' --print claude)\" == *'--permission-mode bypassPermissions'* ]]"
assert "Codex open mode disables approvals and sandbox" "[[ \"\$('$target/.director-mode/bin/director-open' --print codex)\" == *'--dangerously-bypass-approvals-and-sandbox'* ]]"
assert "Grok open mode approves with sandbox off" "[[ \"\$('$target/.director-mode/bin/director-open' --print grok)\" == *'--always-approve --sandbox off'* ]]"

echo "Test: useful non-blocking context hooks are explicit"
target="$(fresh_target guide-hooks)"
"$PROJECT_ROOT/install.sh" --hooks guide "$target" >/dev/null
assert "relay still installed" "[[ -x '$target/.director-mode/bin/director-relay' ]]"
assert "Claude advisory registered" "grep -q 'advisory.sh' '$target/.claude/settings.local.json'"
assert "Codex advisory registered" "grep -q 'advisory.sh' '$target/.codex/hooks.json'"
assert "Grok inert hook omitted" "[[ ! -e '$target/.grok/hooks/director-mode.json' ]]"
assert "advisory executable staged" "[[ -x '$target/.director-mode/hooks/advisory.sh' ]]"

echo "Test: CLI selection limits native hook adapters"
target="$(fresh_target codex-only)"
"$PROJECT_ROOT/install.sh" --cli codex --hooks guide "$target" >/dev/null
assert "Codex adapter exists" "[[ -f '$target/.codex/hooks.json' ]]"
assert "Claude advisory not registered" "[[ ! -f '$target/.claude/settings.local.json' ]]"
assert "Grok adapter not created" "[[ ! -e '$target/.grok/hooks/director-mode.json' ]]"
assert "Grok agents not created" "[[ ! -e '$target/.grok/agents' ]]"

echo "Test: legacy automation is explicit"
target="$(fresh_target automation)"
"$PROJECT_ROOT/install.sh" --hooks automation "$target" >/dev/null
assert "Auto-Loop hook installed" "[[ -x '$target/.claude/hooks/auto-loop-stop.sh' ]]"
assert "Auto-Loop hook registered" "grep -q 'auto-loop-stop.sh' '$target/.claude/settings.local.json'"
assert "evolving-loop scaffolding installed" "[[ -x '$target/.self-evolving-loop/hooks/continue-loop.sh' ]]"

echo "Test: existing files are preserved unless --update is used"
target="$(fresh_target update)"
"$PROJECT_ROOT/install.sh" "$target" >/dev/null
printf '\n# LOCAL\n' >> "$target/.claude/skills/director-mode/SKILL.md"
printf '\n# LOCAL RUNTIME\n' >> "$target/.director-mode/GUIDANCE.md"
"$PROJECT_ROOT/install.sh" "$target" >/dev/null
assert "plain install preserves local skill edit" "grep -q '# LOCAL' '$target/.claude/skills/director-mode/SKILL.md'"
assert "plain install preserves runtime guide edit" "grep -q '# LOCAL RUNTIME' '$target/.director-mode/GUIDANCE.md'"
"$PROJECT_ROOT/install.sh" --update "$target" >/dev/null
assert "update restores distributed skill" "diff -q '$PROJECT_ROOT/skills/director-mode/SKILL.md' '$target/.claude/skills/director-mode/SKILL.md' >/dev/null"
assert "update restores runtime guide" "diff -q '$PROJECT_ROOT/portable/GUIDANCE.md' '$target/.director-mode/GUIDANCE.md' >/dev/null"
assert "ownership manifest exists" "python3 -m json.tool '$target/.director-mode/install-ownership.json' >/dev/null"

echo "Test: existing .claude is backed up"
target="$(fresh_target backup)"
mkdir -p "$target/.claude"
printf 'keep\n' > "$target/.claude/custom.txt"
"$PROJECT_ROOT/install.sh" "$target" >/dev/null
assert "timestamped backup contains custom file" "find '$target' -maxdepth 2 -path '*/.claude-backup-*/custom.txt' -type f | grep -q ."

if [[ $FAILURES -gt 0 ]]; then
    printf '%d assertion(s) failed\n' "$FAILURES"
    exit 1
fi
echo "All assertions passed"
