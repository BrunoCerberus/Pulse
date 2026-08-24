#!/usr/bin/env python3
"""Gate AGENTS.md rule 19: main-thread Combine sinks in @MainActor interactors.

Every `.sink` in a `@MainActor` interactor that mutates `stateSubject.value`
must be preceded by `.receive(on: DispatchQueue.main)` — services deliver off
the main queue, and mutating the subject from a background queue crashes the
app with `_dispatch_assert_queue_fail`. That crash reproduces only at runtime,
on a timing-dependent path, so it is exactly the kind of bug CI should catch.

This is a script rather than a SwiftLint `custom_rules` entry because the check
is inherently multi-line: it has to walk backwards from a `.sink` through an
arbitrarily long publisher chain to find out whether `.receive(on:)` appears
upstream. NSRegularExpression has no variable-length lookbehind, so a regex
rule can only approximate it — and an approximate rule on a crash-class
convention is worse than none.

Trivial sinks (`.sink { _ in }`, `.sink { }`) are exempt: they discard the
value and touch no state, so the queue they run on does not matter.

Usage: check-mainactor-sinks.py <repo-root>
Exit codes: 0 = clean, 1 = violations found, 2 = bad invocation.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

# Directories holding first-party source. Test targets are out of scope: they
# drive interactors from the main queue by construction.
SOURCE_DIRS = ("Pulse", "PulseWidgetExtension", "PulseShareExtension")

# Only files that look like interactors — the layer that owns `stateSubject`.
INTERACTOR_GLOB = "*Interactor*.swift"

# `.receive(on:)` is the canonical guard, but any operator that hops onto the
# main queue via its `scheduler:` argument (`debounce`, `throttle`, `delay`)
# delivers downstream on main just as effectively.
GUARDED = re.compile(
    r"\.receive\s*\(\s*on:|scheduler:\s*(DispatchQueue\.main|\.main)\b"
)
MAIN_ACTOR = re.compile(r"@MainActor")

# `.sink { _ in }`, `.sink { }`, `.sink(receiveValue: { _ in })` and friends —
# a closure whose body is empty or discards its argument.
TRIVIAL_SINK = re.compile(r"\.sink\s*(\(\s*receiveValue:\s*)?\{\s*(_\s+in)?\s*\}")


def strip_noise(line: str) -> str:
    """Remove line comments and string-literal contents.

    Both can hold unbalanced parens/braces that would corrupt the depth
    tracking used to find where a publisher chain starts.
    """
    out = []
    in_string = False
    i = 0
    while i < len(line):
        char = line[i]
        if in_string:
            if char == "\\":
                i += 2
                continue
            if char == '"':
                in_string = False
            i += 1
            continue
        if char == '"':
            in_string = True
            i += 1
            continue
        if char == "/" and i + 1 < len(line) and line[i + 1] == "/":
            break
        out.append(char)
        i += 1
    return "".join(out)


def chain_start(lines: list[str], sink_index: int) -> int:
    """Index of the first line of the publisher chain ending at `sink_index`.

    Walks backwards accumulating bracket depth. A line is the chain root when
    it does not itself continue a chain (does not start with `.`) and every
    bracket opened below it has been closed — that rules out mistaking a
    multi-line argument list's closing `)` for the start of the statement.
    """
    depth = 0
    for index in range(sink_index, -1, -1):
        text = strip_noise(lines[index])
        depth += text.count(")") + text.count("]") - text.count("(") - text.count("[")
        stripped = text.strip()
        if index < sink_index and not stripped.startswith(".") and depth <= 0 and stripped:
            return index
    return 0


def check_file(path: Path, repo_root: Path) -> list[str]:
    lines = path.read_text(encoding="utf-8").splitlines()
    if not any(MAIN_ACTOR.search(line) for line in lines):
        return []

    violations = []
    for index, line in enumerate(lines):
        clean = strip_noise(line)
        if ".sink" not in clean:
            continue
        # A trivial sink discards the value; the delivery queue is irrelevant.
        # Look at the sink line plus the next one so a `{ _ in }` split across
        # lines still reads as trivial.
        window = clean + " " + (strip_noise(lines[index + 1]) if index + 1 < len(lines) else "")
        if TRIVIAL_SINK.search(window):
            continue

        start = chain_start(lines, index)
        chain = " ".join(strip_noise(entry) for entry in lines[start : index + 1])
        if GUARDED.search(chain):
            continue

        relative = path.relative_to(repo_root)
        violations.append(
            f"{relative}:{index + 1}: `.sink` on a publisher chain with no "
            f"main-queue hop upstream (chain starts line {start + 1})"
        )
    return violations


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: check-mainactor-sinks.py <repo-root>", file=sys.stderr)
        return 2

    repo_root = Path(sys.argv[1]).resolve()
    if not repo_root.is_dir():
        print(f"error: {repo_root} is not a directory", file=sys.stderr)
        return 2

    violations: list[str] = []
    checked = 0
    for source_dir in SOURCE_DIRS:
        base = repo_root / source_dir
        if not base.is_dir():
            continue
        for path in sorted(base.rglob(INTERACTOR_GLOB)):
            checked += 1
            violations.extend(check_file(path, repo_root))

    if violations:
        print(f"Found {len(violations)} unguarded sink(s) in {checked} interactor file(s):\n")
        for violation in violations:
            print(f"  {violation}")
        print(
            "\nAGENTS.md rule 19: a `.sink` in a @MainActor interactor that mutates\n"
            "`stateSubject.value` must be preceded by `.receive(on: DispatchQueue.main)`,\n"
            "or it crashes with `_dispatch_assert_queue_fail` when the service delivers\n"
            "off the main queue.\n\n"
            "If the sink genuinely touches no state, make that explicit by writing it as\n"
            "`.sink { _ in }` — the check exempts trivial sinks."
        )
        return 1

    print(f"Main-thread sink check passed ({checked} interactor files).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
