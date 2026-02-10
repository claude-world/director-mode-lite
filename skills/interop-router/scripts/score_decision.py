#!/usr/bin/env python3
"""
score_decision.py - Calculate routing decision score for external AI CLIs

Usage:
    python score_decision.py --task "task description" [--files N] [--complexity high|medium|low] [--json]
"""

import argparse
import json
import os
from pathlib import Path


def check_auto_interop_flag():
    """Check if auto-interop is enabled."""
    paths = [
        Path(".claude/flags/auto-interop.json"),
        Path(os.path.expanduser("~/.claude/flags/auto-interop.json"))
    ]

    for path in paths:
        if path.exists():
            try:
                with open(path) as f:
                    data = json.load(f)
                    return data.get("enabled", False)
            except Exception:
                pass

    return False


def calculate_benefit_score(task, file_count, complexity, timed_out):
    """Calculate benefit score (0.0 - 1.0)."""
    score = 0.0

    # File count factor
    if file_count >= 10:
        score += 0.35
    elif file_count >= 5:
        score += 0.25
    elif file_count >= 3:
        score += 0.15
    elif file_count >= 1:
        score += 0.05

    # Complexity factor
    complexity_scores = {"high": 0.25, "medium": 0.15, "low": 0.1}
    score += complexity_scores.get(complexity, 0.15)

    # Task type detection
    task_lower = task.lower()

    batch_keywords = [
        "batch", "bulk", "multiple", "all files", "refactor", "rename", "replace",
    ]
    if any(kw in task_lower for kw in batch_keywords):
        score += 0.2

    template_keywords = [
        "template", "generate", "scaffold", "boilerplate",
    ]
    if any(kw in task_lower for kw in template_keywords):
        score += 0.15

    impl_keywords = [
        "implement", "add", "create", "build", "write", "fix", "update",
    ]
    if any(kw in task_lower for kw in impl_keywords):
        score += 0.15

    # Previous timeout is a benefit for external CLI
    if timed_out:
        score += 0.2

    return min(score, 1.0)


def calculate_cost_score(file_count, has_secrets):
    """Calculate cost score (-0.3 - 0.0)."""
    score = 0.0

    if file_count >= 20:
        score -= 0.15
    elif file_count >= 10:
        score -= 0.1
    elif file_count >= 5:
        score -= 0.05

    if has_secrets:
        score -= 0.1

    # Review overhead
    score -= 0.05

    return max(score, -0.3)


def calculate_risk_score(task, write_required, has_secrets):
    """Calculate risk score (-0.3 - 0.0)."""
    score = 0.0

    task_lower = task.lower()

    if write_required:
        score -= 0.1

    if has_secrets:
        score -= 0.1

    destructive_keywords = ["delete", "remove", "drop", "destroy", "force"]
    if any(kw in task_lower for kw in destructive_keywords):
        score -= 0.15

    return max(score, -0.3)


def recommend_cli(task):
    """Recommend which CLI to use based on task."""
    task_lower = task.lower()

    codex_keywords = ["edit", "code", "implement", "fix", "debug", "refactor"]
    codex_score = sum(1 for kw in codex_keywords if kw in task_lower)

    gemini_keywords = ["explain", "analyze", "document", "review", "plan", "long"]
    gemini_score = sum(1 for kw in gemini_keywords if kw in task_lower)

    if gemini_score > codex_score:
        return "gemini"
    return "codex"


def calculate_decision(task, file_count=1, complexity="medium",
                       timed_out=False, write_required=True, has_secrets=False):
    """Calculate full routing decision."""
    benefit = calculate_benefit_score(task, file_count, complexity, timed_out)
    cost = calculate_cost_score(file_count, has_secrets)
    risk = calculate_risk_score(task, write_required, has_secrets)

    total_score = benefit + cost + risk
    auto_interop = check_auto_interop_flag()

    decision = {
        "scores": {
            "benefit": round(benefit, 2),
            "cost": round(cost, 2),
            "risk": round(risk, 2),
            "total": round(total_score, 2)
        },
        "auto_interop_enabled": auto_interop,
        "recommendation": {
            "action": "local",
            "cli": None,
            "reason": ""
        }
    }

    if total_score >= 0.15 and auto_interop:
        decision["recommendation"]["action"] = "auto_execute"
        decision["recommendation"]["cli"] = recommend_cli(task)
        decision["recommendation"]["reason"] = (
            f"Score {total_score:.2f} >= 0.15, auto-routing to external CLI"
        )
    else:
        decision["recommendation"]["action"] = "local"
        if not auto_interop:
            decision["recommendation"]["reason"] = "auto-interop disabled, handle locally"
        else:
            decision["recommendation"]["reason"] = (
                f"Score {total_score:.2f} < 0.15, handle locally"
            )

    return decision


def main():
    parser = argparse.ArgumentParser(description="Calculate routing decision score")
    parser.add_argument("--task", required=True, help="Task description")
    parser.add_argument("--files", type=int, default=1, help="Number of files")
    parser.add_argument("--complexity", choices=["high", "medium", "low"], default="medium")
    parser.add_argument("--timeout", action="store_true", help="Previous attempt timed out")
    parser.add_argument("--write", action="store_true", default=True, help="Write required")
    parser.add_argument("--secrets", action="store_true", help="Has secrets to filter")
    parser.add_argument("--json", action="store_true", help="JSON output")

    args = parser.parse_args()

    decision = calculate_decision(
        task=args.task,
        file_count=args.files,
        complexity=args.complexity,
        timed_out=args.timeout,
        write_required=args.write,
        has_secrets=args.secrets
    )

    if args.json:
        print(json.dumps(decision, indent=2))
    else:
        print("=" * 50)
        print("Routing Decision Analysis")
        print("=" * 50)
        print(f"\nTask: {args.task}")
        print(f"Files: {args.files}, Complexity: {args.complexity}")
        print()
        print("Scores:")
        scores = decision["scores"]
        print(f"  Benefit:  {scores['benefit']:+.2f} (0.0 to 0.6)")
        print(f"  Cost:     {scores['cost']:+.2f} (-0.3 to 0.0)")
        print(f"  Risk:     {scores['risk']:+.2f} (-0.3 to 0.0)")
        print(f"  Total:    {scores['total']:+.2f}")
        print()
        auto = decision["auto_interop_enabled"]
        print(f"Auto-interop: {'enabled' if auto else 'disabled'}")
        print()
        rec = decision["recommendation"]
        if rec["action"] == "auto_execute":
            print(f"  [AUTO] Execute with {rec['cli']}")
        else:
            print(f"  [LOCAL] Handle with Claude Code")
        print(f"  Reason: {rec['reason']}")


if __name__ == "__main__":
    main()
