#!/usr/bin/env python3
"""Print the declared test count of an xcresult bundle (one integer, stdout).

Feeds the test-count ratchet in the Coverage Summary job. The count is the
number of tests the suite *knows about* — metrics `testsCount` (which includes
skipped tests) when the summary object carries it, otherwise a leaf count over
the referenced test tree. Deleting tests is the only way this number should
move, and the ratchet fails on a drop beyond tolerance.

Exit codes: 0 with the number on stdout, 2 when no count can be determined
(callers map that to a skipped ratchet, never a fabricated zero).
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

from xcresult_common import parse_xcresult
from xcresult_test_data import collect_test_leaves, fetch_test_tree, total_test_count


def main() -> int:
    bundle = os.environ.get("RESULT_BUNDLE")
    if bundle is None and len(sys.argv) > 1:
        bundle = sys.argv[1]
    if not bundle or not Path(bundle).is_dir():
        print(f"::warning::No result bundle at {bundle!r} — no test count")
        return 2

    data = parse_xcresult(bundle)
    if data is None:
        print(f"::warning::Could not parse {bundle} — no test count")
        return 2

    count = total_test_count(data)
    if count is None:
        tree = fetch_test_tree(bundle)
        count = len(collect_test_leaves(tree)) if tree is not None else None

    if count is None:
        print(f"::warning::No test count recoverable from {bundle}")
        return 2

    print(count)
    return 0


if __name__ == "__main__":
    sys.exit(main())
