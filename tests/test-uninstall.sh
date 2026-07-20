#!/bin/bash
# Test: uninstall.sh hooks-only safety
# Verifies that option 1 removes only Director Mode hook files/configuration
# while preserving user hooks, project assets, and runtime state.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/director-mode-uninstall.XXXXXX")"
TEST_DIR="$TEST_ROOT/project"
FAILURES=0

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# shellcheck disable=SC2329  # Invoked indirectly by the EXIT trap.
cleanup() {
    rm -rf "$TEST_ROOT"
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

echo "Test: hooks-only uninstall preserves user files and state"
mkdir -p "$TEST_DIR"

# Install every hook family so the uninstall path also exercises the optional
# Evolving-Loop registrations. DML_WIZARD_FORCE lets the test feed answers
# without an interactive TTY.
printf '4\n2\nY\n' | DML_WIZARD_FORCE=1 \
    "$PROJECT_ROOT/install.sh" --wizard "$TEST_DIR" > /dev/null 2>&1

# Add a user-owned hook file and registration after installation.
printf '#!/bin/bash\nexit 0\n' > "$TEST_DIR/.claude/hooks/custom-project-hook.sh"
chmod +x "$TEST_DIR/.claude/hooks/custom-project-hook.sh"

SETTINGS_FILE="$TEST_DIR/.claude/settings.local.json" python3 - <<'PYEOF'
import json
import os

path = os.environ["SETTINGS_FILE"]
with open(path) as handle:
    settings = json.load(handle)

settings["customProjectSetting"] = "keep-me"
settings.setdefault("hooks", {}).setdefault("PostToolUse", []).append({
    "matcher": "Write",
    "hooks": [{
        "type": "command",
        "command": '"$CLAUDE_PROJECT_DIR"/.claude/hooks/custom-project-hook.sh',
    }],
})

with open(path, "w") as handle:
    json.dump(settings, handle, indent=2)
PYEOF

# Runtime state can contain checkpoints, changelog history, and learned data.
# A hooks-only uninstall must disable hooks without deleting that state.
mkdir -p \
    "$TEST_DIR/.auto-loop" \
    "$TEST_DIR/.director-mode" \
    "$TEST_DIR/.self-evolving-loop/memory"
printf '{"status":"in_progress"}\n' > "$TEST_DIR/.auto-loop/checkpoint.json"
printf '{"event":"keep"}\n' > "$TEST_DIR/.director-mode/changelog.jsonl"
printf 'keep learned state\n' > "$TEST_DIR/.self-evolving-loop/memory/user-note.md"

uninstall_status=0
if uninstall_output="$(printf '1\n' | "$PROJECT_ROOT/uninstall.sh" "$TEST_DIR" 2>&1)"; then
    :
else
    uninstall_status=$?
fi

assert "hooks-only uninstall exits successfully" "[[ $uninstall_status -eq 0 ]]"

for hook in \
    _lib-changelog.sh \
    auto-loop-stop.sh \
    log-bash-event.sh \
    log-file-change.sh \
    pre-tool-validator.sh; do
    assert "DML hook removed: $hook" "[[ ! -e '$TEST_DIR/.claude/hooks/$hook' ]]"
done

assert "user hook file is preserved" "[[ -x '$TEST_DIR/.claude/hooks/custom-project-hook.sh' ]]"
assert "shared hooks directory is preserved" "[[ -d '$TEST_DIR/.claude/hooks' ]]"
assert "agents are preserved" "[[ -f '$TEST_DIR/.claude/agents/code-reviewer.md' ]]"
assert "skills are preserved" "[[ -f '$TEST_DIR/.claude/skills/workflow/SKILL.md' ]]"

assert "Auto-Loop checkpoint is preserved" "[[ -f '$TEST_DIR/.auto-loop/checkpoint.json' ]]"
assert "changelog state is preserved" "[[ -f '$TEST_DIR/.director-mode/changelog.jsonl' ]]"
assert "Evolving-Loop state is preserved" "[[ -f '$TEST_DIR/.self-evolving-loop/memory/user-note.md' ]]"
assert "Evolving-Loop hook scripts are preserved for later re-enable" "[[ -x '$TEST_DIR/.self-evolving-loop/hooks/continue-loop.sh' ]]"

assert "settings remain valid JSON" "python3 -m json.tool '$TEST_DIR/.claude/settings.local.json' > /dev/null 2>&1"
assert "custom setting is preserved" "python3 -c 'import json; assert json.load(open(\"$TEST_DIR/.claude/settings.local.json\"))[\"customProjectSetting\"] == \"keep-me\"'"
assert "non-hook plansDirectory setting is preserved" "python3 -c 'import json; assert json.load(open(\"$TEST_DIR/.claude/settings.local.json\"))[\"plansDirectory\"] == \".claude/plans\"'"
assert "custom hook registration is preserved" "grep -q 'custom-project-hook.sh' '$TEST_DIR/.claude/settings.local.json'"
assert "core DML hook registrations are removed" "! grep -Eq 'auto-loop-stop|log-bash-event|log-file-change|pre-tool-validator' '$TEST_DIR/.claude/settings.local.json'"
assert "Evolving-Loop hook registrations are removed" "! grep -Eq 'continue-loop|log-event|phase-tracker' '$TEST_DIR/.claude/settings.local.json'"
assert "output reports preserved state" "[[ '$uninstall_output' == *'Runtime state'* ]]"
echo ""

if [[ $FAILURES -gt 0 ]]; then
    echo -e "${RED}$FAILURES assertion(s) failed${NC}"
    exit 1
fi

echo -e "${GREEN}All assertions passed${NC}"
exit 0
