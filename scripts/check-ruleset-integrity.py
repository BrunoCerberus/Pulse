#!/usr/bin/env python3
"""Check the live master ruleset still requires every expected status check.

The merge model rests on the master ruleset's *required* status checks — the
privacy conformance jobs, the test suites, the ratchets, the CodeQL and Claude
review scans, and the style gates all only block merges because the ruleset
requires them. Nothing else observes that ruleset: if a required
check is removed or renamed (a ruleset edited in the UI, a ruleset rewrite, a
GitHub migration), the gate silently stops blocking and no workflow fails,
because a missing required check is simply absent rather than red.

This script closes that gap. The workflow feeds it the union of required-check
contexts across all active rulesets that apply to master (the ``rules`` field
is only returned by the single-ruleset endpoint, so the workflow fetches each
ruleset by id); this script diffs it against the committed expected list in
``.github/required-checks.json``.

Direction matters, deliberately:

  - a context MISSING from the live ruleset is a FAILURE — a gate stopped
    blocking;
  - a context PRESENT but not expected is a WARNING — someone added a gate
    on purpose; surface it so the list gets updated, never block on intent;
  - an EMPTY actual list is a FAILURE, not a pass — an audit that cannot
    verify must not report "all good" (fail-closed: an empty union means the
    ruleset was deleted or the fetch broke, and both are worth a red run).

A missing-context failure also writes ``ruleset-drift-report.md`` in the
current directory; the workflow uses it as the tracking-issue body.

``--self-test`` exercises all four classifications (match / missing / extra /
empty) against synthetic inputs, because a green tree only proves the lists
agree today, not that a future removal would be caught.

Usage: check-ruleset-integrity.py --actual <actual-contexts.json> --expected <required-checks.json>
      check-ruleset-integrity.py --self-test
Exit codes: 0 = in sync (or expected extras only), 1 = drift or unverifiable,
2 = bad args / unreadable input.
"""
from __future__ import annotations

import json
import os
import sys
import tempfile
from pathlib import Path

REPORT_FILE = "ruleset-drift-report.md"


def emit_summary(text: str) -> None:
    """Append to the GitHub step summary when running in Actions."""
    summary_path = os.environ.get("GITHUB_STEP_SUMMARY")
    if not summary_path:
        return
    with open(summary_path, "a", encoding="utf-8") as handle:
        handle.write(text + "\n")


def load_expected(path: Path) -> list[str] | None:
    """Accept {"required_contexts": [...]} or a bare list."""
    with open(path, encoding="utf-8") as handle:
        data = json.load(handle)
    if isinstance(data, dict):
        data = data.get("required_contexts")
    if not isinstance(data, list) or not all(isinstance(c, str) for c in data):
        return None
    return sorted(set(data))


def load_actual(path: Path) -> list[str] | None:
    """The workflow emits a JSON array of context strings."""
    try:
        with open(path, encoding="utf-8") as handle:
            data = json.load(handle)
    except (OSError, json.JSONDecodeError):
        return None
    if not isinstance(data, list) or not all(isinstance(c, str) for c in data):
        return None
    return sorted(set(data))


def check(expected: list[str], actual: list[str]) -> tuple[int, str]:
    """Compare the lists; return (exit_code, report_markdown)."""
    missing = [c for c in expected if c not in actual]
    extra = [c for c in actual if c not in expected]

    if not actual:
        report = (
            "## Ruleset integrity\n\n"
            "No required status checks could be read from the live ruleset — the "
            "ruleset was deleted, the API fetch failed, or the shape changed. "
            "Failing closed: the required-check gate cannot be assumed intact.\n"
        )
        print("::error::No required-check contexts could be read — failing closed.")
        emit_summary(report)
        return 1, report

    if missing:
        for context in missing:
            print(f"::error::Required check context '{context}' is no longer in the master ruleset — the gate it provides no longer blocks merges.")
        for context in extra:
            print(f"::warning::Context '{context}' is required by the ruleset but not in .github/required-checks.json — add it to ratify the new gate.")
        report = (
            "## Ruleset drift detected\n\n"
            f"**{len(missing)}** expected required check(s) missing from the live master ruleset — "
            "the gate(s) they provide no longer block merges:\n\n"
            + "\n".join(f"- `{c}`" for c in missing)
            + (
                "\n\nAlso present but not in the expected list (add to `.github/required-checks.json` to ratify):\n\n"
                + "\n".join(f"- `{c}`" for c in extra)
                if extra
                else ""
            )
            + "\n"
        )
        print("\nRuleset integrity check FAILED — see errors above.")
        return 1, report

    if extra:
        for context in extra:
            print(f"::warning::Context '{context}' is required by the ruleset but not in .github/required-checks.json — add it to ratify the new gate.")
        report = (
            "## Ruleset integrity\n\n"
            "All expected required checks are in place. "
            f"{len(extra)} additional context(s) present — update `.github/required-checks.json` to ratify:\n\n"
            + "\n".join(f"- `{c}`" for c in extra)
            + "\n"
        )
        return 0, report

    report = "## Ruleset integrity\n\nAll expected required checks are present in the master ruleset.\n"
    print("Ruleset integrity check passed — live ruleset matches the expected list.")
    return 0, report


