#!/usr/bin/env python3
"""Check that every localized string key referenced in code exists in its catalog.

Key parity (``check-localization-parity.py``) compares the catalogs *against
each other*; value completeness (``check-localization-completeness.py``) checks
the values *within* the catalogs. Both are blind to the third direction: a key
referenced in code that is missing from **every** catalog — a typo'd key, or a
new key that was never added to any ``.lproj`` — renders the raw key string
(e.g. ``common.foo``) at runtime with no build error, no parity failure, and no
value failure. This script closes that direction.

It scans every ``.swift`` file for the localization call shapes the repo uses —
``AppLocalization[.shared].localized("…")`` in either receiver case (views hold
``@ObservedObject var appLocalization`` and call it on the instance) and
``String(localized: "…")`` — and requires each *literal* key to exist in the
``en`` catalog of the bundle that resolves it at runtime:

  - ``Pulse`` / ``PulseTests`` / ``PulseUITests`` / ``PulseSnapshotTests``
    resolve against the app's main bundle → ``Pulse/en.lproj/Localizable.strings``
    (test targets host the app).
  - ``PulseWidgetExtension`` resolves against its **own** bundle (a widget's
    ``Bundle.main`` is the widget, not the app) → its own ``en`` catalog.
  - ``PulseShareExtension`` ships no ``Localizable.strings``; any literal key
    in it would render raw, so its use is an error.

Dynamic keys (``localized(key)`` with a variable) cannot be checked statically
and are ignored, as are interpolated literals (``"prefix.\\(x)"``).

Emits GitHub Actions ``::error::`` / ``::warning::`` annotations like the other
localization scripts. ``--self-test`` builds a synthetic tree (present/missing/
wrong-bundle keys) and asserts the detector classifies each correctly — a
clean repo only proves the absence of missing keys, not that a missing key
would be caught.

Usage: ``check-localization-usage.py [ROOT] | --self-test`` (defaults to CWD).
"""
from __future__ import annotations

import re
import sys
import tempfile
from pathlib import Path

BASE_LANG = "en"
SKIP_DIRS = {"DerivedData", ".build", ".git"}

# Which top-level target directory owns which runtime bundle (and thus which
# catalog a key must exist in). Test targets host or attach to the app, so
# they resolve against the app's main bundle.
TARGET_CATALOG: dict[str, str | None] = {
    "Pulse": "Pulse",
    "PulseTests": "Pulse",
    "PulseUITests": "Pulse",
    "PulseSnapshotTests": "Pulse",
    "PulseWidgetExtension": "PulseWidgetExtension",
    "PulseShareExtension": None,
}

# `AppLocalization.shared.localized("k")`, `AppLocalization.localized("k")`,
# `appLocalization.localized("k")` (the lowercase instance property views keep
# in `@ObservedObject var appLocalization = AppLocalization.shared`), and
# `String(localized: "k"...)`. Escapes inside the literal are kept so the
# captured text matches the catalog's KEY_RE representation. Other receivers
# (`instance.localized(key)` inside AppLocalization itself) are dynamic and
# uncheckable — the literal-argument requirement already excludes them.
CALL_RE = re.compile(
    r'[Aa]ppLocalization(?:\.shared)?\.localized\(\s*"'
    r'((?:[^"\\]|\\.)*)"'
    r'|String\(localized:\s*"((?:[^"\\]|\\.)*)"'
)

# Matches the key in `"some.key" = "value";`, honoring escaped quotes in the key.
KEY_RE = re.compile(r'^\s*"((?:[^"\\]|\\.)*)"\s*=')

# A Swift string interpolation (`\(x)`) inside the key literal: an unescaped
# backslash followed by `(`. A *literal* backslash in the key would be written
# `\\(` in source and captured as `\\(` — even run of backslashes — so only an
# odd run before `(` marks interpolation.
INTERPOLATION_RE = re.compile(r"(?<!\\)(?:\\\\)*\\\(")


def read_strings(path: Path) -> str:
    """Read a .strings file as UTF-8, falling back to UTF-16 (same reason as the
    parity script)."""
    try:
        return path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return path.read_text(encoding="utf-16")


def parse_keys(path: Path) -> set[str]:
    """Return the set of keys declared in a .strings file, comments stripped."""
    keys: set[str] = set()
    in_block_comment = False
    for raw in read_strings(path).splitlines():
        line = raw.strip()
        if in_block_comment:
            if "*/" in line:
                in_block_comment = False
                line = line.split("*/", 1)[1].strip()
            else:
                continue
        if not line or line.startswith("//"):
            continue
        if line.startswith("/*"):
            if "*/" not in line:
                in_block_comment = True
            continue
        match = KEY_RE.match(line)
        if match:
            keys.add(match.group(1))
    return keys


def rel(path: Path, root: Path) -> str:
    try:
        return str(path.relative_to(root))
    except ValueError:
        return str(path)


