#!/usr/bin/env python3
"""Fail when a nightly suite takes meaningfully longer than the recent baseline.

The nightly is the only unconditional full-suite run, so its per-suite wall
clock is the cleanest CI-cost signal available: a runner-image slowdown, suite
growth, or a new slow test shows up here before it collides with the 180/210
minute step/job ceilings. The scheduled-tests workflow records each leg's
wall-clock seconds into per-suite JSON artifacts (``suite-duration-*``); this
script compares them against the most recent successful run's artifacts, the
same baseline-by-artifact pattern as the app-size / coverage / test-count
ratchets.

Each JSON file is ``{"suite": "<name>", "seconds": <n>}``. Per-suite verdict:

  - current > baseline * (1 + tolerance) → regression (fail);
  - a suite present only in current is a NEW leg — reported, never a failure;
  - a suite present only in baseline is a missing/cancelled leg — reported,
    never a failure;
  - no current measurements at all → pass with a warning (a missing
    measurement is not a regression — same fail-safe as the other ratchets);
  - no baseline yet (first run / nothing downloadable) → pass, recording the
    starting point.

``--self-test`` exercises all five classifications against synthetic inputs,
because a green nightly only proves this run was fast, not that a regression
would be caught.

Usage: check-duration-ratchet.py <current-dir> <baseline-dir|none> [tolerance]
      check-duration-ratchet.py --self-test
Exit codes: 0 = within tolerance (or nothing to compare), 1 = regression,
2 = bad args.
"""
from __future__ import annotations

import json
import os
import sys
import tempfile
from pathlib import Path

# Shared macOS runners vary far more run-to-run than app size or test count,
# and -retry-tests-on-failure inflates a flaky suite's wall clock; 15% absorbs
# that noise while still catching a suite that has genuinely doubled.
DEFAULT_TOLERANCE = 0.15


def emit_summary(text: str) -> None:
    """Append to the GitHub step summary when running in Actions."""
    summary_path = os.environ.get("GITHUB_STEP_SUMMARY")
    if not summary_path:
        return
    with open(summary_path, "a", encoding="utf-8") as handle:
        handle.write(text + "\n")


def load_suite_durations(directory: Path) -> dict[str, float] | None:
    """Map suite name → seconds over the directory's JSON files.

    Returns None when the directory holds no usable measurements (so the caller
    can distinguish "nothing measured" from "zero seconds")."""
    if not directory.is_dir():
        return None
    durations: dict[str, float] = {}
    for path in sorted(directory.glob("*.json")):
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
            durations[str(data["suite"])] = float(data["seconds"])
        except (OSError, json.JSONDecodeError, KeyError, TypeError, ValueError) as exc:
            print(f"::warning::Skipping unreadable duration file {path.name}: {exc}")
    return durations or None


def minutes(seconds: float) -> str:
    return f"{seconds / 60:.1f}m"


def check(current: dict[str, float], baseline: dict[str, float] | None, tolerance: float) -> tuple[int, str]:
    all_suites = sorted(set(current) | set(baseline or {}))
    rows: list[str] = []
    regressions: list[str] = []

    for suite in all_suites:
        cur = current.get(suite)
        base = (baseline or {}).get(suite)
        if cur is None:
            rows.append(f"| {suite} | {minutes(base)} | — | leg missing from this run (skipped or cancelled) |")
            continue
        if base is None:
            rows.append(f"| {suite} | — | {minutes(cur)} | new leg — no baseline yet |")
            continue
        ceiling = base * (1 + tolerance)
        if cur > ceiling:
            regressions.append(suite)
            rows.append(
                f"| {suite} | {minutes(base)} | {minutes(cur)} | "
                f":x: exceeds baseline by more than {tolerance:.0%} (ceiling {minutes(ceiling)}) |"
            )
        else:
            delta = cur - base
            rows.append(f"| {suite} | {minutes(base)} | {minutes(cur)} | {delta / 60:+.1f}m — within tolerance |")

    report = (
        "## CI Duration Ratchet (nightly, advisory)\n\n"
        f"| Suite | Baseline | Current | Verdict (tolerance {tolerance:.0%}) |\n"
        "|-------|----------|---------|------|\n" + "\n".join(rows)
        + "\n"
    )
    if regressions:
        report += f"\n:x: {len(regressions)} suite(s) regressed: {', '.join(regressions)}\n"
        print(
            f"Duration ratchet FAILED: {len(regressions)} suite(s) over the {tolerance:.0%} tolerance: "
            + ", ".join(regressions)
        )
        return 1, report

    print(
        "Duration ratchet passed — all measured suites within "
        f"{tolerance:.0%} of baseline ({len(current)} suite(s) compared)."
    )
    return 0, report


