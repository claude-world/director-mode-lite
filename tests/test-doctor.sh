#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DOCTOR="$PROJECT_ROOT/scripts/director-doctor.py"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/director-mode-doctor.XXXXXX")"
TEST_ROOT="$(cd "$TEST_ROOT" && pwd -P)"
TEST_HOME="$TEST_ROOT/home"
FAILURES=0

cleanup() { rm -rf "$TEST_ROOT"; }
trap cleanup EXIT

assert() {
    if eval "$2"; then printf '  PASS %s\n' "$1"; else printf '  FAIL %s\n' "$1"; FAILURES=$((FAILURES + 1)); fi
}

git -C "$TEST_ROOT" init -q
mkdir -p \
    "$TEST_HOME" \
    "$TEST_ROOT/.director-mode/bin" \
    "$TEST_ROOT/.claude/skills/example" \
    "$TEST_ROOT/.claude/agents" \
    "$TEST_ROOT/.agents/skills/example" \
    "$TEST_ROOT/.codex/agents" \
    "$TEST_ROOT/.grok/agents"
printf 'fixture\n' > "$TEST_ROOT/.director-mode/GUIDANCE.md"
printf '{}\n' > "$TEST_ROOT/.director-mode/handoff.schema.json"
for asset in director-relay director-open director-doctor; do
    printf '#!/usr/bin/env sh\nexit 0\n' > "$TEST_ROOT/.director-mode/bin/$asset"
    chmod +x "$TEST_ROOT/.director-mode/bin/$asset"
done
printf '%s\n' '# Example' > "$TEST_ROOT/.claude/skills/example/SKILL.md"
printf '%s\n' '# Example' > "$TEST_ROOT/.agents/skills/example/SKILL.md"
printf '%s\n' '# Agent' > "$TEST_ROOT/.claude/agents/example.md"
printf '%s\n' 'name = "example"' > "$TEST_ROOT/.codex/agents/example.toml"
printf '%s\n' '# Agent' > "$TEST_ROOT/.grok/agents/example.md"
mkdir -p "$TEST_ROOT/.claude"
printf '%s\n' '{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"true"}]}]}}' \
    > "$TEST_ROOT/.claude/settings.local.json"

before="$(find "$TEST_ROOT" -type f -exec shasum -a 256 {} \; | sort | shasum -a 256)"
report="$(HOME="$TEST_HOME" CLAUDE_CONFIG_DIR="$TEST_HOME/.claude" \
    CODEX_HOME="$TEST_HOME/.codex" GROK_HOME="$TEST_HOME/.grok" \
    "$DOCTOR" --cwd "$TEST_ROOT" --json --no-probe)"
after="$(find "$TEST_ROOT" -type f -exec shasum -a 256 {} \; | sort | shasum -a 256)"

assert "doctor emits valid JSON" "REPORT='$report' python3 -c 'import json,os; json.loads(os.environ[\"REPORT\"])'"
assert "doctor is explicitly read-only" "REPORT='$report' python3 -c 'import json,os; assert json.loads(os.environ[\"REPORT\"])[\"mode\"] == \"read-only\"'"
assert "complete runtime is detected" "REPORT='$report' python3 -c 'import json,os; r=json.loads(os.environ[\"REPORT\"])[\"runtime\"]; assert not r[\"missing\"] and not r[\"issues\"]'"
assert "native skill and agent counts are reported" "REPORT='$report' python3 -c 'import json,os; a=json.loads(os.environ[\"REPORT\"])[\"assets\"]; assert a[\"claude\"] == {\"skills\":1,\"agents\":1} and a[\"codex\"] == {\"skills\":1,\"agents\":1} and a[\"grok\"][\"agents\"] == 1'"
assert "known hook registrations are visible" "REPORT='$report' python3 -c 'import json,os; assert json.loads(os.environ[\"REPORT\"])[\"hooks\"][\"known_registrations\"] == 1'"
assert "doctor does not mutate the project" "[[ '$before' == '$after' ]]"

mkdir -p "$TEST_ROOT/.grok/hooks"
printf '%s\n' '{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"true"}]}]}}' \
    > "$TEST_ROOT/.grok/hooks/company.json"
printf '{bad json\n' > "$TEST_ROOT/.grok/hooks/broken.json"
expanded_report="$(HOME="$TEST_HOME" CLAUDE_CONFIG_DIR="$TEST_HOME/.claude" \
    CODEX_HOME="$TEST_HOME/.codex" GROK_HOME="$TEST_HOME/.grok" \
    "$DOCTOR" --cwd "$TEST_ROOT" --json --no-probe)"
assert "arbitrary Grok hook JSON files are inspected" \
    "REPORT='$expanded_report' python3 -c 'import json,os; r=json.loads(os.environ[\"REPORT\"]); assert r[\"hooks\"][\"known_registrations\"] == 2 and any(k.endswith(\":company.json\") for k in r[\"hooks\"][\"surfaces\"])'"
