#!/usr/bin/env python3
"""Fail when overall coverage drops meaningfully below the master baseline.

The Patch Coverage job gates *changed* lines at 75%. That is the right gate for
new code but it is blind to erosion: deleting well-covered code, moving logic
into an untested type, or widening an existing uncovered branch all leave patch
coverage green while the overall number slides. This is the complementary
ratchet.

It is a ratchet, not a fixed floor. A fixed floor either sits so low it never
fires or blocks legitimate refactors the day it is set; comparing against the
last successful master run means the bar rises on its own as coverage improves,
and a PR only fails if it gives back more than the tolerance.

Usage: check-coverage-ratchet.py <current-pct> <baseline-pct|none> [tolerance]
Exit codes: 0 = within tolerance (or no baseline), 1 = regression, 2 = bad args.
"""

from __future__ import annotations

import os
import sys

# How far coverage may fall in a single PR before this blocks. Small enough to
# catch real erosion, wide enough to absorb the run-to-run jitter that comes
# from retried flaky tests changing which lines executed.
DEFAULT_TOLERANCE = 1.0


def emit_summary(text: str) -> None:
    """Append to the GitHub step summary when running in Actions."""
    summary_path = os.environ.get("GITHUB_STEP_SUMMARY")
    if not summary_path:
        return
    with open(summary_path, "a", encoding="utf-8") as handle:
        handle.write(text + "\n")


def parse_percentage(raw: str, label: str) -> float | None:
    if raw.strip().lower() in ("", "none", "null"):
        return None
    try:
        return float(raw.strip().rstrip("%"))
    except ValueError:
        print(f"error: {label} is not a number: {raw!r}", file=sys.stderr)
        raise


def main() -> int:
    if len(sys.argv) not in (3, 4):
        print(
            "usage: check-coverage-ratchet.py <current-pct> <baseline-pct|none> [tolerance]",
            file=sys.stderr,
        )
        return 2

    try:
        current = parse_percentage(sys.argv[1], "current coverage")
        baseline = parse_percentage(sys.argv[2], "baseline coverage")
    except ValueError:
        return 2
    tolerance = float(sys.argv[3]) if len(sys.argv) == 4 else DEFAULT_TOLERANCE

    if current is None:
        # No usable measurement — the coverage-summary step already warns. Do
        # not invent a regression out of a missing number.
        print("::warning::No current coverage value — skipping ratchet")
        return 0

    if baseline is None:
        # First run, or no master run has published a baseline yet. Record and
        # move on; the next PR gets a real comparison.
        print(f"No master baseline available yet — recording {current:.2f}% as the starting point.")
        emit_summary(
            "## Coverage Ratchet\n\n"
            f"No master baseline available yet. Current: **{current:.2f}%**."
        )
        return 0

    delta = current - baseline
    floor = baseline - tolerance
    verdict = "PASS" if current >= floor else "FAIL"
    print(
        f"Coverage ratchet [{verdict}]: current {current:.2f}%, "
        f"master baseline {baseline:.2f}%, delta {delta:+.2f}pt, "
        f"tolerance {tolerance:.2f}pt (floor {floor:.2f}%)"
    )
    emit_summary(
        "## Coverage Ratchet\n\n"
        "| Current | Master baseline | Delta | Floor |\n"
        "|---------|-----------------|-------|-------|\n"
        f"| {current:.2f}% | {baseline:.2f}% | {delta:+.2f}pt | {floor:.2f}% |\n"
    )

    if verdict == "FAIL":
        print(
            f"\nOverall coverage fell {abs(delta):.2f}pt below master, past the "
            f"{tolerance:.2f}pt tolerance.\n"
            "Patch Coverage only measures changed lines, so this is erosion it cannot see —\n"
            "usually deleted tests, or logic moved into a type nothing exercises.\n"
            "Add coverage for the affected code, or raise the tolerance deliberately if the\n"
            "drop is a known one-off."
        )
        emit_summary(
            f"\n:x: Coverage dropped {abs(delta):.2f}pt below master "
            f"(tolerance {tolerance:.2f}pt)."
        )
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
