#!/usr/bin/env python3
"""Determine whether a PR's diff affects UI code and requires UI tests.

Compares two refs (default: base SHA vs head SHA of the PR) and checks
whether any changed file falls into a UI-affecting path category.

UI-affecting paths:
  - Any Swift source inside Pulse/, PulseShareExtension, PulseWidgetExtension
    (SwiftUI is reactive — changes in services/viewmodels often ripple into views)
  - Tests that exercise UI paths (PulseUITests, PulseSnapshotTests)
  - Localizable.strings files in en.lproj / pt.lproj / es.lproj
  - Assets.xcassets directories (images, colors, accents)
  - Core Data / SwiftData model files (.xcdatamodeld)

Non-UI paths (safe to skip):
  - .github/workflows/, .github/actions/ themselves
  - docs/, scripts/*, Makefile, SwiftFormat/SwiftLint configs
  - Package.resolved, .gitignore, etc.

Usage:
    python3 check-ui-impact.py [--base-sha <sha>] [--head-sha <sha>]

Environment variables take precedence over CLI args.
Base SHA defaults to github.event.pull_request.base.sha (ci.yml).
Head SHA defaults to github.event.pull_request.head.sha.

Outputs:
    echo "::set-output name=run-ui-tests::<true|false>"  (legacy)
    echo "run_ui_tests=<value>" >> "$GITHUB_OUTPUT"      (modern)

Also emits a short human-readable line for the job log.
"""

import argparse
import os
import subprocess
import sys


# ---------------------------------------------------------------------------
# Path categories that affect UI rendering, layout, or presentation.
# Each tuple is (glob-pattern-prefix, impact-description).
# We only need the prefix for matching.
# ---------------------------------------------------------------------------

UI_IMPACTING_PATHS = [
    # All Swift source in the three app targets — SwiftUI is reactive;
    # a change in a service, storage layer, or domain interactor can
    # transitively affect how views present data.
    "Pulse/",
    "PulseShareExtension/",
    "PulseWidgetExtension/",

    # UI test targets themselves (test authors added a new test = UI changed).
    "PulseUITests/",
    "PulseSnapshotTests/",

    # Localization strings directly affect label text and layout.
    "Pulse/en.lproj/",
    "Pulse/pt.lproj/",
    "Pulse/es.lproj/",

    # Assets: images, color assets, accent colors drive visuals.
    "Pulse/Assets.xcassets",

    # Core Data model changes affect data displayed on screen.
    ".xcdatamodeld",
]


def get_changed_files(
    base_sha: str, head_sha: str, fallback_run_tests: list[str] | None = None
) -> list[str]:
    """Return the list of file paths changed by the PR (merge-base diff).

    Uses a three-dot (``...``) merge-base diff to isolate only the PR's
    own commits — a two-dot (``..``) diff would also include unrelated
    churn on the base branch if ``master`` advanced after this PR was
    created, skewing the impact decision.

    *fallback_run_tests* is used when git fails — if provided, those
    paths are returned so the caller can run UI tests as a safe default.
    """
    try:
        mb = subprocess.run(
            ["git", "merge-base", base_sha, head_sha],
            capture_output=True, text=True,
        )
        if mb.returncode != 0:
            print(
                f"::warning::merge-base failed ({mb.stderr.strip().splitlines()[0]}); "
                f"defaulting to full diff"
            )
            merge_base = base_sha
        else:
            merge_base = mb.stdout.strip()

        result = subprocess.run(
            ["git", "diff", "--name-only", f"{merge_base}..{head_sha}"],
            capture_output=True, text=True,
        )
        if result.returncode != 0:
            print(f"::error::git diff failed: {result.stderr.strip()}")
            if fallback_run_tests:
                return fallback_run_tests
            sys.exit(1)

        files = [f for f in result.stdout.strip().splitlines() if f]
    except Exception as exc:
        print(f"::error::Failed to list changed files: {exc}")
        if fallback_run_tests:
            return fallback_run_tests
        sys.exit(1)

    return files


def is_ui_impacting(filepath: str, ui_paths: list[str]) -> bool:
    """Return True if *filepath* matches any UI-impact category."""
    for pattern in ui_paths:
        if ".xcdatamodeld" == pattern and ".xcdatamodeld" in filepath:
            return True
        if filepath.startswith(pattern):
            return True
    return False


def main():
    parser = argparse.ArgumentParser(
        description="Decide whether UI tests are needed for a PR."
    )
    parser.add_argument(
        "--base-sha",
        default=os.environ.get("GITHUB_BASE_SHA"),
        help="Base ref SHA (PR base).",
    )
    parser.add_argument(
        "--head-sha",
        default=os.environ.get("GITHUB_HEAD_SHA"),
        help="Head ref SHA (PR head / latest commit).",
    )
    args = parser.parse_args()

    base_sha: str | None = args.base_sha
    head_sha: str | None = args.head_sha

    # When running from ci.yml the env vars are injected by the job's
    # `env:` block.  If both are absent we can't diff — default to running UI
    # tests so nothing is ever skipped.
    if not base_sha or not head_sha:
        print(
            "No SHA provided (or env vars missing); running UI tests to be safe."
        )
        set_output("true")
        return

    # Pass a fallback list that is guaranteed to trigger the "run tests"
    # decision.  If git diff/merge-base fails, we return these paths so the
    # caller runs UI tests — consistent with the missing-SHA safety net.
    changed_files = get_changed_files(
        base_sha, head_sha, fallback_run_tests=UI_IMPACTING_PATHS
    )
    print(f"Changed files: {len(changed_files)}")

    impacting = [f for f in changed_files if is_ui_impacting(f, UI_IMPACTING_PATHS)]

    if impacting:
        print(f"UI-impacting changes detected in {len(impacting)} files.")
        for f in impacting[:15]:  # cap the log output
            print(f"  - {f}")
        if len(impacting) > 15:
            print(f"  ... and {len(impacting) - 15} more")
        set_output("true")
    else:
        print("No UI-affecting changes; safe to skip UI tests.")
        set_output("false")


def set_output(value: str):
    """Write the output for GitHub Actions in both legacy and modern formats."""
    # Modern format (actions/checkout >= 3.x)
    if "GITHUB_OUTPUT" in os.environ:
        with open(os.environ["GITHUB_OUTPUT"], "a") as f:
            print(f"run_ui_tests={value}", file=f)

    # Legacy format (fallback for older runners)
    print(f"::set-output name=run-ui-tests::{value}")


if __name__ == "__main__":
    main()
