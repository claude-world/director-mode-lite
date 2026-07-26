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

add_custom_hook_state() {
    local target="$1"
    mkdir -p "$target/.claude/hooks" "$target/.codex/hooks" "$target/.grok/hooks"
    printf '#!/usr/bin/env bash\nexit 0\n' > "$target/.claude/hooks/custom.sh"
    printf '#!/usr/bin/env bash\nexit 0\n' > "$target/.codex/hooks/custom.sh"
    printf '#!/usr/bin/env bash\nexit 0\n' > "$target/.grok/hooks/custom.sh"
    chmod +x \
        "$target/.claude/hooks/custom.sh" \
        "$target/.codex/hooks/custom.sh" \
        "$target/.grok/hooks/custom.sh"

    python3 - "$target" <<'PY'
import json
from pathlib import Path
import sys

root = Path(sys.argv[1])
configs = (
    (Path(".claude/settings.local.json"), "bash .claude/hooks/custom.sh"),
    (Path(".codex/hooks.json"), "bash .codex/hooks/custom.sh"),
    (Path(".grok/hooks/director-mode.json"), "bash .grok/hooks/custom.sh"),
)
for relative, custom_command in configs:
    path = root / relative
    data = json.loads(path.read_text()) if path.is_file() else {}
    entries = data.setdefault("hooks", {}).setdefault("SessionStart", [])
    if entries and isinstance(entries[0], dict) and isinstance(entries[0].get("hooks"), list):
        entry = entries[0]
    else:
        entry = {"matcher": "startup", "hooks": []}
        entries.append(entry)
    if relative.parts[0] == ".grok":
        entry["hooks"].append({
            "type": "command",
            "command": "bash .director-mode/hooks/advisory.sh grok",
        })
    entry["hooks"].append({"type": "command", "command": custom_command})
    data["customSetting"] = "keep"
    path.write_text(json.dumps(data, indent=2) + "\n")
PY
}

echo "Test: default install creates three-CLI adapters with zero active hooks"
target="$(fresh_target default)"
"$PROJECT_ROOT/install.sh" "$target" >/dev/null
assert "shared guidance installed" "[[ -f '$target/.director-mode/GUIDANCE.md' ]]"
assert "relay executable installed" "[[ -x '$target/.director-mode/bin/director-relay' ]]"
assert "open permission launcher installed" "[[ -x '$target/.director-mode/bin/director-open' ]]"
assert "read-only doctor installed" "[[ -x '$target/.director-mode/bin/director-doctor' ]]"
assert "doctor reports read-only mode" "'$target/.director-mode/bin/director-doctor' --cwd '$target' --json --no-probe | python3 -c 'import json,sys; assert json.load(sys.stdin)[\"mode\"] == \"read-only\"'"
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
assert "Claude advisory match is exact" "python3 '$PROJECT_ROOT/scripts/director-hooks.py' check-advisory --config '$target/.claude/settings.local.json' >/dev/null"
assert "Codex advisory match is exact" "python3 '$PROJECT_ROOT/scripts/director-hooks.py' check-advisory --config '$target/.codex/hooks.json' >/dev/null"

echo "Test: a similarly named custom advisory cannot suppress Director registration"
target="$(fresh_target custom-advisory-name)"
mkdir -p "$target/.claude/hooks" "$target/.claude"
printf '#!/usr/bin/env bash\nexit 0\n' > "$target/.claude/hooks/company-advisory.sh"
printf '%s\n' '{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"bash .claude/hooks/company-advisory.sh"}]}]}}' \
    > "$target/.claude/settings.local.json"
"$PROJECT_ROOT/install.sh" --cli claude --hooks guide "$target" >/dev/null
assert "custom advisory remains registered" "grep -q '.claude/hooks/company-advisory.sh' '$target/.claude/settings.local.json'"
assert "exact Director advisory is also registered" "python3 '$PROJECT_ROOT/scripts/director-hooks.py' check-advisory --config '$target/.claude/settings.local.json' >/dev/null"

