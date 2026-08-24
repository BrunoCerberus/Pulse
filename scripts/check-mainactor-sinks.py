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

# Schedulers that deliver on the main thread. Both guard forms below must name
# one of these: `.receive(on: DispatchQueue.global())` hops to a *background*
# queue, so accepting a bare `.receive(on:)` would wave through exactly the
# off-main mutation this gate exists to catch. Every `.receive(on:)` in the tree
# today names `DispatchQueue.main`; the other two are accepted because they are
# equally main-thread, not because anything uses them yet.
MAIN_SCHEDULER = re.compile(r"(?:DispatchQueue\.main|RunLoop\.main|\.main)\Z")

# Operators that decide which queue everything *downstream* of them runs on:
# `.receive(on:)` and the `scheduler:` argument of `debounce`/`throttle`/`delay`
# /`timeout`. `.subscribe(on:)` is deliberately not here — it moves where the
# subscription work happens, not where values are delivered.
#
# The scheduler expression is captured so the caller can look at *which* queue
# was named, rather than merely that a hop exists.
SCHEDULER_HOP = re.compile(
    r"\.receive\s*\(\s*on:\s*(?P<a>[A-Za-z_.][A-Za-z0-9_.]*(?:\(\))?)"
    r"|scheduler:\s*(?P<b>[A-Za-z_.][A-Za-z0-9_.]*(?:\(\))?)"
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


def is_guarded(chain: str) -> bool:
    """Whether the sink at the end of `chain` is delivered on the main queue.

    Only the *last* scheduler-changing operator matters: each one re-schedules
    everything downstream of it, so an earlier `.receive(on: DispatchQueue.main)`
    is undone by a later `.debounce(scheduler: DispatchQueue.global())`. Asking
    merely whether a main scheduler appears somewhere in the chain would call
    that shape guarded while it delivers off-main — the crash this gate exists
    to catch. The reverse order is genuinely fine, and stays passing.

    An unrecognised scheduler expression (a variable, an injected scheduler)
    counts as unguarded: this errs toward a reviewable false positive rather
    than a silent false negative.
    """
    hops = [match.group("a") or match.group("b") for match in SCHEDULER_HOP.finditer(chain)]
    if not hops:
        return False
    return MAIN_SCHEDULER.search(hops[-1]) is not None


def chain_start(lines: list[str], sink_index: int) -> int:
    """Index of the first line of the publisher chain ending at `sink_index`.

    Walks backwards accumulating bracket depth. A line is the chain root when
    it does not itself continue a chain (does not start with `.`) and every
    bracket opened below it has been closed — that rules out mistaking a
    multi-line argument list's closing `)` for the start of the statement.

    The sink's own line can be the root: a whole chain written on one line
    (`service.fetch().sink { ... }.store(in: &bag)`) is already balanced and
    does not start with `.`, so the walk must be able to stop immediately.
    Forcing it a line higher would splice in the preceding statement, and if
    *that* statement happened to be a guarded sink, its `.receive(on:)` would
    vouch for a chain it has nothing to do with — masking a real violation.
    Two adjacent single-line subscriptions in one `setup()` is enough to hit
    it, so this is not a corner case.

    A multi-line chain is unaffected: its sink line starts with `.`, so the
    walk keeps climbing to the real root.
    """
    depth = 0
    for index in range(sink_index, -1, -1):
        text = strip_noise(lines[index])
        depth += text.count(")") + text.count("]") - text.count("(") - text.count("[")
        stripped = text.strip()
        if stripped and not stripped.startswith(".") and depth <= 0:
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
        if is_guarded(chain):
            continue

        relative = path.relative_to(repo_root)
        violations.append(
            f"{relative}:{index + 1}: `.sink` on a publisher chain with no "
            f"main-queue hop upstream (chain starts line {start + 1})"
        )
    return violations


# (label, source, expected violation count). Two real bugs in this file were
# caught in review rather than by the 22-file tree scan — a clean tree proves
# no false positives, never the absence of false negatives, which are the
# dangerous direction here. These pin the shapes that broke.
SELF_TEST_CASES = (
    (
        "multi-line chain with a main hop is clean",
        """@MainActor
final class AInteractor {
    func setup() {
        service.publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] v in self?.stateSubject.value.x = v }
            .store(in: &cancellables)
    }
}""",
        0,
    ),
    (
        "multi-line chain with no hop is flagged",
        """@MainActor
final class BInteractor {
    func setup() {
        service.publisher
            .map { $0 }
            .sink { [weak self] v in self?.stateSubject.value.x = v }
            .store(in: &cancellables)
    }
}""",
        1,
    ),
    (
        "a background scheduler is not a main hop",
        """@MainActor
final class CInteractor {
    func setup() {
        service.publisher
            .receive(on: DispatchQueue.global())
            .sink { [weak self] v in self?.stateSubject.value.x = v }
            .store(in: &cancellables)
    }
}""",
        1,
    ),
    (
        "debounce onto the main queue counts as a hop",
        """@MainActor
final class DInteractor {
    func setup() {
        subject
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] v in self?.stateSubject.value.x = v }
            .store(in: &cancellables)
    }
}""",
        0,
    ),
    (
        "a trivial sink is exempt",
        """@MainActor
final class EInteractor {
    func setup() {
        service.publisher.sink { _ in }.store(in: &cancellables)
    }
}""",
        0,
    ),
    (
        "a single-line sink does not borrow the previous line's hop",
        """@MainActor
final class FInteractor {
    func setup() {
        a.fetch().receive(on: DispatchQueue.main).sink { _ in }.store(in: &cancellables)
        b.fetch().sink { [weak self] v in self?.stateSubject.value.x = v }.store(in: &cancellables)
    }
}""",
        1,
    ),
    (
        "a self-contained single-line chain with a hop is clean",
        """@MainActor
final class GInteractor {
    func setup() {
        b.fetch().receive(on: DispatchQueue.main).sink { [weak self] v in self?.stateSubject.value.x = v }
    }
}""",
        0,
    ),
    (
        "a later background hop undoes an earlier main hop",
        """@MainActor
final class IInteractor {
    func setup() {
        service.publisher
            .receive(on: DispatchQueue.main)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.global())
            .sink { [weak self] v in self?.stateSubject.value.x = v }
            .store(in: &cancellables)
    }
}""",
        1,
    ),
    (
        "a later main hop rescues an earlier background hop",
        """@MainActor
final class JInteractor {
    func setup() {
        service.publisher
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] v in self?.stateSubject.value.x = v }
            .store(in: &cancellables)
    }
}""",
        0,
    ),
    (
        "an unrecognised scheduler expression is not assumed to be main",
        """@MainActor
final class KInteractor {
    func setup() {
        service.publisher
            .receive(on: injectedScheduler)
            .sink { [weak self] v in self?.stateSubject.value.x = v }
            .store(in: &cancellables)
    }
}""",
        1,
    ),
    (
        "a non-@MainActor type is out of scope",
        """final class HInteractor {
    func setup() {
        service.publisher.sink { [weak self] v in self?.stateSubject.value.x = v }
    }
}""",
        0,
    ),
)


def self_test() -> int:
    """Run the shape fixtures above through check_file and report mismatches."""
    import tempfile

    failures = 0
    with tempfile.TemporaryDirectory() as raw_root:
        root = Path(raw_root)
        for number, (label, source, expected) in enumerate(SELF_TEST_CASES):
            path = root / f"Case{number}Interactor.swift"
            path.write_text(source, encoding="utf-8")
            actual = len(check_file(path, root))
            status = "ok" if actual == expected else "FAILED"
            if actual != expected:
                failures += 1
            print(f"  [{status}] {label} (expected {expected}, got {actual})")
            path.unlink()

    if failures:
        print(f"\nSelf-test: {failures} of {len(SELF_TEST_CASES)} case(s) failed.")
        return 1
    print(f"\nSelf-test: all {len(SELF_TEST_CASES)} cases passed.")
    return 0


def main() -> int:
    if len(sys.argv) == 2 and sys.argv[1] == "--self-test":
        return self_test()

    if len(sys.argv) != 2:
        print("usage: check-mainactor-sinks.py <repo-root> | --self-test", file=sys.stderr)
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
