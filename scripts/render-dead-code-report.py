#!/usr/bin/env python3
"""Render `swiftlint analyze` output into a GitHub job summary.

Advisory, never a build failure — `unused_declaration` cannot see references
that come from outside the linted sources (protocol requirements the framework
fulfils, `#Preview` blocks, other targets), so a fraction of its hits are false
positives. Grouping them by rule and file makes the report scannable enough to
triage in one pass, which is all it is meant to be.

Usage: render-dead-code-report.py <analyze-output> [repo-root]
Always exits 0.
"""

from __future__ import annotations

import os
import re
import sys
from collections import defaultdict
from pathlib import Path

# `/path/File.swift:12:5: warning: Some Violation: message (rule_id)`
VIOLATION = re.compile(
    r"^(?P<path>/[^:]+):(?P<line>\d+):\d+: \w+: (?P<message>.*?) \((?P<rule>[a-z_]+)\)$"
)

RULE_TITLES = {
    "unused_declaration": "Unused declarations",
    "unused_import": "Unused imports",
}


def emit(text: str) -> None:
    print(text)
    summary_path = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary_path:
        with open(summary_path, "a", encoding="utf-8") as handle:
            handle.write(text + "\n")


def main() -> int:
    if len(sys.argv) not in (2, 3):
        print("usage: render-dead-code-report.py <analyze-output> [repo-root]", file=sys.stderr)
        return 0

    output_path = Path(sys.argv[1])
    repo_root = Path(sys.argv[2] if len(sys.argv) == 3 else ".").resolve()

    if not output_path.is_file():
        emit("## Dead Code Report\n\n_No analyzer output produced._")
        return 0

    by_rule: dict[str, list[tuple[str, str]]] = defaultdict(list)
    for raw in output_path.read_text(encoding="utf-8", errors="replace").splitlines():
        match = VIOLATION.match(raw.strip())
        if not match:
            continue
        path = Path(match.group("path"))
        try:
            location = str(path.resolve().relative_to(repo_root))
        except ValueError:
            location = str(path)
        by_rule[match.group("rule")].append((f"{location}:{match.group('line')}", match.group("message")))

    if not by_rule:
        emit("## Dead Code Report\n\n:white_check_mark: No unused declarations or imports found.")
        return 0

    total = sum(len(entries) for entries in by_rule.values())
    emit(f"## Dead Code Report\n\n{total} candidate(s) across {len(by_rule)} rule(s).\n")
    emit(
        "_Advisory only — this never fails the build. `unused_declaration` cannot see "
        "references from protocol requirements the framework fulfils, `#Preview` blocks, "
        "or other targets, so confirm a hit before deleting._\n"
    )

    for rule, entries in sorted(by_rule.items()):
        title = RULE_TITLES.get(rule, rule)
        emit(f"### {title} ({len(entries)})\n")
        # Cap the rendered list so a large first run cannot blow the 1MB summary
        # limit; the full list is always in the uploaded artifact.
        shown = sorted(entries)[:50]
        emit("| Location |")
        emit("|----------|")
        for location, _ in shown:
            emit(f"| `{location}` |")
        if len(entries) > len(shown):
            emit(f"\n_+{len(entries) - len(shown)} more — see the `dead-code-report` artifact._")
        emit("")

    return 0


if __name__ == "__main__":
    sys.exit(main())