def run(actual_path: Path, expected_path: Path, report_path: Path) -> int:
    expected = load_expected(expected_path)
    if expected is None:
        print(f"::error::Could not parse expected list at {expected_path} — failing closed.", file=sys.stderr)
        return 2
    actual = load_actual(actual_path)
    if actual is None and not actual_path.exists():
        print("::error::No actual contexts file — the ruleset fetch step did not produce output. Failing closed.", file=sys.stderr)
        return 1
    if actual is None:
        print(f"::error::Could not parse actual contexts at {actual_path} — failing closed.", file=sys.stderr)
        return 2

    code, report = check(expected, actual)
    emit_summary(report)
    # Written even on a pass-with-warnings: the workflow reads it when the job
    # is red, and a warnings-only verdict is the most useful one to keep.
    report_path.write_text(report, encoding="utf-8")
    if code != 0:
        print(f"Report written to {report_path} for the tracking issue.")
    return code


def self_test() -> int:
    failures: list[str] = []

    def expect(condition: bool, label: str) -> None:
        if not condition:
            failures.append(label)

    with tempfile.TemporaryDirectory() as tmp:
        tmp_root = Path(tmp)
        expected_file = tmp_root / "expected.json"
        expected_file.write_text(
            json.dumps({"required_contexts": ["Code Quality", "Unit Tests", "Patch Coverage"]}),
            encoding="utf-8",
        )

        def run_case(name: str, actual: list[str]) -> int:
            actual_file = tmp_root / f"{name}.json"
            actual_file.write_text(json.dumps(actual), encoding="utf-8")
            return run(actual_file, expected_file, tmp_root / f"{name}-report.md")

        def report(name: str) -> str:
            path = tmp_root / f"{name}-report.md"
            return path.read_text(encoding="utf-8") if path.exists() else ""

        code = run_case("match", ["Code Quality", "Unit Tests", "Patch Coverage"])
        expect(code == 0, "in-sync lists did not pass")

        code = run_case("missing", ["Code Quality", "Unit Tests"])
        expect(code == 1, "a missing required context did not fail")
        expect("Patch Coverage" in report("missing"), "missing context absent from the report")

        code = run_case("extra", ["Code Quality", "Unit Tests", "Patch Coverage", "New Gate"])
        expect(code == 0, "an extra (deliberately added) context failed the check")
        expect("New Gate" in report("extra"), "extra context not surfaced in the report")

        code = run_case("empty", [])
        expect(code == 1, "an empty actual list (fetch broke / ruleset deleted) did not fail")

    if failures:
        for failure in failures:
            print(f"self-test FAILED: {failure}", file=sys.stderr)
        return 1
    print("self-test passed (in-sync / missing / extra / empty cases all classified correctly).")
    return 0


def main() -> int:
    args = sys.argv[1:]
    if args == ["--self-test"]:
        return self_test()
    if len(args) != 4 or args[0] != "--actual" or args[2] != "--expected":
        print(
            "usage: check-ruleset-integrity.py --actual <actual-contexts.json> --expected <required-checks.json> | --self-test",
            file=sys.stderr,
        )
        return 2
    return run(Path(args[1]).resolve(), Path(args[3]).resolve(), Path(REPORT_FILE))


if __name__ == "__main__":
    sys.exit(main())
