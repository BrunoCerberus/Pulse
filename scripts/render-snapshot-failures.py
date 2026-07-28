#!/usr/bin/env python3
"""Render failing snapshot tests as a PR comment body.

When a snapshot test fails, the useful evidence (the recorded PNGs) is already
uploaded as the `recorded-snapshots` artifact — but finding it means opening the
run, scrolling to the artifacts section, downloading a zip and diffing by hand.
This renders a comment that names the failing cases and links straight to the
run's artifact list, so triage starts from the PR.

NOTE: the images themselves are not inlined. GitHub comments can only embed
images by URL, and artifact contents have no stable public URL — attaching them
would mean pushing binaries to a branch or an external host. The link-plus-names
form is deliberate.

Inputs (environment):

  RESULT_BUNDLE  path to the snapshot .xcresult bundle
  OUTPUT         markdown file to write (default snapshot-failures.md)
  RUN_URL        URL of the current workflow run
  GITHUB_OUTPUT  step-output file; receives `has_failures=true|false`
"""

import os
import sys

from xcresult_common import collect_failures, escape_cell, parse_xcresult, truncate


def render(failures, run_url):
    lines = [
        "## 📸 Snapshot test failures",
        "",
        f"{len(failures)} snapshot test(s) failed. The recorded PNGs are attached "
        f"to the run as the **recorded-snapshots** artifact:",
        "",
        f"➡️ [Download recorded snapshots]({run_url}#artifacts)",
        "",
        "| Test | Failure |",
        "|------|---------|",
    ]
    for case, message in failures:
        lines.append(f"| `{case}` | {escape_cell(truncate(message))} |")
    lines += [
        "",
        "If these are intentional UI changes, re-record the references locally "
        "and commit them — never lower the comparison precision.",
        "",
        "<!-- snapshot-failures -->",
    ]
    return "\n".join(lines) + "\n"


def main():
    result_bundle = os.environ.get("RESULT_BUNDLE", "test-results/snapshot-test-results.xcresult")
    output = os.environ.get("OUTPUT", "snapshot-failures.md")
    run_url = os.environ.get("RUN_URL", "")
    github_output = os.environ.get("GITHUB_OUTPUT", "/dev/null")

    failures = []
    if not os.path.isdir(result_bundle):
        print(f"::warning::No result bundle at {result_bundle} — skipping snapshot report")
    else:
        data = parse_xcresult(result_bundle)
        if data is None:
            print("::warning::Could not parse xcresult bundle — skipping snapshot report")
        else:
            failures = collect_failures(data)

    if failures:
        markdown = render(failures, run_url)
        with open(output, "w") as fh:
            fh.write(markdown)
        print(markdown)
    else:
        print("No snapshot failures to report.")

    with open(github_output, "a") as fh:
        fh.write(f"has_failures={'true' if failures else 'false'}\n")


if __name__ == "__main__":
    sys.exit(main())
