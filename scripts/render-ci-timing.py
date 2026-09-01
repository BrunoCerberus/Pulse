#!/usr/bin/env python3
"""Render CI pre-start wait and execution time for the macOS critical path."""

from __future__ import annotations

import argparse
import json
from datetime import datetime
from pathlib import Path


DEPENDENCIES = {
    "Build Project": ["Code Quality", "Detect Changes"],
    "Release Build": ["Code Quality", "Detect Changes"],
    "Unit Tests": ["Build Project", "Detect Changes"],
    "Snapshot Tests": ["Build Project", "Detect Changes"],
    "UI Tests": ["Build Project", "Detect Changes"],
    "UI Tests (iPad)": ["Build Project", "Detect Changes"],
}


def parse_time(value: str) -> datetime:
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def format_duration(seconds: float) -> str:
    total = max(0, round(seconds))
    return f"{total // 60}m {total % 60:02d}s"


def render(run: dict, jobs_payload: dict) -> str:
    jobs = {job["name"]: job for job in jobs_payload.get("jobs", [])}
    run_created = parse_time(run["created_at"])
    rows = []

    for name, dependencies in DEPENDENCIES.items():
        job = jobs.get(name)
        if not job or not job.get("started_at") or not job.get("completed_at"):
            continue

        ready_at = run_created
        dependency_ends = [
            parse_time(jobs[dependency]["completed_at"])
            for dependency in dependencies
            if dependency in jobs and jobs[dependency].get("completed_at")
        ]
        if dependency_ends:
            ready_at = max(dependency_ends)

        started_at = parse_time(job["started_at"])
        completed_at = parse_time(job["completed_at"])
        rows.append(
            (
                name,
                job.get("conclusion", "unknown"),
                format_duration((started_at - ready_at).total_seconds()),
                format_duration((completed_at - started_at).total_seconds()),
            )
        )

    lines = [
        "## CI Timing",
        "",
        "| Job | Result | Runner wait | Execution |",
        "|-----|--------|-------------|-----------|",
    ]
    lines.extend(f"| {name} | {result} | {wait} | {execution} |" for name, result, wait, execution in rows)
    lines.extend(
        [
            "",
            "_Runner wait starts when the job's declared dependencies completed; execution is GitHub's job start-to-finish time._",
        ]
    )
    return "\n".join(lines) + "\n"


def self_test() -> None:
    run = {"created_at": "2026-01-01T00:00:00Z"}
    jobs = {
        "jobs": [
            {"name": "Code Quality", "started_at": "2026-01-01T00:00:10Z", "completed_at": "2026-01-01T00:01:00Z"},
            {"name": "Detect Changes", "started_at": "2026-01-01T00:00:05Z", "completed_at": "2026-01-01T00:00:30Z"},
            {
                "name": "Build Project",
                "conclusion": "success",
                "started_at": "2026-01-01T00:01:20Z",
                "completed_at": "2026-01-01T00:03:20Z",
            },
        ]
    }
    output = render(run, jobs)
    assert "| Build Project | success | 0m 20s | 2m 00s |" in output


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("run_json", nargs="?")
    parser.add_argument("jobs_json", nargs="?")
    parser.add_argument("output", nargs="?")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()

    if args.self_test:
        self_test()
        return
    if not args.run_json or not args.jobs_json or not args.output:
        parser.error("run_json, jobs_json, and output are required")

    run = json.loads(Path(args.run_json).read_text())
    jobs = json.loads(Path(args.jobs_json).read_text())
    Path(args.output).write_text(render(run, jobs))


if __name__ == "__main__":
    main()
