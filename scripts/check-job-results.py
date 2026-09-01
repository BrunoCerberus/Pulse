#!/usr/bin/env python3
"""Aggregate `needs.<job>.result` values into one branch-protection verdict.

The master ruleset requires a handful of stable summary contexts (Build Results
Summary, Coverage Results Summary, Test Results Summary, Privacy Conformance
Summary) rather than every detailed job, so each of those jobs has to collapse
its dependencies' results into a single pass/fail. That rule was copy-pasted
into four `run:` blocks across two workflows, already drifting (`==` vs `=`);
one definition means a future change — say, treating `cancelled` differently —
cannot land in three places and be forgotten in the fourth.

The rule: "skipped" is healthy. It is what deliberate path filtering produces
(Detect Changes decided a suite could not be affected), and GitHub already
treats a skipped required check as passing — failing on it would red every PR
that skips a suite. Everything that is not success/skipped — failure,
cancelled, or a result GitHub adds later — fails.

Reads JOB_RESULTS: one `Label=result` pair per line. Writes `status=success|
failure` to $GITHUB_OUTPUT when set, so a caller can gate later steps on it
instead of on this script's exit code (Test Results Summary renders its report
before failing). Exits 1 on an unhealthy result unless FAIL_ON_ERROR=false.

Usage: JOB_RESULTS=$'Unit Tests=success\\nUI Tests=skipped' check-job-results.py
       check-job-results.py --self-test
"""

from __future__ import annotations

import os
import sys

HEALTHY = {"success", "skipped"}


def parse_results(raw: str) -> list[tuple[str, str]]:
    """Parse `Label=result` lines. Blank lines are ignored; a malformed or
    empty-valued line is an error, never a silent pass — an unset
    `needs.<job>.result` must not read as healthy."""
    results: list[tuple[str, str]] = []
    for line in raw.splitlines():
        line = line.strip()
        if not line:
            continue
        label, separator, value = line.partition("=")
        label, value = label.strip(), value.strip()
        if not separator or not label or not value:
            raise ValueError(f"malformed JOB_RESULTS entry: {line!r} (expected 'Label=result')")
        results.append((label, value))
    if not results:
        raise ValueError("JOB_RESULTS is empty; nothing to gate on")
    return results


def evaluate(results: list[tuple[str, str]]) -> tuple[bool, str]:
    """(ok, one-line summary naming every job and its result)."""
    summary = ", ".join(f"{label}={value}" for label, value in results)
    return all(value in HEALTHY for _, value in results), summary


def self_test() -> None:
    assert parse_results("A=success\n\n B = skipped \n") == [("A", "success"), ("B", "skipped")]
    for bad in ("", "   ", "A", "A=", "=success", "\n\n"):
        try:
            parse_results(bad)
        except ValueError:
            pass
        else:
            raise AssertionError(f"accepted malformed JOB_RESULTS {bad!r}")

    ok, summary = evaluate([("Unit Tests", "success"), ("UI Tests", "skipped")])
    assert ok and summary == "Unit Tests=success, UI Tests=skipped", summary
    # Every unhealthy conclusion fails, including ones GitHub may add later.
    for bad in ("failure", "cancelled", "timed_out", "action_required", "neutral"):
        ok, summary = evaluate([("Unit Tests", "success"), ("UI Tests", bad)])
        assert not ok, bad
        # The summary names the offending job, not just the aggregate verdict.
        assert f"UI Tests={bad}" in summary, summary
    print("self-test passed")


def main() -> int:
    if "--self-test" in sys.argv[1:]:
        self_test()
        return 0

    try:
        results = parse_results(os.environ.get("JOB_RESULTS", ""))
    except ValueError as exc:
        print(f"::error::{exc}")
        return 1

    ok, summary = evaluate(results)
    status = "success" if ok else "failure"

    output_path = os.environ.get("GITHUB_OUTPUT")
    if output_path:
        with open(output_path, "a", encoding="utf-8") as handle:
            handle.write(f"status={status}\n")

    if ok:
        print(summary)
        return 0
    print(f"::error::{summary}")
    return 0 if os.environ.get("FAIL_ON_ERROR") == "false" else 1


if __name__ == "__main__":
    raise SystemExit(main())