def strip_comments(source: str) -> str:
    """Replace comment and multi-line-string content with spaces, preserving
    single-line strings, layout, and line numbers. Doc-comment examples
    (``AppLocalization.localized("key")`` in a ``///`` block) are not call sites
    and must not count. ``//`` inside a string literal (a URL) is not a comment
    opener; single-line strings are kept intact because the key being checked
    *is* a string literal.

    Multi-line strings are the one string kind that gets blanked like a comment
    (newlines preserved): tokenizing their three quotes individually toggles the
    single-quote state an odd number of times (plus once per inner quote),
    leaving the scanner desynced past the literal — after which a real ``//``
    comment is treated as string content or vice versa. Blanking also keeps a
    call whose argument opens a multi-line string from matching as an empty
    single-line key, and a key spanning lines could never match the per-line
    scanner anyway."""
    out: list[str] = []
    i = 0
    size = len(source)
    in_string = in_line_comment = in_block_comment = in_multiline = False
    while i < size:
        ch = source[i]
        if in_multiline:
            if source[i : i + 3] == '"""':
                in_multiline = False
                out.append("   ")
                i += 3
            else:
                out.append(ch if ch == "\n" else " ")
                i += 1
        elif in_line_comment:
            out.append(ch if ch == "\n" else " ")
            if ch == "\n":
                in_line_comment = False
            i += 1
        elif in_block_comment:
            if ch == "*" and source[i : i + 2] == "*/":
                in_block_comment = False
                out.append("  ")
                i += 2
            else:
                out.append(ch if ch == "\n" else " ")
                i += 1
        elif in_string:
            if ch == "\\" and i + 1 < size:
                out.append(ch + source[i + 1])
                i += 2
            else:
                out.append(ch)
                if ch == '"':
                    in_string = False
                i += 1
        else:
            if source[i : i + 3] == '"""':
                in_multiline = True
                out.append("   ")
                i += 3
            elif ch == '"':
                in_string = True
                out.append(ch)
                i += 1
            elif source[i : i + 2] == "//":
                in_line_comment = True
                out.append("  ")
                i += 2
            elif source[i : i + 2] == "/*":
                in_block_comment = True
                out.append("  ")
                i += 2
            else:
                out.append(ch)
                i += 1
    return "".join(out)


def scan(root: Path) -> list[str]:
    """Return the list of error lines for the tree (empty = pass)."""
    catalogs: dict[str, set[str]] = {}
    for target, catalog_dir in TARGET_CATALOG.items():
        if catalog_dir is None:
            continue
        path = root / catalog_dir / f"{BASE_LANG}.lproj" / "Localizable.strings"
        if path.is_file():
            catalogs[target] = parse_keys(path)

    errors: list[str] = []
    for swift in sorted(root.rglob("*.swift")):
        # Relative to root: rglob yields absolute paths when root is absolute
        # (main() resolves its argument), so parts[0] would be the filesystem
        # root, not the target directory — and every file would be skipped.
        relpath = swift.relative_to(root)
        if SKIP_DIRS.intersection(relpath.parts):
            continue
        top = relpath.parts[0] if len(relpath.parts) > 1 else ""
        if top not in TARGET_CATALOG:
            continue
        try:
            source = swift.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue
        source = strip_comments(source)

        for line_no, line in enumerate(source.splitlines(), start=1):
            for match in CALL_RE.finditer(line):
                key = match.group(1) if match.group(1) is not None else match.group(2)
                if INTERPOLATION_RE.search(key):
                    continue
                catalog = TARGET_CATALOG[top]
                location = f"{rel(swift, root)}:{line_no}"
                if catalog is None:
                    errors.append(
                        f"::error file={location}::{top} ships no {BASE_LANG} "
                        f"Localizable.strings — `String(localized:)` renders the "
                        f"raw key {key!r} to users. Add a catalog or hard-code the string."
                    )
                elif key not in catalogs.get(catalog, set()):
                    errors.append(
                        f"::error file={location}::Key {key!r} is not in "
                        f"{catalog}/{BASE_LANG}.lproj/Localizable.strings — it would "
                        f"render as the raw key at runtime."
                    )
    return errors


def main() -> int:
    if len(sys.argv) == 2 and sys.argv[1] == "--self-test":
        return self_test()
    root = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path.cwd()

    if not any(t for t in TARGET_CATALOG if (root / t).is_dir()):
        print("No known target directories found — nothing to check.")
        return 0

    errors = scan(root)
    for error in errors:
        print(error)
    if errors:
        print(f"\nLocalization usage check FAILED — {len(errors)} missing key reference(s).")
        return 1
    print("Localization usage check passed — every referenced key exists in its catalog.")
    return 0


