#!/usr/bin/env python3
"""Fail when committed snapshot references point at test methods that no longer exist.

SnapshotTesting writes references under ``<Target>/.../__Snapshots__/<TestClass>/<testMethod>.N.png``
and never deletes them when a test method is renamed or removed — dead PNGs
accumulate in the repo (each re-uploaded by the CI recorded-snapshots
artifact, and a stale reference is exactly what makes a future re-record
session look like it "repaired" nothing). This check closes the loop:

  - for every test-type directory inside a ``__Snapshots__`` tree, that type
    (an XCTest ``class`` or a Swift Testing ``@Suite struct``) must still be
    declared in the sources;
  - for every reference file, the stem (after stripping the ``.N`` ordinal)
    must resolve to a ``func <name>(`` declared in that class's source file(s)
    — directly, via a ``-``-separated device/identifier segment, or as a
    method name with a dynamic suffix: SnapshotTesting's ``testName:
    "foo_\\(x)"`` records as ``foo_<value>.N.png`` under a *looped* method,
    so a stem that starts with a declared method and then a separator is live.
    (Without that rule the GlassArticleCard category-loop references would be
    reported as orphans and deleted, breaking the live test on next run.)

Single pass: the tree is read once, building {class: files} and
{file: methods} indexes, so runtime is O(repo) regardless of how many
reference directories exist.

``--self-test`` builds a synthetic tree (live method, identifier suffix,
renamed-method orphan, dead-class orphan) in a temp dir and asserts the
detector classifies each correctly — a clean repo proves the check has no
false positives, the self-test proves it still has teeth.

Usage: ``check-orphan-snapshots.py [ROOT]`` (defaults to CWD).
Exit codes: 0 = no orphans, 1 = orphans found, 2 = bad usage / self-test failure.
"""
from __future__ import annotations

import re
import sys
import tempfile
from pathlib import Path

# ".claude" holds git worktree checkouts of this same repo — their copies of
# __Snapshots__ are untracked and would double every finding.
SKIP_DIRS = {"DerivedData", ".build", ".git", ".claude"}
# Snapshot test types: an XCTest ``class``/``final class`` or a Swift Testing
# ``@Suite struct`` (the attribute sits on the prior line; only the declaration
# keyword is matched). A struct suite that matched no declaration would read as
# a dead class and its live references would be flagged for deletion.
TYPE_RE = re.compile(r"\b(?:final\s+)?(?:class|struct)\s+(\w+)\b")
METHOD_RE = re.compile(r"\bfunc\s+(\w+)\s*\(")
ORDINAL_RE = re.compile(r"\.\d+$")
# SnapshotTesting's `testName:` overrides the recorded name; an interpolated
# literal like "foo_\\(x)" records as foo_<value>.N.png under a *looped*
# method, so the static prefix/suffix of the literal is what keeps such
# references resolvable.
TEST_NAME_RE = re.compile(r'testName:\s*"((?:[^"\\]|\\.)*)"')


def dynamic_name_templates(text: str) -> list[tuple[str, str]]:
    """[(prefix, suffix), ...] for every `testName:` literal in the source.

    An uninterpolated literal yields (name, "") — an exact-name candidate.
    Interpolations are collapsed, leaving the static head and tail.
    """
    templates = []
    for match in TEST_NAME_RE.finditer(text):
        literal = match.group(1)
        prefix, _, rest = literal.partition("\\(")
        _, _, suffix = rest.partition("\\)")
        templates.append((prefix, suffix))
    return templates


class Index:
    """One-pass index of class declarations, test methods, and dynamic snapshot
    name templates over the tree."""

    def __init__(self, root: Path):
        self.type_files: dict[str, list[Path]] = {}
        self.file_methods: dict[Path, set[str]] = {}
        self.file_templates: dict[Path, list[tuple[str, str]]] = {}
        for swift in root.rglob("*.swift"):
            if SKIP_DIRS.intersection(swift.parts):
                continue
            try:
                text = swift.read_text()
            except (OSError, UnicodeDecodeError):
                continue
            self.file_methods[swift] = set(METHOD_RE.findall(text))
            self.file_templates[swift] = dynamic_name_templates(text)
            for name in TYPE_RE.findall(text):
                self.type_files.setdefault(name, []).append(swift)

    def methods(self, type_name: str) -> set[str] | None:
        files = self.type_files.get(type_name)
        if not files:
            return None
        methods: set[str] = set()
        for swift in files:
            methods |= self.file_methods.get(swift, set())
        return methods

    def templates(self, type_name: str) -> list[tuple[str, str]]:
        files = self.type_files.get(type_name)
        if not files:
            return []
        templates: list[tuple[str, str]] = []
        for swift in files:
            templates.extend(self.file_templates.get(swift, []))
        return templates


def find_snapshots_dirs(root: Path) -> list[Path]:
    return sorted(
        p for p in root.rglob("__Snapshots__")
        if p.is_dir() and not (SKIP_DIRS.intersection(p.parts))
    )