echo "Test: pre-existing same-name generic hooks remain user-owned"
target="$(fresh_target user-owned-generic-hook)"
mkdir -p "$target/.claude/hooks" "$target/.claude"
printf '#!/usr/bin/env bash\n# USER OWNED\nexit 0\n' > "$target/.claude/hooks/log-file-change.sh"
chmod +x "$target/.claude/hooks/log-file-change.sh"
printf '%s\n' '{"hooks":{"PostToolUse":[{"hooks":[{"type":"command","command":"bash .claude/hooks/log-file-change.sh"}]}]}}' \
    > "$target/.claude/settings.local.json"
"$PROJECT_ROOT/install.sh" --hooks none "$target" >/dev/null
assert "unowned same-name hook passes zero-hook check" "python3 '$PROJECT_ROOT/scripts/director-hooks.py' check-none --target '$target' >/dev/null"
"$PROJECT_ROOT/install.sh" --update --hooks none "$target" >/dev/null
assert "unowned same-name asset survives update" "grep -q 'USER OWNED' '$target/.claude/hooks/log-file-change.sh'"
assert "unowned same-name registration survives update" "grep -q '.claude/hooks/log-file-change.sh' '$target/.claude/settings.local.json'"

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

echo "Test: automation preserves pre-existing unowned same-name hooks"
target="$(fresh_target automation-hook-conflict)"
mkdir -p "$target/.claude/hooks"
printf '#!/usr/bin/env bash\n# USER CURRENT HOOK\nexit 0\n' > "$target/.claude/hooks/log-file-change.sh"
printf '#!/usr/bin/env bash\n# USER DEPRECATED HOOK\nexit 0\n' > "$target/.claude/hooks/log-commit.sh"
chmod +x "$target/.claude/hooks/log-file-change.sh" "$target/.claude/hooks/log-commit.sh"
automation_output="$("$PROJECT_ROOT/install.sh" --hooks automation "$target")"
assert "same-name current hook content is preserved" "grep -q 'USER CURRENT HOOK' '$target/.claude/hooks/log-file-change.sh'"
assert "same-name deprecated hook is not deleted" "grep -q 'USER DEPRECATED HOOK' '$target/.claude/hooks/log-commit.sh'"
assert "automation reports current hook conflict" "[[ '$automation_output' == *'Preserved user-owned hook conflict: .claude/hooks/log-file-change.sh'* ]]"
assert "automation reports deprecated hook conflict" "[[ '$automation_output' == *'Preserved user-owned deprecated hook conflict: .claude/hooks/log-commit.sh'* ]]"
assert "pre-existing current hook remains unowned" "python3 - '$target/.director-mode/install-ownership.json' <<'PY'
import json, sys
files = json.load(open(sys.argv[1]))['files']
assert '.claude/hooks/log-file-change.sh' not in files
PY"

echo "Test: guide update to none removes Director hooks and preserves custom hooks"
target="$(fresh_target guide-to-none)"
"$PROJECT_ROOT/install.sh" --hooks guide "$target" >/dev/null
add_custom_hook_state "$target"
"$PROJECT_ROOT/install.sh" --update --hooks none "$target" >/dev/null
assert "guide advisory executable removed" "[[ ! -e '$target/.director-mode/hooks/advisory.sh' ]]"
assert "guide registrations removed" "python3 '$PROJECT_ROOT/scripts/director-hooks.py' check-none --target '$target' >/dev/null"
assert "custom Claude hook preserved after guide migration" "grep -q '.claude/hooks/custom.sh' '$target/.claude/settings.local.json' && [[ -x '$target/.claude/hooks/custom.sh' ]]"
assert "custom Codex hook preserved after guide migration" "grep -q '.codex/hooks/custom.sh' '$target/.codex/hooks.json' && [[ -x '$target/.codex/hooks/custom.sh' ]]"
assert "custom Grok hook preserved after guide migration" "grep -q '.grok/hooks/custom.sh' '$target/.grok/hooks/director-mode.json' && [[ -x '$target/.grok/hooks/custom.sh' ]]"
verify_status=0
"$PROJECT_ROOT/scripts/verify-install.sh" --hooks none "$target" >/dev/null || verify_status=$?
assert "guide to none verifies as zero-hook" "[[ $verify_status -eq 0 ]]"

