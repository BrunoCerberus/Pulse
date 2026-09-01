#!/usr/bin/env python3
"""Fail when a workflow's `-only-testing` selector names a test that is gone.

`xcodebuild -only-testing:Target/Class/method` does NOT error on a selector
that matches nothing: it runs zero tests and exits 0. Any workflow that names
individual tests is therefore one rename away from a green job that covers
nothing — the same silent-no-op class as passing a comma-joined target name.

The PR-time iPad leg is exactly that shape: a hand-picked smoke set of
`PulseUITests/<Class>/<method>` selectors chosen to exercise the regular-width
adaptive paths without re-running every device-independent flow. This walks
every `test-selectors:` input in .github/workflows/*.yml and checks that each
three-part selector's class and method still exist in the target's sources.

Two-part (`Target/Class`) and bare-target selectors are checked as far as they
go — a whole-target selector is the case xcodebuild *does* fail loudly on.

`run-ios-test-suite.py` also fails a run that executed zero tests, which
catches this at run time; this script is the cheap half that fails in the
Code Quality job in seconds instead of after a 45-minute build.

Usage: check-test-selectors.py <repo-root>
       check-test-selectors.py --self-test
Exit codes: 0 = every selector resolves, 1 = a selector is dangling, 2 = bad args.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

SELECTOR_BLOCK = re.compile(r"^\s*test-selectors:\s*(?P<inline>\S.*)?$")
CLASS_PATTERN = "(?:final\\s+)?class\\s+{name}\\s*[:{{]"
METHOD_PATTERN = "func\\s+{name}\\s*\\("


def extract_selectors(text: str) -> list[str]:
    """Every selector named by a `test-selectors:` input in one workflow file.

    Handles both the inline form (`test-selectors: PulseTests,PulseWidget…`)
    and the folded-block form (`test-selectors: >-` followed by indented,
    comma-separated lines), which is how the multi-test legs are written."""
    selectors: list[str] = []
    lines = text.splitlines()
    index = 0
    while index < len(lines):
        match = SELECTOR_BLOCK.match(lines[index])
        if not match:
            index += 1
            continue
        inline = (match.group("inline") or "").strip()
        indent = len(lines[index]) - len(lines[index].lstrip())
        index += 1
        if inline and inline not in (">-", ">", "|-", "|"):
            raw = inline
        else:
            block: list[str] = []
            while index < len(lines):
                line = lines[index]
                if line.strip() and (len(line) - len(line.lstrip())) <= indent:
                    break
                block.append(line.strip())
                index += 1
            raw = " ".join(block)
        selectors.extend(part.strip() for part in raw.split(",") if part.strip())
    return selectors


def resolve(selector: str, root: Path) -> str | None:
    """Error message when the selector cannot be resolved, else None."""
    parts = selector.split("/")
    target = parts[0]
    # ${{ … }} selectors come from a matrix; the matrix values are targets, and
    # a bad target name makes xcodebuild fail loudly, so skip them.
    if "${{" in selector:
        return None
    target_dir = root / target
    if not target_dir.is_dir():
        return f"{selector}: no such test target directory '{target}/'"
    if len(parts) == 1:
        return None

    sources = list(target_dir.rglob("*.swift"))
    class_name = parts[1]
    matches = [
        path
        for path in sources
        if re.search(CLASS_PATTERN.format(name=re.escape(class_name)), path.read_text(encoding="utf-8", errors="replace"))
    ]
    if not matches:
        return f"{selector}: class '{class_name}' not found in {target}/"
    if len(parts) == 2:
        return None

    method_name = parts[2]
    pattern = re.compile(METHOD_PATTERN.format(name=re.escape(method_name)))
    if not any(pattern.search(path.read_text(encoding="utf-8", errors="replace")) for path in matches):
        return f"{selector}: method '{method_name}()' not found in class '{class_name}'"
    return None


def check(root: Path) -> int:
    workflows = sorted((root / ".github" / "workflows").glob("*.yml"))
    problems: list[str] = []
    checked = 0
    for workflow in workflows:
        for selector in extract_selectors(workflow.read_text(encoding="utf-8")):
            checked += 1
            problem = resolve(selector, root)
            if problem:
                problems.append(f"{workflow.relative_to(root)}: {problem}")

    for problem in problems:
        print(f"::error::{problem}")
    if problems:
        print(
            f"\n{len(problems)} dangling test selector(s). xcodebuild runs ZERO tests and exits 0 "
            "for a selector that matches nothing, so this would have merged as a green, empty suite."
        )
        return 1
    print(f"All {checked} workflow test selectors resolve.")
    return 0


def self_test() -> None:
    import tempfile

    inline = "      with:\n        test-selectors: PulseTests,PulseWidgetExtensionTests\n        test-name: Unit\n"
    assert extract_selectors(inline) == ["PulseTests", "PulseWidgetExtensionTests"], extract_selectors(inline)

    folded = (
        "        test-selectors: >-\n"
        "          PulseUITests/NavigationUITests/testNavigationFlow,\n"
        "          PulseUITests/AccessibilityAuditTests/testHomeAccessibilityAudit\n"
        "        test-name: UI Tests (iPad)\n"
    )
    assert extract_selectors(folded) == [
        "PulseUITests/NavigationUITests/testNavigationFlow",
        "PulseUITests/AccessibilityAuditTests/testHomeAccessibilityAudit",
    ], extract_selectors(folded)
    assert extract_selectors("        test-selectors: ${{ matrix.test-target }}\n") == ["${{ matrix.test-target }}"]

    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        target = root / "FakeUITests"
        target.mkdir()
        (target / "Nav.swift").write_text(
            "import XCTest\nfinal class NavTests: XCTestCase {\n    func testFlow() {}\n}\n",
            encoding="utf-8",
        )
        assert resolve("FakeUITests", root) is None
        assert resolve("FakeUITests/NavTests", root) is None
        assert resolve("FakeUITests/NavTests/testFlow", root) is None
        # A matrix expression is not resolvable and must not be reported.
        assert resolve("${{ matrix.test-target }}", root) is None
        # The three real failure modes.
        assert "no such test target" in (resolve("GhostTests", root) or "")
        assert "class 'GoneTests' not found" in (resolve("FakeUITests/GoneTests", root) or "")
        assert "method 'testGone()' not found" in (resolve("FakeUITests/NavTests/testGone", root) or "")
        # A method that exists in a DIFFERENT class must not satisfy the selector.
        (target / "Other.swift").write_text(
            "final class OtherTests: XCTestCase {\n    func testElsewhere() {}\n}\n", encoding="utf-8"
        )
        assert "method 'testElsewhere()' not found" in (resolve("FakeUITests/NavTests/testElsewhere", root) or "")

    print("self-test passed")


def main() -> int:
    args = sys.argv[1:]
    if "--self-test" in args:
        self_test()
        return 0
    if len(args) != 1:
        print(__doc__)
        return 2
    return check(Path(args[0]).resolve())


if __name__ == "__main__":
    raise SystemExit(main())
