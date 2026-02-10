#!/usr/bin/env python3
"""
wrap_context.py - Wrap context for external AI CLIs with security filtering

Usage:
    python wrap_context.py [--files FILE...] [--diff] [--output FILE] [--json]
"""

import json
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

# Patterns that indicate secrets
SECRET_PATTERNS = [
    r'(?i)(api[_-]?key|apikey)\s*[=:]\s*["\']?[a-zA-Z0-9_-]{20,}',
    r'(?i)(secret|password|passwd|pwd)\s*[=:]\s*["\']?[^\s"\']{8,}',
    r'(?i)(token|bearer)\s*[=:]\s*["\']?[a-zA-Z0-9_-]{20,}',
    r'(?i)(aws[_-]?access[_-]?key[_-]?id)\s*[=:]\s*["\']?AK[A-Z0-9]{18}',
    r'(?i)(aws[_-]?secret[_-]?access[_-]?key)\s*[=:]\s*["\']?[a-zA-Z0-9/+=]{40}',
    r'-----BEGIN [A-Z]+ PRIVATE KEY-----',
    r'(?i)mongodb(\+srv)?://[^@]+:[^@]+@',
    r'(?i)postgres(ql)?://[^@]+:[^@]+@',
    r'(?i)mysql://[^@]+:[^@]+@',
    r'(?i)redis://:[^@]+@',
]

# Files to always skip
SKIP_FILES = {
    '.env', '.env.local', '.env.production', '.env.development',
    'credentials.json', 'service-account.json',
    '.npmrc', '.pypirc', '.netrc',
    'id_rsa', 'id_ed25519', 'id_dsa',
    '.git-credentials',
}

# Extensions to always skip
SKIP_EXTENSIONS = {
    '.pem', '.key', '.pfx', '.p12', '.jks',
    '.sqlite', '.db', '.sqlite3',
}


def should_skip_file(filepath):
    """Check if file should be skipped for security reasons."""
    path = Path(filepath)

    if path.name in SKIP_FILES:
        return True

    if path.suffix in SKIP_EXTENSIONS:
        return True

    sensitive_dirs = {'.git', 'node_modules', '__pycache__', '.venv', 'venv'}
    if any(part in sensitive_dirs for part in path.parts):
        return True

    return False


def redact_secrets(content):
    """Redact secrets from content. Returns (redacted_content, count)."""
    redacted_count = 0

    for pattern in SECRET_PATTERNS:
        matches = re.findall(pattern, content)
        if matches:
            redacted_count += len(matches)
            content = re.sub(pattern, '[REDACTED]', content)

    return content, redacted_count


def read_file_safe(filepath, max_lines=500):
    """Read file with safety checks."""
    result = {
        "path": filepath,
        "included": False,
        "content": "",
        "reason": "",
        "redacted_count": 0,
        "truncated": False
    }

    if should_skip_file(filepath):
        result["reason"] = "Skipped: sensitive file"
        return result

    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            lines = f.readlines()

        if len(lines) > max_lines:
            lines = lines[:max_lines]
            result["truncated"] = True

        content = ''.join(lines)
        content, redacted_count = redact_secrets(content)

        result["included"] = True
        result["content"] = content
        result["redacted_count"] = redacted_count
        result["line_count"] = len(lines)

    except Exception as e:
        result["reason"] = f"Error: {str(e)}"

    return result


def get_git_diff():
    """Get git diff with secrets redacted."""
    try:
        staged = subprocess.run(
            ['git', 'diff', '--staged'],
            capture_output=True, text=True, timeout=30
        )
        unstaged = subprocess.run(
            ['git', 'diff'],
            capture_output=True, text=True, timeout=30
        )

        diff = staged.stdout + unstaged.stdout
        diff, _ = redact_secrets(diff)
        return diff

    except Exception:
        return ""


def wrap_context(files, include_diff=False, max_lines=500):
    """Wrap context for external CLI."""
    context = {
        "wrapped_at": datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
        "files": [],
        "git_diff": "",
        "summary": {
            "total_files": len(files),
            "included_files": 0,
            "skipped_files": 0,
            "total_redactions": 0,
            "truncated_files": 0
        }
    }

    for filepath in files:
        file_result = read_file_safe(filepath, max_lines)
        context["files"].append(file_result)

        if file_result["included"]:
            context["summary"]["included_files"] += 1
            context["summary"]["total_redactions"] += file_result["redacted_count"]
            if file_result["truncated"]:
                context["summary"]["truncated_files"] += 1
        else:
            context["summary"]["skipped_files"] += 1

    if include_diff:
        context["git_diff"] = get_git_diff()

    return context


def format_for_cli(context):
    """Format context for CLI prompt."""
    output = []
    output.append("# Context for External AI CLI")
    output.append(f"# Generated: {context['wrapped_at']}")
    summary = context['summary']
    output.append(f"# Files: {summary['included_files']}/{summary['total_files']}")
    if summary['total_redactions'] > 0:
        output.append(f"# Redactions: {summary['total_redactions']} secrets removed")
    output.append("")

    for file_info in context["files"]:
        if file_info["included"]:
            output.append(f"## File: {file_info['path']}")
            if file_info["truncated"]:
                output.append(f"# (truncated to {file_info['line_count']} lines)")
            output.append("```")
            output.append(file_info["content"])
            output.append("```")
            output.append("")

    if context["git_diff"]:
        output.append("## Git Diff")
        output.append("```diff")
        output.append(context["git_diff"])
        output.append("```")

    return "\n".join(output)


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Wrap context for external AI CLIs")
    parser.add_argument("--files", nargs="+", default=[], help="Files to include")
    parser.add_argument("--diff", action="store_true", help="Include git diff")
    parser.add_argument("--output", help="Output file")
    parser.add_argument("--max-lines", type=int, default=500, help="Max lines per file")
    parser.add_argument("--json", action="store_true", help="Output as JSON")

    args = parser.parse_args()

    context = wrap_context(args.files, args.diff, args.max_lines)

    if args.json:
        output_text = json.dumps(context, indent=2)
    else:
        output_text = format_for_cli(context)

    if args.output:
        with open(args.output, 'w') as f:
            f.write(output_text)
        print(f"Written to {args.output}", file=sys.stderr)
    else:
        print(output_text)


if __name__ == "__main__":
    main()
