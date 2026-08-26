#!/usr/bin/env python3
"""Fail when the Release app binary grows meaningfully past the master baseline.

The App Store size limit is a cliff, not a curve: nothing warns while the app
sits well under it, and a PR that quietly adds 8 MB of bundled model/data
moves the cliff without tripping it. This ratchet inverts the coverage ratchet
— growth is the regression — and compares the Release simulator build's
Pulse.app size (including its extension appexes) against the last successful
master run with a relative tolerance.

The app-size measurement step publishes the number as an artifact exactly the
way the coverage step does: a missing baseline is a pass, never a fabricated
zero.

Usage: check-app-size-ratchet.py <current-mb> <baseline-mb|none> [tolerance]
Exit codes: 0 = within tolerance (or no baseline / no measurement),
1 = growth regression, 2 = bad args.
"""

from __future__ import annotations

import os
import sys

# How far the size may grow in a single PR before this blocks. App Store
# limits and user download cost make slow bloat the enemy; 10% of a ~60 MB
# app is a 6 MB one-PR jump, which is loudly intentional and reviewable.
DEFAULT_TOLERANCE = 0.10


def emit_summary(text: str) -> None:
    """Append to the GitHub step summary when running in Actions."""
    summary_path = os.environ.get("GITHUB_STEP_SUMMARY")
    if not summary_path:
        return
    with open(summary_path, "a", encoding="utf-8") as handle:
        handle.write(text + "\n")


def parse_size(raw: str, label: str) -> float | None:
    if raw.strip().lower() in ("", "none", "null"):
        return None
    try:
        return float(raw.strip().rstrip("MB").rstrip("mb"))
    except ValueError:
        print(f"error: {label} is not a number: {raw!r}", file=sys.stderr)
        raise


def main() -> int:
    if len(sys.argv) not in (3, 4):
        print(
            "usage: check-app-size-ratchet.py <current-mb> <baseline-mb|none> [tolerance]",
            file=sys.stderr,
        )
        return 2

    try:
        current = parse_size(sys.argv[1], "current size")
        baseline = parse_size(sys.argv[2], "baseline size")
    except ValueError:
        return 2
    tolerance = float(sys.argv[3]) if len(sys.argv) == 4 else DEFAULT_TOLERANCE

    if current is None:
        # No usable measurement — the measure step already warned. Do not
        # invent a regression out of a missing number.
        print("::warning::No current app size — skipping ratchet")
        return 0

    if baseline is None:
        # First run, or no master run has published a baseline yet. Record and
        # move on; the next PR gets a real comparison.
        print(f"No master baseline available yet — recording {current:.1f} MB as the starting point.")
        emit_summary(
            "## App Size Ratchet\n\n"
            f"No master baseline available yet. Current: **{current:.1f} MB**."
        )
        return 0

    delta = current - baseline
    ceiling = baseline * (1 + tolerance)
    verdict = "PASS" if current <= ceiling else "FAIL"
    print(
        f"App-size ratchet [{verdict}]: current {current:.1f} MB, "
        f"master baseline {baseline:.1f} MB, delta {delta:+.1f} MB, "
        f"tolerance {tolerance:.0%} (ceiling {ceiling:.1f} MB)"
    )
    emit_summary(
        "## App Size Ratchet\n\n"
        "| Current | Master baseline | Delta | App Store limit |\n"
        "|---------|-----------------|-------|-----------------|\n"
        f"| {current:.1f} MB | {baseline:.1f} MB | {delta:+.1f} MB | 200 MB |\n"
    )

    if verdict == "FAIL":
        print(
            f"\nThe app grew {delta:.1f} MB past master, over the {tolerance:.0%} tolerance.\n"
            "Bloat is usually a bundled model, asset, or framework. If the growth is a\n"
            "known one-off, say so in the PR body or raise the tolerance deliberately."
        )
        emit_summary(
            f"\n:x: App size grew {delta:.1f} MB past master (tolerance {tolerance:.0%})."
        )
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
