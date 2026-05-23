#!/usr/bin/env python3
"""Check Localizable.strings key parity across languages.

For each localized target (a directory holding one or more
``*.lproj/Localizable.strings`` files) the script compares every language's key
set against the base language (``en``). It fails — exit code 1 — when any
language is missing a key present in the base or carries an orphan key the base
doesn't have, and when a single file declares the same key twice.

Why this exists: a dropped key doesn't error at build time, it silently ships
the raw key string (e.g. ``common.ok``) to users in that language. Pulse leans
hard on ``AppLocalization.localized()`` across en/pt/es, so drift is easy to
introduce and invisible until someone switches language in the field.

Classic ``.strings`` syntax only (``"key" = "value";``) — Pulse does not use
``.xcstrings``. Emits GitHub Actions ``::error::`` annotations so failures show
up inline on the run, and a plain-text report for local use.

Usage: ``check-localization-parity.py [ROOT]`` (defaults to CWD).
"""
from __future__ import annotations

import re
import sys
from collections import Counter
from pathlib import Path

BASE_LANG = "en"
SKIP_DIRS = {"DerivedData", ".build", ".git"}
# Matches the key in `"some.key" = "value";`, honoring escaped quotes in the key.
KEY_RE = re.compile(r'^\s*"((?:[^"\\]|\\.)*)"\s*=')


def read_strings(path: Path) -> str:
    """Read a .strings file as UTF-8, falling back to UTF-16 — Apple tooling and
    some editors still write .strings as UTF-16 LE with a BOM, which would
    otherwise raise UnicodeDecodeError and turn CI red on a harmless re-save."""
    try:
        return path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return path.read_text(encoding="utf-16")


def parse_keys(path: Path) -> list[str]:
    """Return the keys declared in a .strings file, in order, comments stripped."""
    keys: list[str] = []
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
            keys.append(match.group(1))
    return keys


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

        per_lang = {lang: parse_keys(path) for lang, path in langs.items()}

        for lang, keys in per_lang.items():
            dups = sorted(k for k, n in Counter(keys).items() if n > 1)
            if dups:
                failed = True
                print(f"::error file={rel(langs[lang], root)}::Duplicate keys: {', '.join(dups)}")

        base_keys = set(per_lang[BASE_LANG])
        for lang in sorted(langs):
            if lang == BASE_LANG:
                continue
            current = set(per_lang[lang])
            missing = sorted(base_keys - current)
            orphan = sorted(current - base_keys)
            if missing:
                failed = True
                print(f"::error file={rel(langs[lang], root)}::{lang} is missing "
                      f"{len(missing)} key(s) present in {BASE_LANG}: {', '.join(missing)}")
            if orphan:
                failed = True
                print(f"::error file={rel(langs[lang], root)}::{lang} has "
                      f"{len(orphan)} orphan key(s) not in {BASE_LANG}: {', '.join(orphan)}")
            if not missing and not orphan:
                print(f"  {lang}: OK ({len(current)} keys)")

    if failed:
        print("\nLocalization parity check FAILED — see errors above.")
        return 1
    print("\nLocalization parity check passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
