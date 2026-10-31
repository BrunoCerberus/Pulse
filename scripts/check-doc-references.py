#!/usr/bin/env python3
"""Fail when a tracked Markdown doc names a file, directory or make target that no longer exists.

CLAUDE.md, AGENTS.md and the docs-guide are maintained by hand, and a rename
or deletion leaves their pointers dangling with no signal — the agent (or
human) reading them then goes looking for code that isn't there. This check
covers the mechanically verifiable part of doc drift:

  - inline code spans that look like a path (``Pulse/Configs/AI/``,
    ``scripts/check-mainactor-sinks.py``) must resolve — relative to the repo
    root, to the doc's own directory, or as a component-aligned suffix of a
    tracked path (docs routinely abbreviate ``Feed/API/``);
  - bare filenames with a source extension (``LiveAuthService.swift``) must
    match a tracked file's basename;
  - relative Markdown link targets must exist relative to the doc itself,
    as a renderer resolves them — no suffix fallback, and a link climbing
    out of the repo is broken;
  - ``make <target>`` (inline or in fenced blocks) must be a Makefile target.

Brace groups expand (``scripts/{a,b}.py``, ``bump-{patch,minor}``). Spans
holding placeholders (``<Target>``, ``*``, ``...``) are skipped: they describe
a shape, not a path. ``make`` is only read from code (inline spans and fenced
blocks), never prose. A deliberate reference to something outside the repo
goes in ``EXTERNAL_REFS`` with its reason — an allowlist keyed by reference
rather than a per-line marker, because AGENTS.md rules are single-line
paragraphs and a marker would blind the whole rule.

Only git-tracked files count on both sides, so an untracked local file can't
mask a broken reference and scratch Markdown isn't scanned.

``--self-test`` builds a synthetic tree and asserts each reference kind is
classified correctly — a clean repo proves no false positives, the self-test
proves the check still has teeth.

Usage: ``check-doc-references.py [ROOT]`` (defaults to CWD).
Exit codes: 0 = all references resolve, 1 = broken references, 2 = self-test failure.
"""
from __future__ import annotations

import re
import subprocess
import sys
import tempfile
from pathlib import Path, PurePosixPath

SOURCE_EXTS = {
    ".swift", ".py", ".sh", ".yml", ".yaml", ".md", ".json", ".plist",
    ".strings", ".xcprivacy", ".entitlements", ".xcconfig", ".go", ".sql",
}
EXTERNAL_REFS = {
    "Package.swift",  # the vendored swift-llama-cpp package's manifest, not ours
    "security-findings.json",  # emitted at runtime by claude-security-review.yml
    "Pulse/GoogleService-Info.plist",  # gitignored secret, injected in CI
}
PLACEHOLDER_RE = re.compile(r"[<>*$]|\.\.\.|…|://|^~|^/")
PATH_RE = re.compile(r"^[\w.+@-]+(?:/[\w.+@{},-]+)*/?$")
BRACE_RE = re.compile(r"\{([^{}]*)\}")
INLINE_CODE_RE = re.compile(r"(?<!`)`([^`\n]+)`(?!`)")
LINK_RE = re.compile(r"\]\(([^)\s#]+)(?:#[^)]*)?\)")
MAKE_RE = re.compile(r"(?:^|&&|\|\||;)\s*make\s+([a-z][\w{},-]*)")
MAKE_TARGET_RE = re.compile(r"^([a-zA-Z][\w-]*)\s*:(?!=)", re.MULTILINE)
SCRIPT = "scripts/check-doc-references.py"
FENCE_RE = re.compile(r"^\s*(`{3,}|~{3,})(.*)$")


def expand_braces(token: str) -> list[str]:
    match = BRACE_RE.search(token)
    if not match:
        return [token]
    head, tail = token[: match.start()], token[match.end():]
    return [
        expanded
        for option in match.group(1).split(",")
        for expanded in expand_braces(head + option + tail)
    ]


