#!/usr/bin/env python3
"""Merge per-suite flaky-tests.json files into one markdown report.

Consumes the artifacts produced by detect-flaky-tests.py across the four test
jobs and renders a single table. Runs on ubuntu (pure JSON + text), so it never
occupies a macOS runner.

Inputs (environment):

  FLAKY_DIR    directory to search recursively for flaky-*.json (default .)
  OUTPUT       markdown file to write (default flaky-report.md)
  GITHUB_OUTPUT  step-output file; receives `has_flakes=true|false`

Writes OUTPUT only when at least one flake was found, so callers can gate on
`has_flakes` and avoid posting an empty PR comment.
"""

import json
import os
import sys
from pathlib import Path


def load_reports(flaky_dir):
    """Return {suite: [(case, message)]} for every parsable flaky-*.json."""
    reports = {}
    for path in sorted(Path(flaky_dir).rglob("flaky-*.json")):
        try:
            with open(path) as fh:
                payload = json.load(fh)
        except (OSError, json.JSONDecodeError):
            print(f"::warning::Could not read {path} — ignoring")
            continue
        suite = payload.get("suite", path.stem)
        flaky = payload.get("flaky", [])
        if flaky:
            reports[suite] = flaky
    return reports


def render(reports):
    lines = [
        "## ⚠️ Flaky tests detected",
        "",
        "These tests failed on their first attempt and passed on a retry. "
        "The suite is green because of `-retry-tests-on-failure`; the tests "
        "themselves are not reliable.",
        "",
        "| Suite | Test | First-attempt failure |",
        "|-------|------|----------------------|",
    ]
    for suite, flaky in reports.items():
        for entry in flaky:
            # Entries are [case, message] pairs as serialized by json.dump.
            case, message = entry[0], entry[1]
            short = message[:150] + "..." if len(message) > 150 else message
            escaped = short.replace("|", "\\|").replace("\n", " ")
            lines.append(f"| {suite} | `{case}` | {escaped} |")
    lines.append("")
    lines.append("<!-- flaky-report -->")
    return "\n".join(lines) + "\n"


def main():
    flaky_dir = os.environ.get("FLAKY_DIR", ".")
    output = os.environ.get("OUTPUT", "flaky-report.md")
    github_output = os.environ.get("GITHUB_OUTPUT", "/dev/null")

    reports = load_reports(flaky_dir)
    has_flakes = bool(reports)

    if has_flakes:
        markdown = render(reports)
        with open(output, "w") as fh:
            fh.write(markdown)
        print(markdown)
    else:
        print("No flaky tests detected across any suite.")

    with open(github_output, "a") as fh:
        fh.write(f"has_flakes={'true' if has_flakes else 'false'}\n")


if __name__ == "__main__":
    sys.exit(main())
