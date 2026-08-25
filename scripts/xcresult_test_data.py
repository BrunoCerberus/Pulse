"""Shared per-test extraction from xcresult bundles for the reporting scripts.

xcresult_common.py covers the *summary* object (metrics, failures). The
slow-test and test-count reports additionally need the per-test *tree*, which
lives behind the action result's `testsRef` and requires a second
`xcresulttool` call. This module is the single copy of that logic.

Format variance is handled the same way as in xcresult_common: Xcode 26
returns the tree for a bare `get object --id`, Xcode 27 requires `--legacy`
for the same call, so both are tried. The leaf walker matches on `_type`
name, making it indifferent to which wrapper representation it finds.
"""

import json
import subprocess

from xcresult_common import parse_xcresult

METADATA_TYPE = "ActionTestMetadata"


def _xcresulttool_get(bundle: str, legacy: bool, extra: list) -> dict | None:
    cmd = ["xcrun", "xcresulttool", "get", "object"]
    if legacy:
        cmd.append("--legacy")
    cmd.extend(["--path", bundle, "--format", "json", *extra])
    try:
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode == 0 and result.stdout.strip():
            return json.loads(result.stdout)
    except (OSError, json.JSONDecodeError):
        pass
    return None


def action_results(data: dict) -> list:
    """The actionResult dicts of every recorded action (usually one test run)."""
    actions = data.get("actions", {}).get("_values", [])
    results = []
    for action in actions:
        result = action.get("actionResult")
        if isinstance(result, dict):
            results.append(result)
    return results


def metric_value(metrics: dict | None, key: str) -> int | None:
    """Read an xcresult Int metric (``{"_type": ..., "_value": "30"}``)."""
    if not isinstance(metrics, dict):
        return None
    entry = metrics.get(key)
    if isinstance(entry, dict) and "_value" in entry:
        try:
            return int(float(entry["_value"]))
        except (TypeError, ValueError):
            return None
    return None


def total_test_count(data: dict) -> int | None:
    """Declared test count from the summary object's metrics.

    ``testsCount`` includes skipped tests, so it tracks how many tests the
    suite *knows about* — the right number for a deletion ratchet. Returns
    None when the metrics block is absent (older toolchain shapes) so callers
    can fall back to counting tree leaves.
    """
    total = 0
    found = False
    for result in action_results(data):
        count = metric_value(result.get("metrics"), "testsCount")
        if count is not None:
            total += count
            found = True
    return total if found else None


def fetch_test_tree(bundle: str) -> dict | None:
    """Fetch the referenced test tree for every action result, concatenated.

    Returns an object shaped `{"summaries": {"_values": [...]}}`; None when
    the tool cannot produce it (callers treat that as "no data", not an error).

    `parse_xcresult` recovers the main object in whichever CLI shape this
    Xcode accepts, but does not say which one it used, so the `--id` fetch is
    retried with both flag variants.
    """
    data = parse_xcresult(bundle)
    if data is None:
        return None
    ids = []
    for result in action_results(data):
        ref = result.get("testsRef", {})
        ref_id = ref.get("id", {}).get("_value")
        if ref_id:
            ids.append(ref_id)
    if not ids:
        return None
    for legacy in (False, True):
        trees = []
        for ref_id in ids:
            tree = _xcresulttool_get(bundle, legacy, ["--id", ref_id])
            if tree is None:
                break
            trees.append(tree)
        if trees:
            return {"summaries": {"_values": trees}}
    return None


def collect_test_leaves(node) -> "list":
    """Every ActionTestMetadata leaf in the tree, in document order.

    Deliberately shape-agnostic: it recurses through any nested dict/list, so
    it finds leaves regardless of the wrapper representation (summaries ->
    testableSummaries -> tests in the current toolchain, an inline `tests`
    tree in older ones).
    """
    leaves = []
    stack = [node]
    while stack:
        current = stack.pop()
        if not isinstance(current, dict):
            continue
        type_name = current.get("_type", {}).get("_name")
        if isinstance(type_name, str) and type_name == METADATA_TYPE:
            leaves.append(current)
            continue
        for value in current.values():
            if isinstance(value, dict) and "_values" in value:
                stack.extend(value["_values"])
            elif isinstance(value, dict):
                stack.append(value)
            elif isinstance(value, list):
                stack.extend(value)
    return leaves


def leaf_name(leaf: dict) -> str:
    """Stable identifier: `TestTarget.Class/testMethod()`.

    The tree leaves carry `identifier` (`Class/testMethod()`) but not the
    target, so the caller should prefix it; this returns the leaf's own
    identifier, falling back to `name` for older shapes.
    """
    for key in ("identifier", "name"):
        value = leaf.get(key)
        if isinstance(value, dict) and value.get("_value"):
            return value["_value"]
        if isinstance(value, str) and value:
            return value
    return "unknown"


def leaf_duration(leaf: dict) -> float | None:
    """Test duration in seconds (None when the leaf records none)."""
    value = leaf.get("duration")
    if isinstance(value, (int, float)):
        return float(value)
    if isinstance(value, dict) and "_value" in value:
        try:
            return float(value["_value"])
        except (TypeError, ValueError):
            return None
    return None


def leaf_status(leaf: dict) -> str:
    value = leaf.get("testStatus")
    if isinstance(value, dict):
        return value.get("_value", "Unknown")
    if isinstance(value, str):
        return value
    return "Unknown"


def leaves_by_target(tree: dict | None) -> list[tuple[str, dict]]:
    """[(target_name, leaf), ...] with the test-target prefix resolved.

    Walks summaries -> testableSummaries when present (current toolchain);
    leaves without a resolvable target fall back to their own identifier.
    """
    if not tree:
        return []
    results: list[tuple[str, dict]] = []
    for summary in tree.get("summaries", {}).get("_values", []):
        for testable in summary.get("testableSummaries", {}).get("_values", []):
            target = None
            name = testable.get("testTargetName")
            if isinstance(name, dict):
                target = name.get("_value")
            elif isinstance(name, str):
                target = name
            for leaf in collect_test_leaves(testable):
                results.append((target or leaf_name(leaf), leaf))
    if not results:
        # Older shape: one flat `tests` tree per summary, no target name.
        for summary in tree.get("summaries", {}).get("_values", []):
            for leaf in collect_test_leaves(summary):
                results.append((leaf_name(leaf), leaf))
    return results