def run(current_dir: Path, baseline_dir: Path | None, tolerance: float) -> int:
    current = load_suite_durations(current_dir)
    if current is None:
        print("::warning::No suite-duration artifacts found — skipping ratchet (nothing measured this run).")
        return 0

    baseline: dict[str, float] | None = None
    if baseline_dir is None:
        print("No baseline available yet — recording this run's durations as the starting point.")
    else:
        baseline = load_suite_durations(baseline_dir)
        if baseline is None:
            print("::warning::Baseline directory held no usable durations — skipping ratchet.")

    code, report = check(current, baseline, tolerance)
    emit_summary(report)
    return code


def self_test() -> int:
    failures: list[str] = []

    def expect(condition: bool, label: str) -> None:
        if not condition:
            failures.append(label)

    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)

        def write_suite(directory: Path, suite: str, seconds: float) -> None:
            directory.mkdir(parents=True, exist_ok=True)
            (directory / f"suite-duration-{suite}.json").write_text(
                json.dumps({"suite": suite, "seconds": seconds}), encoding="utf-8"
            )

        cur = root / "current"
        base = root / "baseline"
        write_suite(cur, "unit", 30 * 60)
        write_suite(base, "unit", 30 * 60)
        write_suite(cur, "ui", 100 * 60)
        write_suite(base, "ui", 100 * 60)
        code = run(cur, base, DEFAULT_TOLERANCE)
        expect(code == 0, "identical durations did not pass")

        regressed = root / "regressed"
        write_suite(regressed, "unit", 45 * 60)  # 50% over baseline
        write_suite(regressed, "ui", 105 * 60)  # within 15%
        code = run(regressed, base, DEFAULT_TOLERANCE)
        expect(code == 1, "a 50% regression did not fail")

        code = run(root / "empty-current", base, DEFAULT_TOLERANCE)
        expect(code == 0, "an empty current directory failed the ratchet")

        code = run(cur, None, DEFAULT_TOLERANCE)
        expect(code == 0, "a missing baseline (first run) failed the ratchet")

        new_leg = root / "new-leg"
        write_suite(new_leg, "unit", 31 * 60)
        write_suite(new_leg, "ipad-ui", 90 * 60)  # in current only — must not fail
        code = run(new_leg, base, DEFAULT_TOLERANCE)
        expect(code == 0, "a brand-new suite (no baseline) failed the ratchet")

    if failures:
        for failure in failures:
            print(f"self-test FAILED: {failure}", file=sys.stderr)
        return 1
    print("self-test passed (in-tolerance / regression / empty / no-baseline / new-leg cases all classified).")
    return 0


def main() -> int:
    args = sys.argv[1:]
    if args == ["--self-test"]:
        return self_test()
    if len(args) not in (2, 3):
        print(
            "usage: check-duration-ratchet.py <current-dir> <baseline-dir|none> [tolerance] | --self-test",
            file=sys.stderr,
        )
        return 2
    try:
        tolerance = float(args[2]) if len(args) == 3 else DEFAULT_TOLERANCE
    except ValueError:
        print(f"error: tolerance is not a number: {args[2]!r}", file=sys.stderr)
        return 2
    baseline = None if args[1].strip().lower() in ("", "none", "null") else Path(args[1]).resolve()
    return run(Path(args[0]).resolve(), baseline, tolerance)


if __name__ == "__main__":
    sys.exit(main())
