#!/usr/bin/env python3
"""Render per-job runner wait versus execution time for a workflow run.

Runner wait and execution are different problems with different fixes: a long
wait means macOS runner capacity (or a slow dependency), a long execution means
the suite itself got slower. Reporting them as one number is how a capacity
delay gets mistaken for a test regression.

Both numbers come straight from the jobs API, with no model of the workflow's
dependency graph:

  - ``created_at`` is when GitHub *queued* the job — that is, when its ``needs:``
    were satisfied, NOT when the run started. On a real run, Unit Tests'
    created_at equals Build Project's completed_at to the second.
  - ``started_at`` is when a runner picked it up.
  - ``completed_at`` is when it finished.

So wait = started_at - created_at and execution = completed_at - started_at,
for every job, with nothing to keep in sync with ci.yml. An earlier version of
this script hardcoded the ``needs:`` edges and anchored waits to the run's
``created_at``; both drifted silently (and the run field is wrong for re-runs,
where it still points at the first attempt).

Usage: render-ci-timing.py <jobs-json> <output.md>
       render-ci-timing.py --self-test
"""

from __future__ import annotations

import argparse
import json
from datetime import datetime
from pathlib import Path

# Jobs quicker than this are pure bookkeeping (the summary gates, Detect
# Changes); listing them buries the macOS legs the report exists for.
MIN_INTERESTING_SECONDS = 30


def parse_time(value: str) -> datetime:
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def format_duration(seconds: float) -> str:
    total = max(0, round(seconds))
    return f"{total // 60}m {total % 60:02d}s"


def collect_rows(jobs_payload: dict) -> list[tuple[str, str, float, float]]:
    """(name, conclusion, wait seconds, execution seconds) per finished job.

    Jobs still running, or missing any of the three timestamps, are skipped
    rather than reported with a fabricated duration."""
    rows: list[tuple[str, str, float, float]] = []
    for job in jobs_payload.get("jobs", []):
        created, started, completed = (
            job.get("created_at"),
            job.get("started_at"),
            job.get("completed_at"),
        )
        if not created or not started or not completed:
            continue
        wait = (parse_time(started) - parse_time(created)).total_seconds()
        execution = (parse_time(completed) - parse_time(started)).total_seconds()
        if wait + execution < MIN_INTERESTING_SECONDS:
            continue
        rows.append((job.get("name") or "(unnamed)", job.get("conclusion") or "unknown", wait, execution))
    rows.sort(key=lambda row: row[2] + row[3], reverse=True)
    return rows


def render(jobs_payload: dict) -> str:
    rows = collect_rows(jobs_payload)
    lines = [
        "## CI Timing",
        "",
        "| Job | Result | Runner wait | Execution |",
        "|-----|--------|-------------|-----------|",
    ]
    if rows:
        lines.extend(
            f"| {name} | {result} | {format_duration(wait)} | {format_duration(execution)} |"
            for name, result, wait, execution in rows
        )
        total_wait = sum(row[2] for row in rows)
        lines.append(f"| **Total** | | **{format_duration(total_wait)}** | |")
    else:
        lines.append("| _no finished jobs to report_ | | | |")
    lines.extend(
        [
            "",
            "_Runner wait is `started_at - created_at` (GitHub queues a job once its "
            "`needs:` complete, so this is capacity, not dependency time); execution is "
            f"`completed_at - started_at`. Jobs under {MIN_INTERESTING_SECONDS}s are omitted._",
        ]
    )
    return "\n".join(lines) + "\n"


def self_test() -> None:
    def job(name, created, started, completed, conclusion="success"):
        return {
            "name": name,
            "conclusion": conclusion,
            "created_at": created,
            "started_at": started,
            "completed_at": completed,
        }

    # A dependent job's created_at is its dependency's completed_at, so the
    # wait is queue time only — never the dependency's runtime.
    output = render(
        {
            "jobs": [
                job("Build Project", "2026-01-01T00:00:00Z", "2026-01-01T00:00:04Z", "2026-01-01T00:10:00Z"),
                job("Unit Tests", "2026-01-01T00:10:00Z", "2026-01-01T00:10:20Z", "2026-01-01T00:12:00Z"),
            ]
        }
    )
    assert "| Build Project | success | 0m 04s | 9m 56s |" in output, output
    assert "| Unit Tests | success | 0m 20s | 1m 40s |" in output, output
    # Longest total first, and the wait column is summed.
    assert output.index("Build Project") < output.index("Unit Tests"), output
    assert "**10m 24s**" not in output and "**0m 24s**" in output, output

    # A running job (no completed_at) is skipped, not fabricated.
    running = render({"jobs": [job("UI Tests", "2026-01-01T00:00:00Z", "2026-01-01T00:00:05Z", None)]})
    assert "UI Tests" not in running, running
    assert "_no finished jobs to report_" in running, running

    # Sub-threshold bookkeeping jobs are omitted; an empty payload still renders.
    quick = render({"jobs": [job("Build Results Summary", "2026-01-01T00:00:00Z", "2026-01-01T00:00:02Z", "2026-01-01T00:00:06Z")]})
    assert "Build Results Summary" not in quick, quick
    assert "_no finished jobs to report_" in render({})

    # Clock skew must never render a negative duration.
    skewed = render({"jobs": [job("Odd", "2026-01-01T00:01:00Z", "2026-01-01T00:00:00Z", "2026-01-01T00:02:00Z")]})
    assert "| Odd | success | 0m 00s | 2m 00s |" in skewed, skewed

    # A job GitHub reports with no name or conclusion still renders a row.
    unnamed = render(
        {"jobs": [{"created_at": "2026-01-01T00:00:00Z", "started_at": "2026-01-01T00:00:00Z", "completed_at": "2026-01-01T00:01:00Z"}]}
    )
    assert "| (unnamed) | unknown | 0m 00s | 1m 00s |" in unnamed, unnamed

    print("self-test passed")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("jobs_json", nargs="?")
    parser.add_argument("output", nargs="?")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()

    if args.self_test:
        self_test()
        return
    if not args.jobs_json or not args.output:
        parser.error("jobs_json and output are required")

    jobs = json.loads(Path(args.jobs_json).read_text())
    Path(args.output).write_text(render(jobs))


if __name__ == "__main__":
    main()
