#!/usr/bin/env python3
"""Extract test failures from an xcresult bundle for CI reporting.

Replaces the Python heredoc that was copy-pasted across the unit/snapshot/UI
test jobs in ci.yml and scheduled-tests.yml. Reads its inputs from the
environment (matching the old heredoc contract):

  RESULT_BUNDLE        path to the .xcresult bundle
  TEST_NAME            human-readable suite name for headings
  TEST_LOG             raw xcodebuild log, used as fallback when the bundle
                       is missing (default /tmp/test_output.log)
  GITHUB_STEP_SUMMARY  job-summary file (provided by the runner)

Prints per-failure ::error:: annotations and appends a markdown table to the
job summary. Always exits 0 — the test step already failed the job; this is
reporting only.
"""

import json
import os
import re
import subprocess
import sys


def parse_xcresult(result_bundle):
    """Return parsed xcresult JSON, trying the new format then --legacy."""
    for legacy_flag in ["", "--legacy"]:
        try:
            cmd = ["xcrun", "xcresulttool", "get", "object"]
            if legacy_flag:
                cmd.append(legacy_flag)
            cmd.extend(["--path", result_bundle, "--format", "json"])
            result = subprocess.run(cmd, capture_output=True, text=True)
            if result.returncode == 0 and result.stdout.strip():
                return json.loads(result.stdout)
        except Exception:
            continue
    return None


def log_fallback(test_log):
    print(f"::warning::Test result bundle not found — falling back to log parsing of {test_log}")
    print("")
    pattern = re.compile(r"(✘|Test Case.*failed|FAIL|Assertion)")
    try:
        with open(test_log, errors="replace") as f:
            lines = [line.rstrip() for line in f if pattern.search(line)]
    except OSError:
        lines = []
    for line in lines[:50]:
        print(line)
    if not lines:
        print("No failures found in log")


def main():
    result_bundle = os.environ.get("RESULT_BUNDLE", "test-results/test.xcresult")
    test_name = os.environ.get("TEST_NAME", "Tests")
    test_log = os.environ.get("TEST_LOG", "/tmp/test_output.log")
    summary_file = os.environ.get("GITHUB_STEP_SUMMARY", "/dev/null")

    print("")
    print("============================================")
    print("          FAILED TESTS SUMMARY")
    print("============================================")
    print("")

    if not os.path.isdir(result_bundle):
        log_fallback(test_log)
        return

    data = parse_xcresult(result_bundle)
    if data is None:
        print("Could not parse xcresult bundle")
        return

    actions = data.get("actions", {}).get("_values", [])
    if not actions:
        print("No actions found in xcresult")
        return

    issues = actions[0].get("actionResult", {}).get("issues", {})
    failures = issues.get("testFailureSummaries", {}).get("_values", [])
    if not failures:
        print("No test failures found in xcresult (test may have crashed)")
        return

    print(f"Found {len(failures)} test failure(s):")
    print("")

    with open(summary_file, "a") as summary:
        summary.write(f"## Failed: {test_name}\n\n")
        summary.write("| Test | Failure Message |\n")
        summary.write("|------|----------------|\n")

        for f in failures:
            case = f.get("testCaseName", {}).get("_value", "Unknown Test")
            message = f.get("message", {}).get("_value", "No message")
            message_short = message[:150] + "..." if len(message) > 150 else message
            message_escaped = message_short.replace("|", "\\|").replace("\n", " ")

            print(f"❌ {case}")
            print(f"   {message_short}")
            print("")
            print(f"::error title={case}::{message_short}")
            summary.write(f"| `{case}` | {message_escaped} |\n")

    print("")
    print("See the uploaded .xcresult artifact for full details.")


if __name__ == "__main__":
    sys.exit(main())
