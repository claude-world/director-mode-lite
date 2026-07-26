#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
RELAY="$PROJECT_ROOT/scripts/director-relay.py"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/director-mode-relay.XXXXXX")"
FAILURES=0

cleanup() { rm -rf "$TEST_ROOT"; }
trap cleanup EXIT

assert() {
    if eval "$2"; then printf '  PASS %s\n' "$1"; else printf '  FAIL %s\n' "$1"; FAILURES=$((FAILURES + 1)); fi
}

assert_prefix() {
    local description="$1" value="$2" prefix="$3"
    if [[ "$value" == "$prefix"* ]]; then
        printf '  PASS %s\n' "$description"
    else
        printf '  FAIL %s\n' "$description"
        FAILURES=$((FAILURES + 1))
    fi
}

assert_contains() {
    local description="$1" value="$2" needle="$3"
    if [[ "$value" == *"$needle"* ]]; then
        printf '  PASS %s\n' "$description"
    else
        printf '  FAIL %s\n' "$description"
        FAILURES=$((FAILURES + 1))
    fi
}

assert_not_contains() {
    local description="$1" value="$2" needle="$3"
    if [[ "$value" != *"$needle"* ]]; then
        printf '  PASS %s\n' "$description"
    else
        printf '  FAIL %s\n' "$description"
        FAILURES=$((FAILURES + 1))
    fi
}

git -C "$TEST_ROOT" init -q
git -C "$TEST_ROOT" config user.name "Director Test"
git -C "$TEST_ROOT" config user.email "director@example.invalid"
printf 'base\n' > "$TEST_ROOT/app.txt"
git -C "$TEST_ROOT" add app.txt
git -C "$TEST_ROOT" commit -qm "test: base"
printf 'changed\n' >> "$TEST_ROOT/app.txt"
printf 'xai-secret-that-must-not-enter-packet\n' > "$TEST_ROOT/local-secret.txt"

echo "Test: relay creates portable JSON and Markdown"
cd "$TEST_ROOT"
"$RELAY" create \
    --from claude --to codex \
    --session-id claude-native-123 \
    --goal "Finish relay test" \
    --summary "One tracked file changed" \
    --completed "Created the base implementation" \
    --decision "Use portable state instead of vendor transcripts" \
    --next "Review the working tree" \
    --verification "Base commit exists" \
    --note "Keep native controls" >/dev/null

packet="$TEST_ROOT/.director-mode/handoffs/latest.json"
markdown="$TEST_ROOT/.director-mode/handoffs/latest.md"
assert "latest JSON exists" "[[ -f '$packet' ]]"
assert "latest Markdown exists" "[[ -f '$markdown' ]]"
assert "packet validates" "'$RELAY' validate '$packet' >/dev/null"
assert "protocol is recorded" "python3 -c 'import json; assert json.load(open(\"$packet\"))[\"protocol\"] == \"director-handoff/v1\"'"
assert "source CLI is recorded" "python3 -c 'import json; assert json.load(open(\"$packet\"))[\"source\"][\"cli\"] == \"claude\"'"
assert "target CLI is recorded" "python3 -c 'import json; assert json.load(open(\"$packet\"))[\"target\"][\"cli\"] == \"codex\"'"
assert "packet is unreviewed by default" "python3 -c 'import json; assert json.load(open(\"$packet\"))[\"privacy\"][\"review_status\"] == \"unreviewed\"'"
assert "privacy capture is metadata-only" "python3 -c 'import json; p=json.load(open(\"$packet\"))[\"privacy\"]; assert p[\"capture_mode\"] == \"git-metadata-only\" and p[\"raw_transcript_included\"] is False and p[\"file_contents_included\"] is False'"
assert "Git status captures paths" "grep -q 'app.txt' '$packet'"
assert "file contents are not captured" "! grep -q 'xai-secret-that-must-not-enter-packet' '$packet'"
assert "Markdown explains new native session" "grep -q 'new native codex session' '$markdown'"

echo "Test: relay prints native receiving commands without running them"
codex_command="$("$RELAY" continue --to codex)"
grok_command="$("$RELAY" continue --to grok --headless)"
grok_interactive="$("$RELAY" continue --to grok)"
claude_command="$("$RELAY" command --to claude)"
assert_prefix "Codex interactive command printed" "$codex_command" "codex "
assert_prefix "Grok headless command printed" "$grok_command" "grok --no-auto-update -p "
assert_prefix "Grok interactive command printed" "$grok_interactive" "grok "
assert_not_contains "Grok interactive command uses no invalid rules flag" "$grok_interactive" "--rules"
assert_prefix "Claude interactive command printed" "$claude_command" "claude "
assert_contains "commands use validated JSON packet" "$codex_command" "latest.json"

printf '# unrelated modified rendering\n' > "$markdown"
command_after_markdown_edit="$("$RELAY" continue --to codex)"
assert_contains "Markdown edits cannot redirect receiving input" "$command_after_markdown_edit" "latest.json"

echo "Test: reviewed packets and subdirectory calls use the project handoff directory"
mkdir -p "$TEST_ROOT/packages/app"
"$RELAY" --cwd "$TEST_ROOT/packages/app" create \
    --from grok --to claude --goal "Subdirectory relay" --summary "Ready" \
    --next "Inspect root" --reviewed >/dev/null
assert "subdirectory call writes at Git root" "[[ -f '$TEST_ROOT/.director-mode/handoffs/latest.json' && ! -e '$TEST_ROOT/packages/app/.director-mode' ]]"
assert "review flag is recorded" "python3 -c 'import json; assert json.load(open(\"$TEST_ROOT/.director-mode/handoffs/latest.json\"))[\"privacy\"][\"review_status\"] == \"reviewed\"'"

echo "Test: malformed and unsupported packets fail cleanly"
printf '{"protocol":"unknown"}\n' > "$TEST_ROOT/bad.json"
bad_status=0
"$RELAY" validate "$TEST_ROOT/bad.json" >/dev/null 2>&1 || bad_status=$?
assert "unsupported packet exits two" "[[ $bad_status -eq 2 ]]"

python3 - "$TEST_ROOT/.director-mode/handoffs/latest.json" "$TEST_ROOT/extra.json" "$TEST_ROOT/date.json" "$TEST_ROOT/type.json" <<'PY'
import copy
import json
import pathlib
import sys

source = json.loads(pathlib.Path(sys.argv[1]).read_text())
extra = copy.deepcopy(source)
extra["unexpected"] = True
pathlib.Path(sys.argv[2]).write_text(json.dumps(extra))
bad_date = copy.deepcopy(source)
bad_date["created_at"] = "not-a-date"
pathlib.Path(sys.argv[3]).write_text(json.dumps(bad_date))
bad_type = copy.deepcopy(source)
bad_type["workspace"]["status_truncated"] = "false"
pathlib.Path(sys.argv[4]).write_text(json.dumps(bad_type))
PY
for invalid in extra date type; do
    invalid_status=0
    "$RELAY" validate "$TEST_ROOT/$invalid.json" >/dev/null 2>&1 || invalid_status=$?
    assert "$invalid packet is rejected" "[[ $invalid_status -eq 2 ]]"
done

if [[ $FAILURES -gt 0 ]]; then
    printf '%d assertion(s) failed\n' "$FAILURES"
    exit 1
fi
echo "All assertions passed"
