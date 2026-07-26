#!/usr/bin/env python3
"""Score whether another CLI may help, without executing or changing policy."""

from __future__ import annotations

import argparse
import json


def benefit_score(task: str, file_count: int, complexity: str, timed_out: bool) -> float:
    score = 0.0
    score += 0.35 if file_count >= 10 else 0.25 if file_count >= 5 else 0.15 if file_count >= 3 else 0.05
    score += {"high": 0.25, "medium": 0.15, "low": 0.1}[complexity]
    lowered = task.lower()
    if any(word in lowered for word in ("batch", "bulk", "multiple", "all files", "refactor", "rename")):
        score += 0.2
    if any(word in lowered for word in ("template", "generate", "scaffold", "boilerplate")):
        score += 0.15
    if any(word in lowered for word in ("implement", "create", "build", "fix", "update")):
        score += 0.15
    if timed_out:
        score += 0.2
    return min(score, 1.0)


def cost_score(file_count: int, has_secrets: bool) -> float:
    score = -0.15 if file_count >= 20 else -0.1 if file_count >= 10 else -0.05 if file_count >= 5 else 0.0
    if has_secrets:
        score -= 0.1
    return max(score - 0.05, -0.3)


def risk_score(task: str, write_required: bool, has_secrets: bool) -> float:
    score = -0.1 if write_required else 0.0
    if has_secrets:
        score -= 0.1
    if any(word in task.lower() for word in ("delete", "remove", "drop", "destroy", "force")):
        score -= 0.15
    return max(score, -0.3)


def recommend_cli(task: str) -> str:
    lowered = task.lower()
    scores = {
        "claude": sum(word in lowered for word in ("architecture", "coordinate", "review", "research", "plan")),
        "codex": sum(word in lowered for word in ("edit", "code", "implement", "fix", "debug", "refactor", "test")),
        "grok": sum(word in lowered for word in ("grok", "xai", "search", "explore", "realtime", "parallel")),
    }
    return max(scores, key=scores.get)


def calculate_decision(
    task: str,
    file_count: int = 1,
    complexity: str = "medium",
    timed_out: bool = False,
    write_required: bool = True,
    has_secrets: bool = False,
) -> dict[str, object]:
    benefit = benefit_score(task, file_count, complexity, timed_out)
    cost = cost_score(file_count, has_secrets)
    risk = risk_score(task, write_required, has_secrets)
    total = benefit + cost + risk
    suggested = total >= 0.15
    cli = recommend_cli(task) if suggested else None
    return {
        "scores": {
            "benefit": round(benefit, 2),
            "cost": round(cost, 2),
            "risk": round(risk, 2),
            "total": round(total, 2),
        },
        "recommendation": {
            "action": "suggest" if suggested else "stay",
            "cli": cli,
            "reason": (
                f"Score {total:.2f} suggests offering {cli} as an option"
                if suggested
                else f"Score {total:.2f} suggests continuing in the current CLI"
            ),
            "user_choice_required": True,
        },
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--task", required=True)
    parser.add_argument("--files", type=int, default=1)
    parser.add_argument("--complexity", choices=("high", "medium", "low"), default="medium")
    parser.add_argument("--timeout", action="store_true")
    parser.add_argument("--read-only", action="store_true", help="the proposed work does not write files")
    parser.add_argument("--secrets", action="store_true")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    decision = calculate_decision(
        args.task,
        args.files,
        args.complexity,
        args.timeout,
        not args.read_only,
        args.secrets,
    )
    if args.json:
        print(json.dumps(decision, indent=2))
        return
    scores = decision["scores"]
    recommendation = decision["recommendation"]
    print(f"Routing score: {scores['total']:+.2f}")
    if recommendation["action"] == "suggest":
        print(f"Suggestion: offer {recommendation['cli']} as an option; do not launch it automatically.")
    else:
        print("Suggestion: continue in the current CLI.")
    print(f"Reason: {recommendation['reason']}")


if __name__ == "__main__":
    main()