echo "Test: automation update to none removes legacy hooks and preserves custom hooks"
target="$(fresh_target automation-to-none)"
"$PROJECT_ROOT/install.sh" --hooks automation "$target" >/dev/null
add_custom_hook_state "$target"
"$PROJECT_ROOT/install.sh" --update --hooks none "$target" >/dev/null
assert "legacy hook executables removed" "[[ ! -e '$target/.claude/hooks/auto-loop-stop.sh' && ! -e '$target/.claude/hooks/log-bash-event.sh' && ! -e '$target/.claude/hooks/log-file-change.sh' && ! -e '$target/.claude/hooks/pre-tool-validator.sh' ]]"
assert "evolving-loop hook assets removed" "[[ ! -e '$target/.self-evolving-loop/hooks/continue-loop.sh' && ! -e '$target/.self-evolving-loop/hooks/log-event.sh' && ! -e '$target/.self-evolving-loop/hooks/phase-tracker.sh' && ! -e '$target/.self-evolving-loop/hooks/settings-hooks.json' ]]"
assert "non-hook evolving-loop templates preserved" "[[ -d '$target/.self-evolving-loop/templates' ]]"
assert "automation registrations removed" "python3 '$PROJECT_ROOT/scripts/director-hooks.py' check-none --target '$target' >/dev/null"
assert "custom hooks preserved after automation migration" "grep -q '.claude/hooks/custom.sh' '$target/.claude/settings.local.json' && grep -q '.codex/hooks/custom.sh' '$target/.codex/hooks.json' && grep -q '.grok/hooks/custom.sh' '$target/.grok/hooks/director-mode.json'"
verify_status=0
"$PROJECT_ROOT/scripts/verify-install.sh" --hooks none "$target" >/dev/null || verify_status=$?
assert "automation to none verifies as zero-hook" "[[ $verify_status -eq 0 ]]"

echo "Test: guidance-only update preserves a locally modified owned hook asset"
target="$(fresh_target modified-hook-to-none)"
"$PROJECT_ROOT/install.sh" --hooks automation "$target" >/dev/null
printf '\n# LOCAL HOOK CHANGE\n' >> "$target/.claude/hooks/auto-loop-stop.sh"
"$PROJECT_ROOT/install.sh" --update --hooks none "$target" >/dev/null
assert "modified owned hook asset is preserved" "grep -q '# LOCAL HOOK CHANGE' '$target/.claude/hooks/auto-loop-stop.sh'"
assert "modified hook registration is still removed" "! grep -q 'auto-loop-stop.sh' '$target/.claude/settings.local.json'"
hook_check_status=0
python3 "$PROJECT_ROOT/scripts/director-hooks.py" check-none --target "$target" >/dev/null 2>&1 || hook_check_status=$?
assert "zero-hook check reports the preserved Director asset" "[[ $hook_check_status -eq 1 ]]"