class Repo:
    def __init__(self, root: Path, files: list[str], external_refs: set[str]):
        self.root = root
        self.external_refs = external_refs
        self.external_used: set[str] = set()
        dirs = {str(p) for f in files for p in PurePosixPath(f).parents if str(p) != "."}
        self.paths = set(files) | dirs
        # Every component-aligned suffix of every tracked path, so an
        # abbreviated reference (`Feed/API/`, a bare filename) is one lookup.
        self.suffixes = {
            "/".join(parts[i:])
            for path in self.paths
            for parts in [path.split("/")]
            for i in range(len(parts))
        }
        makefile = root / "Makefile"
        self.make_targets = (
            set(MAKE_TARGET_RE.findall(makefile.read_text())) if makefile.is_file() else set()
        )

    def resolves(self, ref: str, doc: PurePosixPath) -> bool:
        ref = ref.rstrip("/")
        if ref.startswith("./"):
            ref = ref[2:]
        if not ref:
            return True
        return ref in self.suffixes or self.resolves_link(ref, doc)

    def resolves_link(self, link: str, doc: PurePosixPath) -> bool:
        """Strict: only relative to the doc's directory, as a renderer resolves
        it. A link that climbs out of the repo is broken, not clamped to root."""
        relative = _normalize((doc.parent / link.rstrip("/")).parts)
        return relative is not None and relative in self.paths


def _normalize(parts: tuple[str, ...]) -> str | None:
    out: list[str] = []
    for part in parts:
        if part == "..":
            if not out:
                return None
            out.pop()
        elif part != ".":
            out.append(part)
    return "/".join(out) or "."


def looks_like_path(span: str) -> bool:
    if PLACEHOLDER_RE.search(span) or not PATH_RE.match(span):
        return False
    if "/" in span:
        # A single "a/b" with no extension is as likely an `owner/repo`, a
        # `key/value` or a MIME type as a path, so require a second separator,
        # a trailing slash, or a source extension.
        return (
            span.count("/") >= 2
            or span.endswith("/")
            or PurePosixPath(span).suffix in SOURCE_EXTS
            or "{" in span
        )
    return PurePosixPath(span).suffix in SOURCE_EXTS


def check_doc(repo: Repo, doc: str) -> list[tuple[int, str, str]]:
    """Return [(line_no, kind, reference), ...] for every broken reference."""
    broken = []
    doc_path = PurePosixPath(doc)
    fence: str | None = None
    fence_line = 0
    for line_no, line in enumerate((repo.root / doc).read_text().splitlines(), 1):
        match = FENCE_RE.match(line)
        if match:
            marker, rest = match.groups()
            if fence is None:
                fence, fence_line = marker, line_no
                continue
            # CommonMark: only a bare run of the opening char, at least as
            # long, closes the block; anything else is content inside it.
            if marker[0] == fence[0] and len(marker) >= len(fence) and not rest.strip():
                fence = None
                continue
        in_fence = fence is not None
        code = [line] if in_fence else [s.strip() for s in INLINE_CODE_RE.findall(line)]
        for snippet in code:
            for target in MAKE_RE.findall(snippet):
                for name in expand_braces(target):
                    if name not in repo.make_targets:
                        broken.append((line_no, "make target", f"make {name}"))
        if in_fence:
            continue
        for span in code:
            if not looks_like_path(span):
                continue
            for ref in expand_braces(span):
                if ref in repo.external_refs:
                    repo.external_used.add(ref)
                elif not repo.resolves(ref, doc_path):
                    broken.append((line_no, "path", ref))
        for link in LINK_RE.findall(line):
            if PLACEHOLDER_RE.search(link) or ":" in link:
                continue
            if not repo.resolves_link(link, doc_path):
                broken.append((line_no, "link", link))
    if fence is not None:
        # Everything after an unclosed fence is read as code, which silently
        # turns the path and link checks off for the rest of the doc.
        broken.append((fence_line, "fence", f"unterminated {fence} code fence"))
    return broken


def tracked_files(root: Path) -> list[str]:
    # -z: without it git C-quotes non-ASCII paths, which then never match.
    out = subprocess.run(
        ["git", "-C", str(root), "ls-files", "-z"], capture_output=True, text=True, check=True
    ).stdout
    return [f for f in out.split("\0") if f and (root / f).exists()]