def self_test() -> int:
    failures: list[str] = []
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)

        def write(path: str, text: str) -> None:
            full = root / path
            full.parent.mkdir(parents=True, exist_ok=True)
            full.write_text(text, encoding="utf-8")

        write(
            "Pulse/en.lproj/Localizable.strings",
            '"known.key" = "Known";\n'
            '"common.ok" = "OK";\n'
            # Escaped backslash in the key: a literal `\(b`, not interpolation.
            '"a\\\\(b)" = "x";\n',
        )
        write(
            "PulseWidgetExtension/en.lproj/Localizable.strings",
            '"widget.title" = "News";\n',
        )

        # Passes: key present in the owning catalog, both call shapes.
        write(
            "Pulse/App.swift",
            '/// Doc example: `AppLocalization.shared.localized("doc.example.key")`\n'
            "/* Block example: String(localized: \"block.example.key\") */\n"
            'let a = AppLocalization.shared.localized("known.key") // https://example.com/x\n'
            'let b = AppLocalization.localized("common.ok")\n'
            'let c = String(localized: "known.key")\n'
            'let d = AppLocalization.shared.localized(variableKey)\n'
            # Interpolation — uncheckable, must be ignored.
            'let e = String(localized: "prefix.\\(suffix)")\n'
            # Escaped backslash — a real key present in the catalog, must pass.
            'let f = String(localized: "a\\\\(b)")\n',
        )
        write(
            "PulseTests/Host.swift",
            'let t = AppLocalization.localized("common.ok")\n',
        )
        # Views keep the localization in an `@ObservedObject var appLocalization`
        # and call `localized` on the lowercase instance — same type, must be
        # checked against the same catalog.
        write(
            "Pulse/InstanceCaller.swift",
            'let t = appLocalization.localized("common.ok")\n'
            'let u = appLocalization.shared.localized("known.key")\n',
        )
        # Fails: missing key via the lowercase instance receiver.
        write(
            "Pulse/InstanceBad.swift",
            'let v = appLocalization.localized("never.added.instance.key")\n',
        )

        # A `"""` multi-line string: the scanner must stay in sync across it.
        # The content holds a lone `"` (odd inner-quote parity — the shape that
        # desynced the old quote-by-quote toggling) plus `//` text that is
        # string content, not a comment. The call *after* the literal must be
        # checked; the example inside it must not.
        write(
            "Pulse/MultiLine.swift",
            'let template = """\n'
            'example: AppLocalization.localized("inside.multiline")\n'
            'a // not-a-comment and a " quote inside\n'
            '"""\n'
            'let real = AppLocalization.localized("never.added.after.multiline")\n'
            'let commented = AppLocalization.localized("commented.out.key") // real comment\n',
        )

        # The widget resolves against its own bundle, not the app's.
        write(
            "PulseWidgetExtension/Widget.swift",
            'let w = String(localized: "widget.title")\n',
        )

        # Fails: missing from every catalog.
        write(
            "Pulse/Bad.swift",
            'let x = AppLocalization.shared.localized("never.added.key")\n',
        )
        # Fails: present in the APP catalog but not the widget's own catalog.
        write(
            "PulseWidgetExtension/WrongBundle.swift",
            'let y = String(localized: "known.key")\n',
        )
        # Fails: the share extension has no catalog at all.
        write(
            "PulseShareExtension/Share.swift",
            'let z = String(localized: "anything.at.all")\n',
        )

        text = "\n".join(scan(root))

        def expect(condition: bool, label: str) -> None:
            if not condition:
                failures.append(label)

        # The pass file must be entirely absent from the report (which also
        # pins the dynamic-key and interpolation guards — a regression would
        # flag lines d/e in App.swift); the failing files must be present.
        expect("Pulse/App.swift" not in text, "passing call site flagged")
        expect("Pulse/Bad.swift" in text, "missing-from-all key not reported")
        expect("PulseWidgetExtension/WrongBundle.swift" in text, "wrong-bundle key not reported")
        expect("PulseShareExtension/Share.swift" in text, "no-catalog target not reported")
        expect("PulseTests/Host.swift" not in text, "test-host key (app catalog) flagged")
        expect("PulseWidgetExtension/Widget.swift" not in text, "own-bundle key flagged")
        expect("Pulse/InstanceCaller.swift" not in text, "lowercase instance receiver with valid keys flagged")
        expect("Pulse/InstanceBad.swift" in text, "missing key via lowercase instance receiver not reported")
        # The multi-line literal's content is blanked: its example key must not
        # be reported, but the call after the literal is real code and must be.
        expect("inside.multiline" not in text, "key inside multi-line literal flagged")
        expect("never.added.after.multiline" in text, "missing key after multi-line literal not reported")

    if failures:
        for failure in failures:
            print(f"self-test FAILED: {failure}", file=sys.stderr)
        return 1
    print("self-test passed (missing / wrong-bundle / no-catalog cases all detected).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
