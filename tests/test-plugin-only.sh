#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
RELAY="$PROJECT_ROOT/skills/session-relay/scripts/director-relay.py"
DOCTOR="$PROJECT_ROOT/skills/director-mode/scripts/director-doctor.py"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/director-mode-plugin.XXXXXX")"
TEST_ROOT="$(cd "$TEST_ROOT" && pwd -P)"
FAILURES=0

cleanup() { rm -rf "$TEST_ROOT"; }
trap cleanup EXIT

assert() {
    if eval "$2"; then printf '  PASS %s\n' "$1"; else printf '  FAIL %s\n' "$1"; FAILURES=$((FAILURES + 1)); fi
}

assert "bundled relay matches the distributed runtime" "cmp -s '$PROJECT_ROOT/scripts/director-relay.py' '$RELAY'"
assert "bundled doctor matches the distributed runtime" "cmp -s '$PROJECT_ROOT/scripts/director-doctor.py' '$DOCTOR'"
assert "bundled guidance matches the portable guide" "cmp -s '$PROJECT_ROOT/portable/GUIDANCE.md' '$PROJECT_ROOT/skills/director-mode/references/GUIDANCE.md'"

git -C "$TEST_ROOT" init -q
git -C "$TEST_ROOT" config user.name "Plugin Test"
git -C "$TEST_ROOT" config user.email "plugin@example.invalid"
printf 'fixture\n' > "$TEST_ROOT/app.txt"
git -C "$TEST_ROOT" add app.txt
git -C "$TEST_ROOT" commit -qm "test: plugin fixture"

python3 "$RELAY" --cwd "$TEST_ROOT" create \
  --from grok --to claude --goal "Plugin-only continuation" \
  --summary "No project runtime is installed" --next "Inspect the fixture" >/dev/null
packet="$TEST_ROOT/.director-mode/handoffs/latest.json"
assert "plugin-bundled relay creates a v2 packet" "python3 - '$packet' <<'PY'
import json, sys
p = json.load(open(sys.argv[1]))
assert p['protocol'] == 'director-handoff/v2'
assert p['lineage']['route'] == ['grok', 'claude']
PY"
assert "plugin-bundled relay validates its packet" "python3 '$RELAY' validate '$packet' >/dev/null"
assert "plugin-bundled relay reports current status" "python3 '$RELAY' --cwd '$TEST_ROOT' status --json | python3 -c 'import json,sys; assert json.load(sys.stdin)[\"drift\"][\"head_matches\"] is True'"

doctor_report="$(python3 "$DOCTOR" --cwd "$TEST_ROOT" --json --no-probe)"
assert "plugin-bundled doctor remains read-only" "REPORT='$doctor_report' python3 -c 'import json,os; r=json.loads(os.environ[\"REPORT\"]); assert r[\"mode\"] == \"read-only\"'"

for skill in director-mode session-relay; do
  assert "$skill has Codex UI metadata" "[[ -f '$PROJECT_ROOT/skills/$skill/agents/openai.yaml' ]]"
  assert "$skill has valid eval JSON" "python3 -m json.tool '$PROJECT_ROOT/skills/$skill/evals/evals.json' >/dev/null"
done

if [[ $FAILURES -gt 0 ]]; then
    printf '%d assertion(s) failed\n' "$FAILURES"
    exit 1
fi
echo "All assertions passed"
