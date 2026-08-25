#!/usr/bin/env python3
"""Fail when a canonical screen has no accessibility audit.

Pulse's UI-test suite includes ``AccessibilityAuditTests`` (one
``performAccessibilityAudit`` per main screen — see AGENTS.md Testing rules).
Until now that list was maintained by memory: screens added later simply
went unaudited. This check makes the audit suite a *mirror* of the
canonical screen list:

  - every case of ``AppTab`` (Coordinator.swift) and ``Page`` (Page.swift)
    is a reachable main screen and must be covered by an audit method whose
    name contains the case name's camelCase words (so ``readingHistory`` is
    covered by ``testReadingHistory`` or ``testReadingHistoryWithContent``);
  - a case whose doc comment carries ``a11y-audit:exclude`` is skipped — the
    escape valve for genuinely transient pages (confirmations, alerts).

This runs in the Code Quality job (seconds, no simulator) so a new screen
ships in the same PR as an audit, or an explicit exclusion with a reason.

Usage: ``check-a11y-audit-coverage.py [ROOT]`` (defaults to CWD).
Exit codes: 0 = all covered, 1 = uncovered screens, 2 = source files missing.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

SKIP_DIRS = {"DerivedData", ".build", "git", ".claude"}

APP_TAB_FILE = "Pulse/Configs/Navigation/Coordinator.swift"
PAGE_FILE = "Pulse/Configs/Navigation/Page.swift"
AUDIT_FILE = "PulseUITests/AccessibilityAuditTests.swift"

EXCLUDE_MARKER = "a11y-audit:exclude"
CAMEL_RE = re.compile(r"[A-Z]?[a-z0-9]+|[A-Z]+(?![a-z])")


def find_file(root: Path, rel: str) -> Path | None:
    """Allow the file to sit at the repo root or in a shallow subdirectory —
    the two navigation files have moved before; refuse to guess deeper."""
    direct = root / rel
    if direct.is_file():
        return direct
    tail = Path(rel).name
    matches = [p for p in root.rglob(tail) if p.is_file() and not SKIP_DIRS.intersection(p.parts)]
    return matches[0] if len(matches) == 1 else None


def camel_words(name: str) -> list[str]:
    return [w.lower() for w in CAMEL_RE.findall(name)]


def enum_cases(root: Path, rel: str, enum_name: str) -> list[str] | None:
    """Direct cases of an enum, tracking brace depth from its declaration so
    multi-line declarations and nested bodies (switches, computed props) are
    handled. ``None`` = the enum itself was not found."""
    path = find_file(root, rel)
    if path is None:
        return None
    lines = path.read_text().splitlines()
    depth = 0
    in_body = False
    in_comment = False
    last_comment = ""
    cases: list[str] = []
    for line in lines:
        stripped = line.strip()
        if in_comment:
            if "*/" in stripped:
                in_comment = False
            if not in_body:
                continue
            last_comment = (last_comment + " " + stripped).strip()
            continue
        if stripped.startswith("/*"):
            in_comment = "*/" not in stripped
            if not in_body:
                continue
            last_comment = stripped
            continue
        if stripped.startswith("///"):
            if in_body:
                last_comment = stripped.lstrip("/ ").strip()
            continue
        if not stripped:
            continue
        if not in_body:
            if re.search(rf"\benum\s+{enum_name}\b", stripped):
                depth += stripped.count("{") - stripped.count("}")
                in_body = depth > 0
            continue
        depth += stripped.count("{") - stripped.count("}")
        if depth <= 0:
            break
        case = re.match(r"case\s+(\w+)", stripped)
        if case:
            if EXCLUDE_MARKER in last_comment:
                last_comment = ""
                continue
            cases.append(case.group(1))
            last_comment = ""
    return cases if in_body else None


def audit_methods(root: Path) -> list[str] | None:
    path = find_file(root, AUDIT_FILE)
    if path is None:
        return None
    return re.findall(r"\bfunc\s+(test\w+)\s*\(", path.read_text())


def is_covered(screen: str, methods: list[str]) -> bool:
    words = camel_words(screen)
    return any(all(w in camel_words(m) for w in words) for m in methods)


def main() -> int:
    root = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path.cwd()

    problems = 0
    tabs = enum_cases(root, APP_TAB_FILE, "AppTab")
    if tabs is None:
        print(f"::error file={APP_TAB_FILE}::Could not parse `enum AppTab` — check path or shape")
        problems += 1
    pages = enum_cases(root, PAGE_FILE, "Page")
    if pages is None:
        print(f"::error file={PAGE_FILE}::Could not parse `enum Page` — check path or shape")
        problems += 1
    methods = audit_methods(root)
    if methods is None:
        print(f"::error file={AUDIT_FILE}::AccessibilityAuditTests.swift not found")
        problems += 1
    if problems:
        return 2

    screens = [("AppTab", tabs or []), ("Page", pages or [])]
    total = sum(len(cases) for _name, cases in screens)
    covered_count = 0
    for source, cases in screens:
        print(f"\n== {source} ({len(cases)} cases) ==")
        for case in cases:
            if is_covered(case, methods):
                covered_count += 1
                print(f"  {case}: covered")
            else:
                print(f"::error file={AUDIT_FILE}::{source}.{case} has no accessibility audit — "
                      f"add a test case to AccessibilityAuditTests, or mark the case "
                      f"'{EXCLUDE_MARKER}' if it is a transient screen")

    print(f"\n{covered_count}/{total} canonical screens have accessibility audits.")
    if covered_count < total:
        print("Accessibility audit coverage FAILED — every AppTab and Page case must be audited.")
        return 1
    print("Accessibility audit coverage passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