echo "Test: existing files are preserved unless --update is used"
target="$(fresh_target update)"
"$PROJECT_ROOT/install.sh" "$target" >/dev/null
printf '\n# LOCAL\n' >> "$target/.claude/skills/director-mode/SKILL.md"
printf '\n# LOCAL RUNTIME\n' >> "$target/.director-mode/GUIDANCE.md"
printf 'CLAUDE USER EXTRA\n' > "$target/.claude/skills/director-mode/user-notes.txt"
printf 'CODEX USER EXTRA\n' > "$target/.agents/skills/director-mode/user-notes.txt"
"$PROJECT_ROOT/install.sh" "$target" >/dev/null
assert "plain install preserves local skill edit" "grep -q '# LOCAL' '$target/.claude/skills/director-mode/SKILL.md'"
assert "plain install preserves runtime guide edit" "grep -q '# LOCAL RUNTIME' '$target/.director-mode/GUIDANCE.md'"
"$PROJECT_ROOT/install.sh" --update "$target" >/dev/null
assert "update restores distributed skill" "diff -q '$PROJECT_ROOT/skills/director-mode/SKILL.md' '$target/.claude/skills/director-mode/SKILL.md' >/dev/null"
assert "update restores runtime guide" "diff -q '$PROJECT_ROOT/portable/GUIDANCE.md' '$target/.director-mode/GUIDANCE.md' >/dev/null"
assert "Claude skill update preserves user extras" "grep -q 'CLAUDE USER EXTRA' '$target/.claude/skills/director-mode/user-notes.txt'"
assert "Codex skill update preserves user extras" "grep -q 'CODEX USER EXTRA' '$target/.agents/skills/director-mode/user-notes.txt'"
assert "ownership manifest exists" "python3 -m json.tool '$target/.director-mode/install-ownership.json' >/dev/null"

echo "Test: managed writes reject destination and ancestor symlinks"
outside_file="$TEST_ROOT/outside-guidance.txt"
printf 'EXTERNAL SENTINEL\n' > "$outside_file"
target="$(fresh_target final-symlink)"
mkdir -p "$target/.director-mode"
ln -s "$outside_file" "$target/.director-mode/GUIDANCE.md"
symlink_status=0
symlink_output="$("$PROJECT_ROOT/install.sh" --update "$target" 2>&1)" || symlink_status=$?
assert "destination symlink aborts install" "[[ $symlink_status -ne 0 ]]"
assert "destination symlink cannot overwrite external file" "[[ \"\$(cat '$outside_file')\" == 'EXTERNAL SENTINEL' ]]"
assert "destination symlink error is explicit" "[[ '$symlink_output' == *'managed path contains a symlink'* ]]"

outside_dir="$TEST_ROOT/outside-agents"
mkdir -p "$outside_dir"
printf 'ANCESTOR SENTINEL\n' > "$outside_dir/sentinel.txt"
target="$(fresh_target ancestor-symlink)"
ln -s "$outside_dir" "$target/.agents"
ancestor_status=0
ancestor_output="$("$PROJECT_ROOT/install.sh" --update "$target" 2>&1)" || ancestor_status=$?
assert "ancestor symlink aborts install" "[[ $ancestor_status -ne 0 ]]"
assert "ancestor symlink cannot create external skill tree" "[[ ! -e '$outside_dir/skills' ]] && grep -q 'ANCESTOR SENTINEL' '$outside_dir/sentinel.txt'"
assert "ancestor symlink error is explicit" "[[ '$ancestor_output' == *'managed path contains a symlink'* ]]"

outside_file="$TEST_ROOT/outside-hardlink.txt"
printf 'HARDLINK SENTINEL\n' > "$outside_file"
target="$(fresh_target final-hardlink)"
mkdir -p "$target/.director-mode"
ln "$outside_file" "$target/.director-mode/GUIDANCE.md"
hardlink_status=0
hardlink_output="$("$PROJECT_ROOT/install.sh" --update "$target" 2>&1)" || hardlink_status=$?
assert "destination hard link aborts install" "[[ $hardlink_status -ne 0 ]]"
assert "destination hard link cannot overwrite external inode" "[[ \"\$(cat '$outside_file')\" == 'HARDLINK SENTINEL' ]]"
assert "destination hard link error is explicit" "[[ '$hardlink_output' == *'multiple hard links'* ]]"

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
