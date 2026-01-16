#!/bin/bash
# Pre-Tool Validator Hook - Adds context for protected files
# Director Mode Lite
#
# PreToolUse hook for Write and Edit tools
# Returns additionalContext to guide Claude about sensitive files
#
# Input: JSON via stdin (Claude Code PreToolUse format)
# Output: JSON with decision field (required) + optional additionalContext
#
# Note: This hook provides guidance, not blocks. It adds context to help
# Claude make better decisions about sensitive file modifications.

# Never exit on errors
set +e

# Check for jq availability
HAS_JQ=false
command -v jq &>/dev/null && HAS_JQ=true

# Read JSON from stdin
INPUT=$(cat 2>/dev/null) || INPUT=""
[[ -z "$INPUT" ]] && exit 0

# Parse tool name and file path
if $HAS_JQ; then
    TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null) || TOOL_NAME=""
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null) || FILE_PATH=""
else
    TOOL_NAME=$(echo "$INPUT" | grep -o '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:.*"\([^"]*\)".*/\1/' 2>/dev/null) || TOOL_NAME=""
    FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:.*"\([^"]*\)".*/\1/' 2>/dev/null) || FILE_PATH=""
fi

# Only process Write and Edit tools
case "$TOOL_NAME" in
    Write|Edit) ;;
    *) exit 0 ;;
esac

# Exit if no file path
[[ -z "$FILE_PATH" ]] && exit 0

# Get filename for pattern matching
FILENAME=$(basename "$FILE_PATH" 2>/dev/null) || FILENAME="$FILE_PATH"

# Define protected file patterns and their guidance
get_additional_context() {
    local path="$1"
    local name="$2"

    # Environment files - contain secrets
    if [[ "$name" =~ ^\.env(\.|$) ]] || [[ "$name" == ".env" ]]; then
        echo "This is an environment file that may contain secrets. Never commit secrets to git. Use placeholder values if creating examples."
        return
    fi

    # Claude settings - may break tool
    if [[ "$path" =~ \.claude/settings\.local\.json$ ]] || [[ "$path" =~ \.claude/settings\.json$ ]]; then
        echo "This is a Claude Code settings file. Invalid JSON will break Claude Code. Ensure proper JSON format."
        return
    fi

    # Package lock files - usually auto-generated
    if [[ "$name" == "package-lock.json" ]] || [[ "$name" == "yarn.lock" ]] || [[ "$name" == "pnpm-lock.yaml" ]]; then
        echo "This is an auto-generated lockfile. Usually should not be manually edited. Use npm/yarn/pnpm commands instead."
        return
    fi

    # Git internal files
    if [[ "$path" =~ ^\.git/ ]] || [[ "$path" =~ /\.git/ ]]; then
        echo "This is a git internal file. Direct modification may corrupt the repository."
        return
    fi

    # CI/CD files
    if [[ "$path" =~ \.github/workflows/ ]] || [[ "$name" == ".gitlab-ci.yml" ]] || [[ "$name" == "Jenkinsfile" ]]; then
        echo "This is a CI/CD configuration file. Changes will affect automated pipelines. Test changes carefully."
        return
    fi

    # Docker files
    if [[ "$name" == "Dockerfile" ]] || [[ "$name" == "docker-compose.yml" ]] || [[ "$name" == "docker-compose.yaml" ]]; then
        echo "This is a Docker configuration file. Ensure base images are from trusted sources and no secrets are hardcoded."
        return
    fi

    # Credentials/auth files
    if [[ "$name" =~ credentials ]] || [[ "$name" =~ (^|\.)auth\. ]] || [[ "$name" =~ \.pem$ ]] || [[ "$name" =~ \.key$ ]]; then
        echo "This appears to be a credentials or key file. Never commit real credentials. Use environment variables or secrets management."
        return
    fi

    # Database migrations
    if [[ "$path" =~ migrations/ ]] || [[ "$path" =~ migrate/ ]]; then
        echo "This is a database migration file. Once deployed, migrations should not be modified. Create new migrations instead."
        return
    fi

    # No special context needed
    echo ""
}

# Get context for this file
CONTEXT=$(get_additional_context "$FILE_PATH" "$FILENAME")

# Output format per Claude Code Hooks guide:
# - Allow without context: exit 0 (no output)
# - Add context: {"hookSpecificOutput": {"hookEventName": "PreToolUse", "additionalContext": "..."}}
if [[ -n "$CONTEXT" ]]; then
    # Escape for JSON
    CONTEXT="${CONTEXT//\\/\\\\}"
    CONTEXT="${CONTEXT//\"/\\\"}"
    CONTEXT="${CONTEXT//$'\n'/\\n}"
    echo "{\"hookSpecificOutput\": {\"hookEventName\": \"PreToolUse\", \"additionalContext\": \"$CONTEXT\"}}"
fi

exit 0
