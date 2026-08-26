#!/usr/bin/env python3
"""Merge per-suite slow-tests.json files into one markdown report.

Consumes the artifacts produced by detect-slow-tests.py across the nightly
matrix legs and renders a single table. Runs on ubuntu (pure JSON + text), so
it never occupies a macOS runner.

Inputs (environment):

  SLOW_DIR    directory to search recursively for slow-*.json (default .)
  OUTPUT      markdown file to write (default slow-report.md)
  GITHUB_OUTPUT  step-output file; receives `has_slow=true|false`

Writes OUTPUT only when at least one slow test was found, so callers can gate
on `has_slow` and avoid rendering an empty section.
"""

from __future__ import annotations

import json
import os
from pathlib import Path


def load_reports(slow_dir: str) -> dict[str, list[dict]]:
    """Return {suite: [entries]} for every parsable slow-*.json."""
    reports: dict[str, list[dict]] = {}
    for path in sorted(Path(slow_dir).rglob("slow-*.json")):
        try:
            with open(path) as fh:
                payload = json.load(fh)
        except (OSError, json.JSONDecodeError):
            print(f"::warning::Could not read {path} — ignoring")
            continue
        suite = payload.get("suite", path.stem)
        slow = payload.get("slow", [])
        if slow:
            reports[suite] = slow
    return reports


def render(reports: dict[str, list[dict]]) -> str:
    lines = [
        "## 🐢 Slow tests detected",
        "",
        "These tests exceeded the advisory nightly threshold. They never fail "
        "a build; they are triage signal for suite wall-clock drift.",
        "",
        "| Suite | Test | Duration | Status |",
        "|-------|------|----------|--------|",
    ]
    for suite, entries in reports.items():
        for entry in entries:
            lines.append(
                f"| {suite} | `{entry['test']}` | {entry['duration']:.1f}s | {entry['status']} |"
            )
    lines.append("")
    lines.append("<!-- slow-report -->")
    return "\n".join(lines) + "\n"


def main() -> None:
    slow_dir = os.environ.get("SLOW_DIR", ".")
    output = os.environ.get("OUTPUT", "slow-report.md")
    github_output = os.environ.get("GITHUB_OUTPUT", "/dev/null")

    reports = load_reports(slow_dir)
    has_slow = bool(reports)

    if has_slow:
        markdown = render(reports)
        with open(output, "w") as fh:
            fh.write(markdown)
        print(markdown)
    else:
        print("No slow tests detected across any suite.")

    with open(github_output, "a") as fh:
        fh.write(f"has_slow={'true' if has_slow else 'false'}\n")


if __name__ == "__main__":
    main()
