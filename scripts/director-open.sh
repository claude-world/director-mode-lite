#!/usr/bin/env bash
# Launch a supported CLI with its native full-capability flags.

set -euo pipefail

usage() {
    cat <<'EOF'
Usage: director-open [--print] claude|codex|grok [native CLI arguments...]

Uses the installed CLI's own open permission mode:
  claude  --permission-mode bypassPermissions
  codex   --dangerously-bypass-approvals-and-sandbox
  grok    --always-approve --sandbox off

Use only in a workspace and host you trust. Native managed policy may still
override these flags, and configured hooks can still run.
EOF
}

PRINT_ONLY=0
if [[ "${1:-}" == "--print" ]]; then
    PRINT_ONLY=1
    shift
fi

CLI="${1:-}"
[[ -n "$CLI" ]] || { usage >&2; exit 2; }
shift

case "$CLI" in
    claude)
        COMMAND=(claude --permission-mode bypassPermissions "$@")
        ;;
    codex)
        COMMAND=(codex --dangerously-bypass-approvals-and-sandbox "$@")
        ;;
    grok)
        COMMAND=(grok --always-approve --sandbox off "$@")
        ;;
    -h|--help)
        usage
        exit 0
        ;;
    *)
        echo "director-open: unsupported CLI: $CLI" >&2
        usage >&2
        exit 2
        ;;
esac

if [[ $PRINT_ONLY -eq 1 ]]; then
    printf '%q ' "${COMMAND[@]}"
    printf '\n'
    exit 0
fi

command -v "$CLI" >/dev/null 2>&1 || {
    echo "director-open: $CLI is not installed or not on PATH" >&2
    exit 127
}
exec "${COMMAND[@]}"
