#!/usr/bin/env bash
# Report available first-class CLIs. This script never launches or configures one.

set -euo pipefail

JSON_OUTPUT=false
[[ "${1:-}" == "--json" ]] && JSON_OUTPUT=true

probe() {
    local name="$1"
    if command -v "$name" >/dev/null 2>&1; then
        local version
        version="$("$name" --version 2>&1 | head -1 || true)"
        printf 'true|%s\n' "$version"
    else
        printf 'false|\n'
    fi
}

claude_result="$(probe claude)"
codex_result="$(probe codex)"
grok_result="$(probe grok)"

if $JSON_OUTPUT; then
    CLAUDE_RESULT="$claude_result" CODEX_RESULT="$codex_result" GROK_RESULT="$grok_result" python3 - <<'PY'
import json
import os

def value(name):
    available, version = os.environ[name].split("|", 1)
    return {"available": available == "true", "version": version}

print(json.dumps({
    "claude": value("CLAUDE_RESULT"),
    "codex": value("CODEX_RESULT"),
    "grok": value("GROK_RESULT"),
    "behavior": "report-only",
}, indent=2))
PY
else
    echo "=== AI CLI availability (report only) ==="
    printf 'Claude Code: %s\n' "${claude_result#*|}"
    printf 'Codex CLI:   %s\n' "${codex_result#*|}"
    printf 'Grok Build:  %s\n' "${grok_result#*|}"
    echo "No CLI was launched and no permission or routing setting was changed."
fi
