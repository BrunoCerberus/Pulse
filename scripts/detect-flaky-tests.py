#!/usr/bin/env python3
"""Detect retry-masked flaky tests in an xcresult bundle.

Every test invocation in this repo passes `-retry-tests-on-failure`. That is
the right call for a 180-minute UI suite — a single infrastructure hiccup
shouldn't redden a PR — but it has a cost: a test that fails and then passes on
a retry reports the job green and leaves no trace anywhere a human looks. Flake
rates drift upward invisibly.

This script is meant to run ONLY on the success path of a test step (the
workflow gates it with `if: success()`). Under that precondition the detection
rule is simple and needs no version-specific repetition parsing:

    the suite passed overall, yet the bundle still records test failures
    => every recorded failure was recovered by a retry => flaky

Inputs (environment):

  RESULT_BUNDLE   path to the .xcresult bundle
  TEST_NAME       human-readable suite name for headings
  FLAKY_JSON      where to write the machine-readable result (default
                  flaky-tests.json). Always written, even when clean, so the
                  aggregating job can distinguish "no flakes" from "suite
                  never ran".
  GITHUB_STEP_SUMMARY  job-summary file (provided by the runner)

Emits ::warning:: annotations rather than ::error:: and always exits 0: a
recovered flake is a signal to triage, not a reason to fail a build that
legitimately passed.
"""

import json
import os
import sys

from xcresult_common import collect_failures, escape_cell, parse_xcresult, truncate


def write_outputs(test_name, flaky, json_path, summary_file, available=True):
    payload = {"suite": test_name, "flaky": flaky, "available": available}
    with open(json_path, "w") as fh:
        json.dump(payload, fh, indent=2)

    if not available:
        print(f"Flake data unavailable for {test_name}.")
        return

    if not flaky:
        print(f"No retry-masked flakes in {test_name}.")
        return

    print(f"Found {len(flaky)} retry-masked flaky test(s) in {test_name}:")
    print("")
    for case, message in flaky:
        short = truncate(message)
        print(f"⚠️  {case}")
        print(f"   {short}")
        print("")
        print(f"::warning title=Flaky: {case}::Passed only after a retry — {short}")

    with open(summary_file, "a") as summary:
        summary.write(f"## Flaky (passed on retry): {test_name}\n\n")
        summary.write("| Test | First-attempt failure |\n")
        summary.write("|------|----------------------|\n")
        for case, message in flaky:
            summary.write(f"| `{case}` | {escape_cell(truncate(message))} |\n")
        summary.write(
            "\n_These tests failed at least once and passed on a retry. "
            "The suite is green; the tests are not._\n"
        )


def main():
    result_bundle = os.environ.get("RESULT_BUNDLE", "test-results/test.xcresult")
    test_name = os.environ.get("TEST_NAME", "Tests")
    json_path = os.environ.get("FLAKY_JSON", "flaky-tests.json")
    summary_file = os.environ.get("GITHUB_STEP_SUMMARY", "/dev/null")

    if not os.path.isdir(result_bundle):
        print(f"::warning::No result bundle at {result_bundle} — skipping flake detection")
        write_outputs(test_name, [], json_path, summary_file, available=False)
        return

    data = parse_xcresult(result_bundle)
    if data is None:
        print("::warning::Could not parse xcresult bundle — skipping flake detection")
        write_outputs(test_name, [], json_path, summary_file, available=False)
        return

    write_outputs(test_name, collect_failures(data), json_path, summary_file)


if __name__ == "__main__":
    sys.exit(main())
