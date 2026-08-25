#!/usr/bin/env python3
"""Fail when the test-suite count drops meaningfully below the master baseline.

Patch coverage and the flake report both measure *quality of execution*;
nothing measures the *size* of the suite. Deleting tests — one by one, "for
now", to green a red build — is the fastest way a suite erodes to nothing,
and each individual deletion looks innocent in review. This ratchet makes the
suite a ratchet: the bar is the last successful master run, it rises as tests
are added, and a PR fails only when it removes more than the tolerance.

Tolerance is relative (default 2%): an absolute floor either never fires or
blocks the day it is set, and a relative bar scales with the suite.

Usage: check-test-count-ratchet.py <current-count> <baseline-count|none> [tolerance]
Exit codes: 0 = within tolerance (or no baseline / no count), 1 = regression,
2 = bad args.
"""

from __future__ import annotations

import os
import sys

# How far the count may fall in a single PR before this blocks. Wide enough to
# absorb a deliberate small refactor, tight enough that mass-deletion fails.
DEFAULT_TOLERANCE = 0.02


def emit_summary(text: str) -> None:
    """Append to the GitHub step summary when running in Actions."""
    summary_path = os.environ.get("GITHUB_STEP_SUMMARY")
    if not summary_path:
        return
    with open(summary_path, "a", encoding="utf-8") as handle:
        handle.write(text + "\n")


def parse_count(raw: str, label: str) -> int | None:
    if raw.strip().lower() in ("", "none", "null"):
        return None
    try:
        return int(float(raw.strip()))
    except ValueError:
        print(f"error: {label} is not a number: {raw!r}", file=sys.stderr)
        raise


def main() -> int:
    if len(sys.argv) not in (3, 4):
        print(
            "usage: check-test-count-ratchet.py <current-count> <baseline-count|none> [tolerance]",
            file=sys.stderr,
        )
        return 2

    try:
        current = parse_count(sys.argv[1], "current test count")
        baseline = parse_count(sys.argv[2], "baseline test count")
    except ValueError:
        return 2
    tolerance = float(sys.argv[3]) if len(sys.argv) == 4 else DEFAULT_TOLERANCE

    if current is None:
        # No usable measurement — the extraction step already warned. Do not
        # invent a regression out of a missing number.
        print("::warning::No current test count — skipping ratchet")
        return 0

    if baseline is None:
        # First run, or no master run has published a baseline yet. Record and
        # move on; the next PR gets a real comparison.
        print(f"No master baseline available yet — recording {current} tests as the starting point.")
        emit_summary(
            "## Test Count Ratchet\n\n"
            f"No master baseline available yet. Current: **{current}** tests."
        )
        return 0

    delta = current - baseline
    floor = baseline * (1 - tolerance)
    verdict = "PASS" if current >= floor else "FAIL"
    print(
        f"Test-count ratchet [{verdict}]: current {current}, "
        f"master baseline {baseline}, delta {delta:+d}, "
        f"tolerance {tolerance:.1%} (floor {floor:.0f})"
    )
    emit_summary(
        "## Test Count Ratchet\n\n"
        "| Current | Master baseline | Delta |\n"
        "|---------|-----------------|-------|\n"
        f"| {current} | {baseline} | {delta:+d} |\n"
    )

    if verdict == "FAIL":
        print(
            f"\nThe test suite shrank by {abs(delta)} tests below master, past the "
            f"{tolerance:.1%} tolerance.\n"
            "If tests were removed on purpose (refactor, dedup), add their replacement\n"
            "in the same PR so the count holds — or raise the tolerance deliberately."
        )
        emit_summary(
            f"\n:x: Test count dropped {abs(delta)} below master "
            f"(tolerance {tolerance:.1%})."
        )
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
