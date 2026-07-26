#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TARGET_DIR="."
CLI_TARGETS="all"
HOOK_MODE="none"
FAILURES=0
TARGET_SET=0

usage() {
    cat <<'EOF'
Usage: verify-install.sh [--cli all|claude|codex|grok]
                         [--hooks guide|none|automation]
                         [--allow-no-hooks] [target-dir]

Verify a project-local Director Mode Lite installation. --allow-no-hooks is an
alias for --hooks none.
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --cli)
            [[ $# -ge 2 ]] || { usage >&2; exit 2; }
            CLI_TARGETS="$2"
            shift
            ;;
        --cli=*) CLI_TARGETS="${1#*=}" ;;
        --hooks)
            [[ $# -ge 2 ]] || { usage >&2; exit 2; }
            HOOK_MODE="$2"
            shift
            ;;
        --hooks=*) HOOK_MODE="${1#*=}" ;;
        --allow-no-hooks) HOOK_MODE="none" ;;
        -h|--help) usage; exit 0 ;;
        -*) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
        *)
            [[ $TARGET_SET -eq 0 ]] || { echo "Only one target directory may be provided." >&2; exit 2; }
            TARGET_DIR="$1"
            TARGET_SET=1
            ;;
    esac
    shift
done

case "$CLI_TARGETS" in all|claude|codex|grok) ;; *) usage >&2; exit 2 ;; esac
case "$HOOK_MODE" in guide|none|automation) ;; *) usage >&2; exit 2 ;; esac

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

pass() { printf "%bPASS%b %s\n" "$GREEN" "$NC" "$1"; }
fail() { printf "%bFAIL%b %s\n" "$RED" "$NC" "$1"; FAILURES=$((FAILURES + 1)); }

check_file() {
    [[ -f "$1" ]] && pass "$2" || fail "$2 ($1 missing)"
}

check_dir() {
    [[ -d "$1" ]] && pass "$2" || fail "$2 ($1 missing)"
}

check_executable() {
    [[ -f "$1" && -x "$1" ]] && pass "$2" || fail "$2 ($1 missing or not executable)"
}

check_json() {
    if [[ -f "$1" ]] && python3 -m json.tool "$1" >/dev/null 2>&1; then
        pass "$2"
    else
        fail "$2 ($1 missing or invalid)"
    fi
}

selected() {
    [[ "$CLI_TARGETS" == "all" || "$CLI_TARGETS" == "$1" ]]
}

check_inventory_copy() {
    local source_dir="$1" target_dir="$2" label="$3" kind="$4"
    local source_file name missing=0 count=0
    if [[ "$kind" == "skills" ]]; then
        while IFS= read -r source_file; do
            count=$((count + 1))
            name="$(basename "$(dirname "$source_file")")"
            if [[ ! -f "$target_dir/$name/SKILL.md" ]]; then
                fail "$label includes $name"
                missing=1
            fi
        done < <(find "$source_dir" -mindepth 2 -maxdepth 2 -name SKILL.md -type f | sort)
    else
        while IFS= read -r source_file; do
            count=$((count + 1))
            name="$(basename "$source_file")"
            if [[ ! -f "$target_dir/$name" ]]; then
                fail "$label includes $name"
                missing=1
            fi
        done < <(find "$source_dir" -mindepth 1 -maxdepth 1 -name '*.md' -type f | sort)
    fi
    [[ $missing -eq 0 ]] && pass "$label has all $count shipped $kind"
}

check_advisory_registration() {
    local path="$1" label="$2"
    if [[ -f "$path" ]] && python3 "$PROJECT_ROOT/scripts/director-hooks.py" \
        check-advisory --config "$path" >/dev/null 2>&1; then
        pass "$label"
    else
        fail "$label ($path missing exact .director-mode advisory registration)"
    fi
}

if [[ ! -d "$TARGET_DIR" ]]; then
    fail "Target directory exists ($TARGET_DIR)"
    printf "\n%bInstallation verification failed%b\n" "$RED" "$NC"
    exit 1
fi
if ! command -v python3 >/dev/null 2>&1; then
    fail "python3 is available"
    exit 1
fi

printf "Verifying Director Mode Lite install in %s\n" "$TARGET_DIR"
printf "CLI adapters: %s | hooks: %s\n\n" "$CLI_TARGETS" "$HOOK_MODE"

check_file "$TARGET_DIR/CLAUDE.md" "CLAUDE.md exists"
check_file "$TARGET_DIR/AGENTS.md" "AGENTS.md exists"
check_file "$TARGET_DIR/.director-mode/GUIDANCE.md" "shared guidance exists"
check_json "$TARGET_DIR/.director-mode/handoff.schema.json" "handoff schema is valid JSON"
check_executable "$TARGET_DIR/.director-mode/bin/director-relay" "director-relay is executable"
check_executable "$TARGET_DIR/.director-mode/bin/director-open" "director-open is executable"
check_executable "$TARGET_DIR/.director-mode/bin/director-doctor" "director-doctor is executable"
if [[ "$HOOK_MODE" != "none" ]]; then
    check_executable "$TARGET_DIR/.director-mode/hooks/advisory.sh" "advisory hook adapter is executable"
