#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/director-mode-uninstall.XXXXXX")"
TARGET="$TEST_ROOT/project"
FAILURES=0

cleanup() { rm -rf "$TEST_ROOT"; }
trap cleanup EXIT

assert() {
    if eval "$2"; then printf '  PASS %s\n' "$1"; else printf '  FAIL %s\n' "$1"; FAILURES=$((FAILURES + 1)); fi
}

mkdir -p "$TARGET"
"$PROJECT_ROOT/install.sh" --hooks guide "$TARGET" >/dev/null

# Add user-owned hook assets and registrations beside Director Mode entries.
mkdir -p "$TARGET/.claude/hooks" "$TARGET/.grok/hooks"
printf '#!/usr/bin/env bash\nexit 0\n' > "$TARGET/.claude/hooks/custom.sh"
chmod +x "$TARGET/.claude/hooks/custom.sh"
printf '{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"bash custom-grok.sh"}]}]}}\n' > "$TARGET/.grok/hooks/custom.json"
mkdir -p "$TARGET/.director-mode/handoffs"
printf 'keep packet\n' > "$TARGET/.director-mode/handoffs/user-packet.md"

python3 - "$TARGET" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
for rel, command in (
    (".claude/settings.local.json", "bash .claude/hooks/custom.sh"),
    (".codex/hooks.json", "bash .codex/hooks/custom.sh"),
):
    path = root / rel
    data = json.loads(path.read_text())
    data.setdefault("hooks", {}).setdefault("SessionStart", []).append({
        "hooks": [{"type": "command", "command": command}],
    })
    data["customSetting"] = "keep"
    path.write_text(json.dumps(data, indent=2) + "\n")
PY

echo "Test: hooks-only uninstall removes Director adapters and preserves user state"
status=0
output="$(printf '1\n' | "$PROJECT_ROOT/uninstall.sh" "$TARGET" 2>&1)" || status=$?
assert "uninstall exits zero" "[[ $status -eq 0 ]]"
assert "Claude advisory registration removed" "! grep -q 'advisory.sh' '$TARGET/.claude/settings.local.json'"
assert "Codex advisory registration removed" "! grep -q 'advisory.sh' '$TARGET/.codex/hooks.json'"
assert "Grok Director hook removed" "[[ ! -f '$TARGET/.grok/hooks/director-mode.json' ]]"
assert "advisory executable removed" "[[ ! -f '$TARGET/.director-mode/hooks/advisory.sh' ]]"
assert "custom Claude registration preserved" "grep -q 'custom.sh' '$TARGET/.claude/settings.local.json'"
assert "custom Codex registration preserved" "grep -q 'custom.sh' '$TARGET/.codex/hooks.json'"
assert "custom Grok hook preserved" "[[ -f '$TARGET/.grok/hooks/custom.json' ]]"
assert "custom hook executable preserved" "[[ -x '$TARGET/.claude/hooks/custom.sh' ]]"
assert "shared guidance preserved" "[[ -f '$TARGET/.director-mode/GUIDANCE.md' ]]"
assert "relay binary preserved" "[[ -x '$TARGET/.director-mode/bin/director-relay' ]]"
assert "handoff packet preserved" "[[ -f '$TARGET/.director-mode/handoffs/user-packet.md' ]]"
assert "skills preserved" "[[ -f '$TARGET/.claude/skills/session-relay/SKILL.md' ]]"
assert "Codex agents preserved" "[[ -f '$TARGET/.codex/agents/code-reviewer.toml' ]]"
assert "output reports adapter removal" "[[ '$output' == *'advisory adapters'* ]]"

echo "Test: complete uninstall removes only owned, unmodified assets"
COMPLETE="$TEST_ROOT/complete"
mkdir -p \
    "$COMPLETE/.claude/agents" \
    "$COMPLETE/.claude/skills/director-mode" \
    "$COMPLETE/.codex/agents"
printf 'user agent\n' > "$COMPLETE/.claude/agents/code-reviewer.md"
printf 'user skill\n' > "$COMPLETE/.claude/skills/director-mode/SKILL.md"
printf 'user codex agent\n' > "$COMPLETE/.codex/agents/code-reviewer.toml"
"$PROJECT_ROOT/install.sh" "$COMPLETE" >/dev/null
printf '\nuser modification\n' >> "$COMPLETE/.claude/skills/session-relay/SKILL.md"
printf 'private packet\n' > "$COMPLETE/.director-mode/handoffs/user-packet.md"

status=0
output="$(printf '2\n' | "$PROJECT_ROOT/uninstall.sh" "$COMPLETE" 2>&1)" || status=$?
assert "complete uninstall exits zero" "[[ $status -eq 0 ]]"
assert "pre-existing Claude agent preserved" "grep -q 'user agent' '$COMPLETE/.claude/agents/code-reviewer.md'"
assert "pre-existing Claude skill preserved" "grep -q 'user skill' '$COMPLETE/.claude/skills/director-mode/SKILL.md'"
assert "pre-existing Codex agent preserved" "grep -q 'user codex agent' '$COMPLETE/.codex/agents/code-reviewer.toml'"
assert "modified installed skill preserved" "grep -q 'user modification' '$COMPLETE/.claude/skills/session-relay/SKILL.md'"
assert "unmodified Claude asset removed" "[[ ! -e '$COMPLETE/.claude/agents/debugger.md' ]]"
assert "unmodified Grok adapter removed" "[[ ! -e '$COMPLETE/.grok/agents/debugger.md' ]]"
assert "unmodified runtime guide removed" "[[ ! -e '$COMPLETE/.director-mode/GUIDANCE.md' ]]"
assert "unmodified open launcher removed" "[[ ! -e '$COMPLETE/.director-mode/bin/director-open' ]]"
assert "unmodified doctor removed" "[[ ! -e '$COMPLETE/.director-mode/bin/director-doctor' ]]"
assert "handoff packets explicitly removed" "[[ ! -e '$COMPLETE/.director-mode/handoffs' ]]"
assert "ownership manifest removed" "[[ ! -e '$COMPLETE/.director-mode/install-ownership.json' ]]"
assert "output reports modified preservation" "[[ '$output' == *'Preserved modified'* ]]"

if [[ $FAILURES -gt 0 ]]; then
    printf '%d assertion(s) failed\n' "$FAILURES"
    exit 1
fi
echo "All assertions passed"