def find_broken(
    root: Path, files: list[str], external_refs: set[str] = EXTERNAL_REFS
) -> list[tuple[str, int, str, str]]:
    repo = Repo(root, files, external_refs)
    broken = [
        (doc, line_no, kind, ref)
        for doc in sorted(f for f in files if f.endswith(".md"))
        for line_no, kind, ref in check_doc(repo, doc)
    ]
    # Keep the allowlist minimal: an entry no doc cites any more, or one that
    # now exists in the tree, would silently exempt that string everywhere.
    for ref in sorted(external_refs):
        if ref not in repo.external_used:
            broken.append((SCRIPT, 0, "allowlist", f"{ref} (no doc references it)"))
        elif ref in repo.paths:
            broken.append((SCRIPT, 0, "allowlist", f"{ref} (now exists in the tree)"))
    return broken


def self_test() -> int:
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        files = {
            "Makefile": "build:\n\techo\nbump-patch:\n\techo\nvar := x\n",
            "Pulse/Feed/API/LiveFeedService.swift": "",
            "scripts/check-a.py": "",
            "scripts/check-b.py": "",
            "docs-guide/testing.md": "",
            "docs-guide/ci.md": (
                "Live: `Pulse/Feed/API/LiveFeedService.swift`, `Feed/API/`, "
                "`LiveFeedService.swift`, `scripts/{check-a,check-b}.py`, "
                "[testing](testing.md), [up](../Makefile), `make build`, "
                "`make bump-{patch}`.\n"
                "Skipped: `<Target>/__Snapshots__/x.png`, `actions/checkout`, "
                "`foo.bar()`, [web](https://example.com), `Pulse/*.swift`.\n"
                "Prose is not a command: make the docs match. External: `Package.swift`.\n"
                "```bash\n"
                "make build\n"
                "make missing-in-fence\n"
                "`InFence.swift` is not checked inside fences\n"
                "```\n"
                "````md\n"
                "```\n"
                "make nested-in-fence\n"
                "~~~\n"
                "````\n"
                "After the nested fence, prose again: make sure `make build && make chained`.\n"
                "Broken: `Pulse/Feed/API/DeadService.swift`, `DeadView.swift`, "
                "`scripts/{check-a,check-gone}.py`, `Feed/Gone/`, "
                "[dead](missing.md), [moved](Makefile), [escape](../../Makefile), "
                "`make nope`, `make bump-{patch,major}`, "
                "`make var`.\n"
            ),
            "docs-guide/unclosed.md": "Fine: `scripts/check-a.py`.\n```\ncode\n`Dead.swift` after the leak\n",
        }
        for rel, content in files.items():
            (root / rel).parent.mkdir(parents=True, exist_ok=True)
            (root / rel).write_text(content)

        found = {(kind, ref) for _, _, kind, ref in find_broken(
            root, list(files), {"Package.swift", "unused.json", "scripts/check-b.py"}
        )}
        expected = {
            ("make target", "make missing-in-fence"),
            ("make target", "make nested-in-fence"),
            ("make target", "make chained"),
            ("link", "Makefile"),
            ("link", "../../Makefile"),
            ("path", "Pulse/Feed/API/DeadService.swift"),
            ("path", "DeadView.swift"),
            ("path", "scripts/check-gone.py"),
            ("path", "Feed/Gone/"),
            ("link", "missing.md"),
            ("make target", "make nope"),
            ("make target", "make bump-major"),
            ("make target", "make var"),
            ("fence", "unterminated ``` code fence"),
            ("allowlist", "unused.json (no doc references it)"),
            ("allowlist", "scripts/check-b.py (now exists in the tree)"),
        }
        ok = found == expected
        for item in sorted(found - expected):
            print(f"self-test: false positive {item}")
        for item in sorted(expected - found):
            print(f"self-test: missed broken reference {item}")
        print("self-test:", "passed" if ok else "FAILED")
        return 0 if ok else 2


def main() -> int:
    if "--self-test" in sys.argv:
        return self_test()

    root = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path.cwd()
    broken = find_broken(root, tracked_files(root))
    if not broken:
        print("All doc references resolve.")
        return 0

    print(f"Found {len(broken)} broken doc reference(s):")
    for doc, line_no, kind, ref in broken:
        print(f"::error file={doc},line={line_no}::Broken {kind} reference: {ref}")
    print(
        "\nDoc references FAILED the check.\n"
        "Update the doc to the new name/location, or drop the stale reference. A\n"
        "deliberate reference to something outside the repo goes in EXTERNAL_REFS."
    )
    return 1


if __name__ == "__main__":
    sys.exit(main())