fi

if ! grep -q 'director-mode-lite:start' "$TARGET_DIR/CLAUDE.md" 2>/dev/null; then
    fail "CLAUDE.md contains the managed guidance block"
else
    pass "CLAUDE.md contains the managed guidance block"
fi
if ! grep -q 'director-mode-lite:start' "$TARGET_DIR/AGENTS.md" 2>/dev/null; then
    fail "AGENTS.md contains the managed guidance block"
else
    pass "AGENTS.md contains the managed guidance block"
fi

# Claude-compatible assets are canonical for Claude and Grok, and are always
# installed so a project can switch between those two without duplication.
check_dir "$TARGET_DIR/.claude/skills" ".claude/skills exists"
check_dir "$TARGET_DIR/.claude/agents" ".claude/agents exists"
check_inventory_copy "$PROJECT_ROOT/skills" "$TARGET_DIR/.claude/skills" ".claude/skills" skills
check_inventory_copy "$PROJECT_ROOT/agents" "$TARGET_DIR/.claude/agents" ".claude/agents" agents

if selected codex; then
    check_dir "$TARGET_DIR/.agents/skills" ".agents/skills exists"
    check_dir "$TARGET_DIR/.codex/agents" ".codex/agents exists"
    check_inventory_copy "$PROJECT_ROOT/skills" "$TARGET_DIR/.agents/skills" ".agents/skills" skills
    codex_count="$(find "$TARGET_DIR/.codex/agents" -mindepth 1 -maxdepth 1 -name '*.toml' -type f | wc -l | tr -d ' ')"
    source_count="$(find "$PROJECT_ROOT/agents" -mindepth 1 -maxdepth 1 -name '*.md' -type f | wc -l | tr -d ' ')"
    [[ "$codex_count" == "$source_count" ]] && pass ".codex/agents has $source_count generated agents" || fail ".codex/agents count ($codex_count, expected $source_count)"
fi

if selected grok; then
    if [[ -d "$TARGET_DIR/.grok/skills" ]]; then
        fail "Grok reuses canonical Claude skills without a duplicate .grok/skills tree"
    else
        pass "Grok reuses canonical Claude skills without duplication"
    fi
    check_dir "$TARGET_DIR/.grok/agents" ".grok/agents exists"
    grok_count="$(find "$TARGET_DIR/.grok/agents" -mindepth 1 -maxdepth 1 -name '*.md' -type f | wc -l | tr -d ' ')"
    source_count="$(find "$PROJECT_ROOT/agents" -mindepth 1 -maxdepth 1 -name '*.md' -type f | wc -l | tr -d ' ')"
    [[ "$grok_count" == "$source_count" ]] && pass ".grok/agents has $source_count generated agents" || fail ".grok/agents count ($grok_count, expected $source_count)"
fi

if [[ "$HOOK_MODE" == "guide" ]]; then
    selected claude && { check_json "$TARGET_DIR/.claude/settings.local.json" "Claude hook settings are valid JSON"; check_advisory_registration "$TARGET_DIR/.claude/settings.local.json" "Claude advisory hook is registered"; }
    selected codex && { check_json "$TARGET_DIR/.codex/hooks.json" "Codex hooks are valid JSON"; check_advisory_registration "$TARGET_DIR/.codex/hooks.json" "Codex advisory hook is registered"; }
    if selected grok; then
        [[ ! -e "$TARGET_DIR/.grok/hooks/director-mode.json" ]] && pass "Grok has no inert passive hook" || fail "Grok has no inert passive hook"
    fi
elif [[ "$HOOK_MODE" == "automation" ]]; then
    for hook in _lib-changelog.sh auto-loop-stop.sh log-bash-event.sh log-file-change.sh pre-tool-validator.sh; do
        check_executable "$TARGET_DIR/.claude/hooks/$hook" "$hook is executable"
    done
    check_advisory_registration "$TARGET_DIR/.claude/settings.local.json" "Claude advisory hook remains registered with automation"
    grep -q 'auto-loop-stop.sh' "$TARGET_DIR/.claude/settings.local.json" 2>/dev/null && pass "Legacy Auto-Loop is registered" || fail "Legacy Auto-Loop is registered"
else
    hook_check_output=""
    if hook_check_output="$(python3 "$PROJECT_ROOT/scripts/director-hooks.py" check-none --target "$TARGET_DIR" 2>&1)"; then
        pass "zero-hook install has no Director Mode registrations or owned hook assets"
    else
        fail "zero-hook install has no Director Mode registrations or owned hook assets ($hook_check_output)"
    fi
fi

printf "\n"
if [[ $FAILURES -eq 0 ]]; then
    printf "%bInstallation verification passed%b\n" "$GREEN" "$NC"
    exit 0
fi

printf "%bInstallation verification failed (%d check(s))%b\n" "$RED" "$FAILURES" "$NC"
exit 1
