#!/usr/bin/env python3
"""Print the declared test count of an xcresult bundle (one integer, stdout).

Feeds the test-count ratchet in the Coverage Summary job. The count is the
number of *distinct* tests the suite knows about: a deduped identity count over
the referenced test tree (so a retried execution from `-retry-tests-on-failure`
counts once and cannot move the baseline), falling back to the summary's
`testsCount` metric when the tree cannot be fetched. Deleting tests is the only
way this number should move, and the ratchet fails on a drop beyond tolerance.

The count is the only thing written to stdout; `::warning::` diagnostics go to
stderr so a caller that redirects stdout to a file does not swallow them.

Exit codes: 0 with the number on stdout, 2 when no count can be determined
(callers map that to a skipped ratchet, never a fabricated zero).
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

from xcresult_common import parse_xcresult
from xcresult_test_data import (
    collect_test_leaves,
    fetch_test_tree,
    leaf_name,
    total_test_count,
)


def unique_test_count(tree: dict | None) -> int | None:
    """Count of *distinct* tests, deduped by identity so a retried execution
    (``-retry-tests-on-failure``) counts once. Returns None when the tree yields
    no resolvable identities. Diagnostics go to stderr so the caller can redirect
    only the count (stdout) without swallowing the warning."""
    if tree is None:
        return None
    identities = {leaf_name(leaf) for leaf in collect_test_leaves(tree)}
    identities.discard("unknown")
    if not identities:
        print("::warning::Test tree present but no resolvable test identities", file=sys.stderr)
        return None
    return len(identities)


def main() -> int:
    bundle = os.environ.get("RESULT_BUNDLE")
    if bundle is None and len(sys.argv) > 1:
        bundle = sys.argv[1]
    if not bundle or not Path(bundle).is_dir():
        print(f"::warning::No result bundle at {bundle!r} — no test count", file=sys.stderr)
        return 2

    data = parse_xcresult(bundle)
    if data is None:
        print(f"::warning::Could not parse {bundle} — no test count", file=sys.stderr)
        return 2

    # The ratchet tracks how many distinct tests exist. Prefer the retry-stable
    # unique-identity count over the raw `testsCount` metric, which the xcresult
    # summary counts per execution — so flaky retries would move the baseline.
    count = unique_test_count(fetch_test_tree(bundle))
    if count is None:
        count = total_test_count(data)

    if count is None:
        print(f"::warning::No test count recoverable from {bundle}", file=sys.stderr)
        return 2

    print(count)
    return 0


if __name__ == "__main__":
    sys.exit(main())
