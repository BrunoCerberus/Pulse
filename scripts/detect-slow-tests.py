#!/usr/bin/env python3
"""Report the slowest tests in an xcresult bundle (advisory, nightly).

A suite's wall-clock cost drifts upward the same invisible way its flake rate
does: a test that grows from 2 s to 60 s never breaks anything until the
aggregate blows a timeout. This script reads per-test durations out of the
tree and surfaces the worst offenders so the drift is triage-able instead of
ambient.

It is deliberately advisory: it never fails a build. It runs on the nightly
suite (scheduled-tests.yml), where the full suite runs regardless of the
PR path filter, and its per-suite JSON is merged into the nightly summary by
render-slow-report.py.

Inputs (environment):

  RESULT_BUNDLE    path to the .xcresult bundle
  TEST_NAME        human-readable suite name for headings
  SLOW_JSON        where to write the machine-readable result (default
                   slow-tests.json). Always written, even when clean, so the
                   aggregator can distinguish "nothing slow" from "never ran".
  SLOW_THRESHOLD   seconds above which a test is reported (default 30)
  SLOW_TOP         maximum number of tests to report (default 10)
  GITHUB_STEP_SUMMARY  job-summary file (provided by the runner)

Always exits 0 — slowness is a signal to triage, not a reason to fail a build.
"""

from __future__ import annotations

import json
import os
import sys

from xcresult_common import escape_cell, parse_xcresult
from xcresult_test_data import fetch_test_tree, leaf_duration, leaf_name, leaf_status, leaves_by_target


def main() -> int:
    result_bundle = os.environ.get("RESULT_BUNDLE", "test-results/test.xcresult")
    test_name = os.environ.get("TEST_NAME", "Tests")
    json_path = os.environ.get("SLOW_JSON", "slow-tests.json")
    summary_file = os.environ.get("GITHUB_STEP_SUMMARY", "/dev/null")
    threshold = float(os.environ.get("SLOW_THRESHOLD", "30"))
    top_n = int(os.environ.get("SLOW_TOP", "10"))

    entries = []
    data = parse_xcresult(result_bundle)
    if data is None:
        print(f"::warning::Could not parse xcresult bundle — skipping slow-test detection")
    else:
        tree = fetch_test_tree(result_bundle)
        for target, leaf in leaves_by_target(tree):
            duration = leaf_duration(leaf)
            if duration is None:
                continue
            name = leaf_name(leaf)
            if "/" not in name:
                name = f"{target}/{name}"
            entries.append(
                {
                    "test": name,
                    "duration": round(duration, 3),
                    "status": leaf_status(leaf),
                }
            )
        entries.sort(key=lambda e: e["duration"], reverse=True)
        entries = [e for e in entries if e["duration"] >= threshold][:top_n]

    payload = {"suite": test_name, "thresholdSeconds": threshold, "slow": entries}
    with open(json_path, "w") as fh:
        json.dump(payload, fh, indent=2)

    if not entries:
        print(f"No tests over {threshold:.0f}s in {test_name}.")
        return 0

    print(f"Found {len(entries)} test(s) over {threshold:.0f}s in {test_name}:")
    for entry in entries:
        print(f"  {entry['duration']:8.3f}s  {entry['test']}")
        print(
            f"::warning title=Slow: {entry['test']}::{entry['duration']:.1f}s — "
            f"over the {threshold:.0f}s advisory threshold"
        )

    with open(summary_file, "a") as summary:
        summary.write(f"## Slow tests ({threshold:.0f}s+): {test_name}\n\n")
        summary.write("| Test | Duration | Status |\n")
        summary.write("|------|----------|--------|\n")
        for entry in entries:
            summary.write(
                f"| `{escape_cell(entry['test'])}` | {entry['duration']:.1f}s | {entry['status']} |\n"
            )
        summary.write(
            "\n_Advisory: these exceed the nightly threshold and are candidates for\n"
            "splitting, loosened polling, or lower-fidelity fakes._\n"
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
