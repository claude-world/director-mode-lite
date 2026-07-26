#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
FAILURES=0

assert() {
    if eval "$2"; then printf '  PASS %s\n' "$1"; else printf '  FAIL %s\n' "$1"; FAILURES=$((FAILURES + 1)); fi
}

echo "Test: portable product contract is guidance-first"
assert "shared guide names all three CLIs" "grep -q 'Claude Code, Codex CLI, and' '$PROJECT_ROOT/portable/GUIDANCE.md' && grep -q 'Grok Build' '$PROJECT_ROOT/portable/GUIDANCE.md'"
assert "shared guide adds no permission gate" "grep -q 'does not add permission gates' '$PROJECT_ROOT/portable/GUIDANCE.md'"
assert "router tree exposes no automatic execution action" "! grep -R -q 'auto_execute\|auto-route\|auto route' '$PROJECT_ROOT/skills/interop-router'"
assert "router runtime always requires user choice" "python3 -c 'import json,subprocess; p=json.loads(subprocess.check_output([\"python3\", \"$PROJECT_ROOT/skills/interop-router/scripts/score_decision.py\", \"--task\", \"bulk refactor code\", \"--files\", \"20\", \"--json\"])); assert p[\"recommendation\"][\"action\"] in (\"suggest\", \"stay\") and p[\"recommendation\"][\"user_choice_required\"] is True'"
assert "project init does not instruct Stop-hook installation" "! grep -q 'copy .*auto-loop-stop\|settings.*hooks.Stop\|Verify hooks were installed' '$PROJECT_ROOT/skills/project-init/SKILL.md'"
assert "onboarding uses current inventory" "grep -q '35 skills' '$PROJECT_ROOT/skills/getting-started/SKILL.md' && grep -q '14 canonical Claude' '$PROJECT_ROOT/skills/getting-started/SKILL.md'"
assert "onboarding makes hooks optional" "grep -q 'Active hooks are optional' '$PROJECT_ROOT/skills/getting-started/SKILL.md'"
assert "portable skills do not recommend bypass flags" "! grep -RE -- '--yolo|--always-approve|dangerously-(skip|bypass)' '$PROJECT_ROOT/skills/director-mode' '$PROJECT_ROOT/skills/session-relay' '$PROJECT_ROOT/skills/handoff-claude' '$PROJECT_ROOT/skills/handoff-codex' '$PROJECT_ROOT/skills/handoff-grok'"
assert "README describes a new native receiving session" "grep -q 'receiver starts a new native session' '$PROJECT_ROOT/README.md'"
assert "version is 2.0.0" "[[ \$(tr -d '\\n' < '$PROJECT_ROOT/VERSION') == '2.0.0' ]]"
assert "Claude manifest version matches" "python3 -c 'import json; assert json.load(open(\"$PROJECT_ROOT/.claude-plugin/plugin.json\"))[\"version\"] == \"2.0.0\"'"
assert "Codex manifest version matches" "python3 -c 'import json; assert json.load(open(\"$PROJECT_ROOT/.codex-plugin/plugin.json\"))[\"version\"] == \"2.0.0\"'"

echo "Test: report-only CLI probe is executable"
assert "CLI probe has valid shell syntax" "bash -n '$PROJECT_ROOT/skills/interop-router/scripts/check_cli_available.sh'"
assert "CLI probe remains report-only" "bash '$PROJECT_ROOT/skills/interop-router/scripts/check_cli_available.sh' --json | python3 -c 'import json,sys; assert json.load(sys.stdin)[\"behavior\"] == \"report-only\"'"

echo "Test: advisory hook can only add context"
hook_output="$(printf 'not json' | "$PROJECT_ROOT/hooks/advisory.sh" claude)"
hook_status=$?
assert "advisory exits zero" "[[ $hook_status -eq 0 ]]"
assert "advisory emits additionalContext" "[[ '$hook_output' == *'additionalContext'* ]]"
assert "advisory emits no decision field" "[[ '$hook_output' != *'\"decision\"'* ]]"
assert "advisory emits no permission mutation" "[[ '$hook_output' != *'permissionDecision'* ]]"
codex_hook_output="$(printf '{}' | "$PROJECT_ROOT/hooks/advisory.sh" codex)"
assert "Codex advisory emits model context" "[[ '$codex_hook_output' == *'additionalContext'* ]]"
assert "default installer selects no hooks" "grep -q '^HOOK_MODE=\"none\"' '$PROJECT_ROOT/install.sh'"
assert "Grok inert passive hook is not registered" "! grep -q 'director-mode.json' '$PROJECT_ROOT/scripts/install-portable.py'"

if [[ $FAILURES -gt 0 ]]; then
    printf '%d assertion(s) failed\n' "$FAILURES"
    exit 1
fi
echo "All assertions passed"