assert "malformed hook JSON is reported instead of treated as zero hooks" \
    "REPORT='$expanded_report' python3 -c 'import json,os; r=json.loads(os.environ[\"REPORT\"]); assert any(k.endswith(\":broken.json\") for k in r[\"hooks\"][\"invalid_surfaces\"]); assert not any(\"no hook registrations\" in x for x in r[\"recommendations\"])'"

missing="$(HOME="$TEST_HOME" CLAUDE_CONFIG_DIR="$TEST_HOME/.claude" \
    CODEX_HOME="$TEST_HOME/.codex" GROK_HOME="$TEST_HOME/.grok" \
    "$DOCTOR" --cwd "$TEST_ROOT/.claude" --json --no-probe)"
assert "subdirectory calls resolve the project root" "REPORT='$missing' ROOT='$TEST_ROOT' python3 -c 'import json,os; assert json.loads(os.environ[\"REPORT\"])[\"project_root\"] == os.environ[\"ROOT\"]'"

GLOBAL_ROOT="$TEST_ROOT/global-project"
GLOBAL_HOME="$TEST_ROOT/global-home"
mkdir -p "$GLOBAL_ROOT"
git -C "$GLOBAL_ROOT" init -q
mkdir -p \
    "$GLOBAL_HOME/.claude/portable" "$GLOBAL_HOME/.claude/bin" \
    "$GLOBAL_HOME/.claude/skills/example" "$GLOBAL_HOME/.claude/agents" \
    "$GLOBAL_HOME/.agents/skills/example" "$GLOBAL_HOME/.codex/agents" \
    "$GLOBAL_HOME/.grok/agents"
printf 'fixture\n' > "$GLOBAL_HOME/.claude/portable/GUIDANCE.md"
printf '{}\n' > "$GLOBAL_HOME/.claude/portable/handoff.schema.json"
for asset in director-relay director-open director-doctor; do
    printf '#!/usr/bin/env sh\nexit 0\n' > "$GLOBAL_HOME/.claude/bin/$asset"
    chmod +x "$GLOBAL_HOME/.claude/bin/$asset"
done
printf '# Example\n' > "$GLOBAL_HOME/.claude/skills/example/SKILL.md"
printf '# Example\n' > "$GLOBAL_HOME/.agents/skills/example/SKILL.md"
printf '# Agent\n' > "$GLOBAL_HOME/.claude/agents/example.md"
printf 'name = "example"\n' > "$GLOBAL_HOME/.codex/agents/example.toml"
printf '# Agent\n' > "$GLOBAL_HOME/.grok/agents/example.md"
global_report="$(HOME="$GLOBAL_HOME" CLAUDE_CONFIG_DIR="$GLOBAL_HOME/.claude" \
    CODEX_HOME="$GLOBAL_HOME/.codex" GROK_HOME="$GLOBAL_HOME/.grok" \
    "$DOCTOR" --cwd "$GLOBAL_ROOT" --json --no-probe)"
assert "Bootstrap user runtime is recognized outside an initialized project" \
    "REPORT='$global_report' python3 -c 'import json,os; r=json.loads(os.environ[\"REPORT\"]); assert r[\"runtime\"][\"source\"] == \"user\" and not r[\"runtime\"][\"missing\"]'"
assert "user and project discovery paths are combined by asset name" \
    "REPORT='$global_report' python3 -c 'import json,os; a=json.loads(os.environ[\"REPORT\"])[\"assets\"]; assert a[\"claude\"] == {\"skills\":1,\"agents\":1} and a[\"codex\"] == {\"skills\":1,\"agents\":1} and a[\"grok\"][\"agents\"] == 1'"

PLUGIN_ROOT="$TEST_ROOT/plugin-project"
PLUGIN_HOME="$TEST_ROOT/plugin-home"
mkdir -p "$PLUGIN_ROOT" "$PLUGIN_HOME"
git -C "$PLUGIN_ROOT" init -q
plugin_report="$(HOME="$PLUGIN_HOME" CLAUDE_CONFIG_DIR="$PLUGIN_HOME/.claude" \
    CODEX_HOME="$PLUGIN_HOME/.codex" GROK_HOME="$PLUGIN_HOME/.grok" \
    "$PROJECT_ROOT/skills/director-mode/scripts/director-doctor.py" \
    --cwd "$PLUGIN_ROOT" --json --no-probe)"
assert "plugin-only bundled runtime is recognized" \
    "REPORT='$plugin_report' python3 -c 'import json,os; r=json.loads(os.environ[\"REPORT\"]); assert r[\"runtime\"][\"source\"] == \"plugin\" and not r[\"runtime\"][\"missing\"]'"

if [[ $FAILURES -gt 0 ]]; then
    printf '%d assertion(s) failed\n' "$FAILURES"
    exit 1
fi
echo "All assertions passed"
