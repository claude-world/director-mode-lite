#!/usr/bin/env bash
# check_cli_available.sh - Check which external AI CLIs are available
# Usage: ./check_cli_available.sh [--json]

set -euo pipefail

JSON_OUTPUT=false
[[ "${1:-}" == "--json" ]] && JSON_OUTPUT=true

check_command() {
    local cmd="$1"
    local version_flag="${2:---version}"

    if command -v "$cmd" &>/dev/null; then
        local version
        version=$("$cmd" $version_flag 2>&1 | head -1 || echo "unknown")
        echo "available|$version"
    else
        echo "not_found|"
    fi
}

# Check Codex CLI
codex_result=$(check_command "codex" "--version")
codex_status="${codex_result%%|*}"
codex_version="${codex_result#*|}"

# Check Gemini CLI
gemini_result=$(check_command "gemini" "--version")
gemini_status="${gemini_result%%|*}"
gemini_version="${gemini_result#*|}"

# Check for API keys
has_openai_key=false
has_google_key=false

[[ -n "${OPENAI_API_KEY:-}" ]] && has_openai_key=true
[[ -n "${GOOGLE_API_KEY:-}" || -n "${GEMINI_API_KEY:-}" ]] && has_google_key=true

# Check for subscription-based authentication
codex_logged_in=false
gemini_logged_in=false

if [ "$codex_status" == "available" ]; then
    if codex login status 2>&1 | grep -q "Logged in" 2>/dev/null; then
        codex_logged_in=true
    fi
fi

if [ "$gemini_status" == "available" ]; then
    if [[ -f "$HOME/.gemini/oauth_creds.json" ]]; then
        gemini_logged_in=true
    fi
fi

# Effective auth: API key OR subscription login
codex_auth=$( ($has_openai_key || $codex_logged_in) && echo true || echo false )
gemini_auth=$( ($has_google_key || $gemini_logged_in) && echo true || echo false )

# Check auto-interop flag
auto_interop_enabled=false
if [[ -f ".claude/flags/auto-interop.json" ]]; then
    if grep -q '"enabled".*true' .claude/flags/auto-interop.json 2>/dev/null; then
        auto_interop_enabled=true
    fi
elif [[ -f "$HOME/.claude/flags/auto-interop.json" ]]; then
    if grep -q '"enabled".*true' "$HOME/.claude/flags/auto-interop.json" 2>/dev/null; then
        auto_interop_enabled=true
    fi
fi

if $JSON_OUTPUT; then
    cat <<EOF
{
  "codex": {
    "available": $([ "$codex_status" == "available" ] && echo true || echo false),
    "version": "$codex_version",
    "authenticated": $codex_auth
  },
  "gemini": {
    "available": $([ "$gemini_status" == "available" ] && echo true || echo false),
    "version": "$gemini_version",
    "authenticated": $gemini_auth
  },
  "api_keys": {
    "openai": $has_openai_key,
    "google": $has_google_key
  },
  "auto_interop_enabled": $auto_interop_enabled,
  "recommended": "$(
    if [ "$codex_status" == "available" ] && $codex_auth; then
        echo "codex"
    elif [ "$gemini_status" == "available" ] && $gemini_auth; then
        echo "gemini"
    else
        echo "none"
    fi
  )"
}
EOF
else
    echo "=== External AI CLI Availability ==="
    echo ""
    echo "Codex CLI:  ${codex_status} ${codex_version:+($codex_version)}"
    echo "Gemini CLI: ${gemini_status} ${gemini_version:+($gemini_version)}"
    echo ""
    echo "=== Authentication ==="
    echo "Codex:  $( $codex_auth && echo 'authenticated' || echo 'not authenticated' )"
    echo "Gemini: $( $gemini_auth && echo 'authenticated' || echo 'not authenticated' )"
    echo ""
    echo "=== Configuration ==="
    echo "Auto-interop: $( $auto_interop_enabled && echo 'enabled' || echo 'disabled' )"
    echo ""
    echo "=== Recommendation ==="
    if [ "$codex_status" == "available" ] && $codex_auth; then
        echo "Ready: Codex CLI available (interop-router will auto-route when appropriate)"
    elif [ "$gemini_status" == "available" ] && $gemini_auth; then
        echo "Ready: Gemini CLI available (interop-router will auto-route when appropriate)"
    else
        echo "No external CLI ready. Install and authenticate codex or gemini CLI."
    fi
fi
