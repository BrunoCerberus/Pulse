#!/usr/bin/env python3
"""Check Localizable.strings *values* across languages — the complement to
check-localization-parity.py, which only compares key sets.

Key parity catches a dropped key (the raw key ships to users). It is blind to
three value-level defects:

  - an empty translation (the localized screen renders a blank string),
  - a format-placeholder mismatch (``%@`` vs ``%d``, or a different count) —
    ``String(format:)`` prints ``?`` or the wrong argument at runtime, with no
    build error and no crash, so this is silent user-facing corruption,
  - a value still identical to the English source (a "translation" that was
    never written). This is only a *warning*: brand names and words like
    "OK" are legitimately identical in every language, so failing on it would
    train people to ignore the check.

Classic ``.strings`` syntax only — Pulse does not use ``.xcstrings``.
Emits GitHub Actions ``::error::``/``::warning::`` annotations and exits 1
when any error-class defect is found.

Usage: ``check-localization-completeness.py [ROOT]`` (defaults to CWD).
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

BASE_LANG = "en"
SKIP_DIRS = {"DerivedData", ".build", "git"}
# `"key" = "value";` on one line, honoring backslash escapes in both halves.
ENTRY_RE = re.compile(r'^\s*"((?:[^"\\]|\\.)*)"\s*=\s*"((?:[^"\\]|\\.)*)"\s*;\s*(?://.*)?$')
# printf-style specifiers, including %@ (objects) and positional ones like %1$d.
SPEC_RE = re.compile(r"%\d*\$?([diouxXeEfFgGaAsDc@])")

ESCAPES = {"n": "\n", "t": "\t", "r": "\r", '"': '"', "\\": "\\"}


def read_strings(path: Path) -> str:
    """Read a .strings file as UTF-8, falling back to UTF-16 — same reason as
    the parity script: Apple tooling and some editors write .strings as
    UTF-16 LE with a BOM, which would otherwise raise UnicodeDecodeError."""
    try:
        return path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return path.read_text(encoding="utf-16")


def unescape(value: str) -> str:
    def repl(match: re.Match) -> str:
        char = match.group(1)
        return ESCAPES.get(char, "\\" + char)

    return re.sub(r"\\(.)", repl, value)


def parse_entries(path: Path) -> dict[str, str]:
    """Return {key: raw value} in order, comments and unparseable lines skipped.
    A key declared twice wins with its last value — duplicates are the parity
    script's job to fail on, not this one's to re-report."""
    entries: dict[str, str] = {}
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
        match = ENTRY_RE.match(line)
        if match:
            entries[match.group(1)] = match.group(2)
    return entries


def find_groups(root: Path) -> dict[Path, dict[str, Path]]:
    """Map each target directory → {language: strings_path}."""
    groups: dict[Path, dict[str, Path]] = {}
    for strings in root.rglob("*.lproj/Localizable.strings"):
        if SKIP_DIRS.intersection(strings.parts):
            continue
        lproj = strings.parent
        lang = lproj.name[: -len(".lproj")]
        groups.setdefault(lproj.parent, {})[lang] = strings
    return groups


def rel(path: Path, root: Path) -> str:
    try:
        return str(path.relative_to(root))
    except ValueError:
        return str(path)


def placeholders(value: str) -> list[str]:
    """Base specifier of each placeholder, positional prefixes stripped, so
    ``%1$d`` and ``%d`` compare equal (same argument slot, same type) while
    ``%@`` vs ``%s`` still differ. A *reordered* pair like ``%1$s %2$s`` vs
    ``%2$s %1$s`` reads differently but normalizes to the same multiset — the
    reordering only matters when the specifiers differ, which is caught."""
    specs = []
    for raw in SPEC_RE.finditer(unescape(value)):
        specs.append(raw.group(1))
    return sorted(specs)


def main() -> int:
    root = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path.cwd()
    groups = find_groups(root)
    if not groups:
        print("No *.lproj/Localizable.strings files found — nothing to check.")
        return 0

    failed = False
    for target in sorted(groups, key=str):
        langs = groups[target]
        print(f"\n== {rel(target, root)} ({', '.join(sorted(langs))}) ==")

        if BASE_LANG not in langs:
            print(f"::warning::No '{BASE_LANG}' base found in {rel(target, root)}; skipping.")
            continue

        per_lang = {lang: parse_entries(path) for lang, path in langs.items()}
        base = per_lang[BASE_LANG]

        for lang in sorted(langs):
            if lang == BASE_LANG:
                continue
            values = per_lang[lang]
            empty = sorted(k for k, v in values.items() if k in base and not v.strip())
            mismatched = sorted(
                k for k, v in values.items() if k in base and placeholders(v) != placeholders(base[k])
            )
            untranslated = sorted(k for k, v in values.items() if k in base and v == base[k] and v.strip())

            if empty:
                failed = True
                for k in empty:
                    print(f"::error file={rel(langs[lang], root)}::{lang} value for '{k}' is empty")
            if mismatched:
                failed = True
                for k in mismatched:
                    print(
                        f"::error file={rel(langs[lang], root)}::{lang} placeholders for '{k}' "
                        f"({placeholders(values[k])}) differ from {BASE_LANG} ({placeholders(base[k])})"
                    )
            if untranslated:
                sample = ", ".join(untranslated[:5])
                more = f" (+{len(untranslated) - 5} more)" if len(untranslated) > 5 else ""
                print(f"::warning file={rel(langs[lang], root)}::{lang} is identical to {BASE_LANG} for {len(untranslated)} key(s): {sample}{more}")
            print(
                f"  {lang}: {len(values)} keys — {len(empty)} empty, "
                f"{len(mismatched)} placeholder mismatch, {len(untranslated)} identical to {BASE_LANG}"
            )

    if failed:
        print("\nLocalization completeness check FAILED — see errors above.")
        return 1
    print("\nLocalization completeness check passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
