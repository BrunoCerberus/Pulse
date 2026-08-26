#!/usr/bin/env python3
"""Diff two Package.resolved lockfiles and render a markdown change table.

The SPM dependency-review job in ci.yml runs this on every PR that touches
the committed lockfile. It is advisory by design — dependency bumps in this
repo are Dependabot-driven and auto-merge (patch/minor), so a failing gate
would fight the automation; the table is posted as a sticky PR comment so a
human can scan what actually moved and by how much.

Committed lockfiles are v3 JSON: a top-level `pins` array where each entry
carries `identity`, `location`, and `state` (`version` for tagged releases,
`revision` for branch/revision pins — `revision` alone means the pin is not
tagged and its version cannot be known without fetching).

Usage: diff-package-resolved.py <base-lock> <head-lock> [output.md]
Exit codes: 0 = rendered (or no changes), 2 = the *head* lockfile is
unreadable. An absent *base* lockfile (the PR adds it for the first time) is a
warning, not a failure — the advisory job must not redden on a first lockfile.

Writes `has_changes=true|false` to the file named by the GITHUB_OUTPUT
environment variable when set, so the calling step can gate a PR comment.
"""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path


def load_pins(path: Path) -> dict[str, dict] | None:
    """Return {identity: pin} or None when the file is absent/unparsable."""
    try:
        data = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError):
        return None
    pins = data.get("pins")
    if not isinstance(pins, list):
        return None
    return {pin["identity"]: pin for pin in pins if isinstance(pin, dict) and "identity" in pin}


def version_of(pin: dict) -> str:
    state = pin.get("state", {})
    version = state.get("version")
    if version:
        return version
    revision = state.get("revision")
    if revision:
        return f"{revision[:12]} (revision pin)"
    return state.get("branch") or "?"


def short_location(location: str | None) -> str:
    """https://github.com/firebase/firebase-ios-sdk.git -> firebase/firebase-ios-sdk.

    Pins without a resolvable location (fileSystem references, some v1 shapes)
    render as ``?`` rather than raising a KeyError that would redden the job."""
    if not location:
        return "?"
    trimmed = location.rstrip("/")
    if trimmed.endswith(".git"):
        trimmed = trimmed[: -4]
    if "://" in trimmed:
        trimmed = trimmed.split("://", 1)[1]
    parts = trimmed.split("/")
    return "/".join(parts[-2:]) if len(parts) >= 2 else trimmed


def main() -> int:
    if len(sys.argv) < 3:
        print("usage: diff-package-resolved.py <base-lock> <head-lock> [output.md]", file=sys.stderr)
        return 2

    base_path, head_path = Path(sys.argv[1]), Path(sys.argv[2])
    output = Path(sys.argv[3]) if len(sys.argv) > 3 else None

    head = load_pins(head_path)
    if head is None:
        print(f"::error file={head_path}::Could not read Package.resolved")
        return 2
    base = load_pins(base_path)
    if base is None:
        # No base lockfile — e.g. this PR adds Package.resolved for the first
        # time, so the base-branch fetch 404s. This is an advisory job, so list
        # every dependency as an addition rather than failing red.
        print(f"::warning file={base_path}::No base Package.resolved — listing all dependencies as new")
        base = {}

    lines = ["## SPM dependency changes", ""]
    changes: list[tuple[str, str, str, str]] = []
    for identity in sorted(set(base) | set(head)):
        base_v = version_of(base[identity]) if identity in base else None
        head_v = version_of(head[identity]) if identity in head else None
        source_pin = head.get(identity) or base.get(identity)
        # `.get` not `["location"]`: fileSystem and some v1 pins carry no
        # location, and an unguarded subscript would raise and redden the job.
        repo = short_location(source_pin.get("location") if source_pin else None)
        if base_v is None:
            changes.append((identity, "+", repo, f"— → {head_v}"))
        elif head_v is None:
            changes.append((identity, "−", repo, f"{base_v} → —"))
        elif base_v != head_v:
            changes.append((identity, "~", repo, f"{base_v} → {head_v}"))

    if not changes:
        lines.append("No dependency version changes in this PR.")
    else:
        lines.append("| Package | Repo | Change |")
        lines.append("|---------|------|--------|")
        for identity, marker, repo, change in changes:
            lines.append(f"| `{identity}` {marker} | {repo} | {change} |")
        lines.append("")
        lines.append(
            "_Advisory: patch/minor bumps auto-merge via Dependabot. Review majors "
            "and revision pins (untagged, branch-pinned) before merging._"
        )

    markdown = "\n".join(lines) + "\n"
    if output:
        output.write_text(markdown)
    print(markdown)

    github_output = os.environ.get("GITHUB_OUTPUT")
    if github_output:
        with open(github_output, "a") as fh:
            fh.write(f"has_changes={'true' if changes else 'false'}\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
