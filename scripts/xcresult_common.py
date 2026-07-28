"""Shared xcresult parsing for the CI reporting scripts.

extract-test-failures.py, detect-flaky-tests.py and render-snapshot-failures.py
all need the same two operations: get JSON out of an .xcresult bundle across
xcresulttool's old and new CLI shapes, and pull the test-failure list out of it.
This module is the single copy. Imported by path — the scripts are invoked as
`python3 scripts/<name>.py`, which puts scripts/ on sys.path.
"""

import json
import subprocess


def parse_xcresult(result_bundle):
    """Return parsed xcresult JSON, trying the new format then --legacy.

    Xcode 16 moved `xcresulttool get` behind a --legacy flag for the object
    format this parsing relies on; older toolchains reject the flag outright.
    Trying both, in that order, works across the range without version sniffing.
    Returns None when neither shape yields parsable JSON.
    """
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


def collect_failures(data):
    """Return [(test_case_name, message)] recorded in a parsed bundle."""
    actions = data.get("actions", {}).get("_values", [])
    if not actions:
        return []
    issues = actions[0].get("actionResult", {}).get("issues", {})
    summaries = issues.get("testFailureSummaries", {}).get("_values", [])

    failures = []
    for f in summaries:
        case = f.get("testCaseName", {}).get("_value", "Unknown Test")
        message = f.get("message", {}).get("_value", "No message")
        failures.append((case, message))
    return failures


def truncate(message, limit=150):
    """Shorten a failure message for single-line display."""
    return message[:limit] + "..." if len(message) > limit else message


def escape_cell(text):
    """Make a string safe to drop into a markdown table cell."""
    return text.replace("|", "\\|").replace("\n", " ")