def stem_is_live(stem: str, methods: set[str], templates: list[tuple[str, str]] = ()) -> bool:
    """A stem is live if it is itself a method, or any '-'-delimited segment or
    prefix/suffix is one (covers ``<method>-<identifier>`` and
    ``<device>-<method>`` reference naming), or it extends a declared method
    across a separator, or it matches a dynamic ``testName:`` template
    (``testName: "method_\\(value)"`` records under a *looped* method, so the
    recorded stem need not be a declared name at all). The separator
    requirement on method prefixes keeps a renamed method (``testFoo`` ->
    ``testFoobar``) from masking the orphan its old references left behind.

    The template match is the one deliberate false-negative trade: a deleted
    method whose name happens to prefix a surviving ``testName:`` literal's
    static head would read as live. That is rarer than the live loop case it
    exists for, and both surfaces re-record cleanly on ``--record``."""
    parts = stem.split("-")
    candidates = {stem, *parts}
    for i in range(1, len(parts)):
        candidates.add("-".join(parts[:i]))
        candidates.add("-".join(parts[i:]))
    if any(c in methods for c in candidates if c):
        return True
    if any(
        stem.startswith(method) and len(stem) > len(method)
        and stem[len(method)] in "_-."
        for method in methods
    ):
        return True
    # A fully-interpolated literal ("" prefix/suffix) would match everything,
    # so require at least one static fragment.
    return any(
        (prefix or suffix)
        and stem.startswith(prefix)
        and stem.endswith(suffix)
        for prefix, suffix in templates
    )


def find_orphans(root: Path) -> list[tuple[Path, bool]]:
    """Return [(ref_file, whole_class_dir_dead), ...] — orphans only."""
    index = Index(root)
    orphans = []
    for snaps_dir in find_snapshots_dirs(root):
        for class_dir in sorted(p for p in snaps_dir.iterdir() if p.is_dir()):
            methods = index.methods(class_dir.name)
            for ref in sorted(class_dir.iterdir()):
                if not ref.is_file() or ref.suffix != ".png":
                    continue
                stem = ORDINAL_RE.sub("", ref.name[: -len(".png")])
                if methods is None:
                    orphans.append((ref, True))
                elif not stem_is_live(stem, methods, index.templates(class_dir.name)):
                    orphans.append((ref, False))
    return orphans


def self_test() -> int:
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        live_dir = root / "T" / "__Snapshots__" / "LiveTests"
        renamed_dir = root / "T" / "__Snapshots__" / "RenamedTests"
        dead_dir = root / "T" / "__Snapshots__" / "DeletedTests"
        struct_live_dir = root / "T" / "__Snapshots__" / "StructLiveTests"
        struct_dead_dir = root / "T" / "__Snapshots__" / "StructDeletedTests"
        for d in (live_dir, renamed_dir, dead_dir, struct_live_dir, struct_dead_dir):
            d.mkdir(parents=True)
        # testOldName was renamed to testRenamed — its old reference is an orphan.
        (root / "T" / "LiveTests.swift").write_text(
            "class LiveTests: XCTestCase {\n"
            "    func testLive() {}\n"
            "    func testRenamed() {}\n"
            "    func testDynamic() {}\n"
            "    private func helper() {}\n"
            "}\n"
        )
        (root / "T" / "RenamedTests.swift").write_text(
            "class RenamedTests: XCTestCase {\n"
            "    func testNewName() {}\n"
            "}\n"
        )
        # A Swift Testing suite is a struct, not a class — its live reference
        # must not read as a dead class.
        (root / "T" / "StructLiveTests.swift").write_text(
            "@Suite\n"
            "struct StructLiveTests {\n"
            "    @Test\n"
            "    func testLiveStruct() {}\n"
            "}\n"
        )
        # live method, identifier suffix, renamed-method orphan (x2),
        # dynamic testName suffix (live), rename that would mask via prefix (orphan),
        # dead-class orphan, live struct ref (not an orphan), dead-struct orphan
        (live_dir / "testLive.1.png").write_bytes(b"x")
        (live_dir / "testLive-dark.1.png").write_bytes(b"x")
        (live_dir / "testOldName.2.png").write_bytes(b"x")
        (live_dir / "testDynamic_value.1.png").write_bytes(b"x")
        (live_dir / "testDynamicallyRenamed.1.png").write_bytes(b"x")
        (renamed_dir / "testOldName.1.png").write_bytes(b"x")
        (dead_dir / "testGone.1.png").write_bytes(b"x")
        (struct_live_dir / "testLiveStruct.1.png").write_bytes(b"x")
        (struct_dead_dir / "testStructGone.1.png").write_bytes(b"x")

        found = {str(ref.relative_to(root)): dead for ref, dead in find_orphans(root)}
        expected = {
            "T/__Snapshots__/LiveTests/testOldName.2.png": False,
            "T/__Snapshots__/LiveTests/testDynamicallyRenamed.1.png": False,
            "T/__Snapshots__/RenamedTests/testOldName.1.png": False,
            "T/__Snapshots__/DeletedTests/testGone.1.png": True,
            "T/__Snapshots__/StructDeletedTests/testStructGone.1.png": True,
        }
        ok = True
        for rel, dead in found.items():
            if expected.get(rel) is not dead:
                print(f"self-test: unexpected classification {rel} (whole_dir_dead={dead})")
                ok = False
        for rel in expected:
            if rel not in found:
                print(f"self-test: expected orphan {rel} not detected")
                ok = False
        print("self-test:", "passed" if ok else "FAILED")
        return 0 if ok else 2


def main() -> int:
    if "--self-test" in sys.argv:
        return self_test()

    root = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path.cwd()
    orphans = find_orphans(root)
    if not orphans:
        print("No orphaned snapshot references.")
        return 0

    print(f"Found {len(orphans)} orphaned snapshot reference(s):")
    for ref, whole_dir in orphans:
        if whole_dir:
            print(f"::error file={ref}::Orphaned snapshot — class '{ref.parent.name}' no longer exists")
        else:
            print(f"::error file={ref}::Orphaned snapshot — test method no longer declared in '{ref.parent.name}'")
    print(
        "\nOrphaned snapshot references FAILED the check.\n"
        "Delete the reference files (they re-record on next `--record`), or restore the tests."
    )
    return 1


if __name__ == "__main__":
    sys.exit(main())
