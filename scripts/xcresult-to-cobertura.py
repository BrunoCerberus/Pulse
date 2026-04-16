#!/usr/bin/env python3
"""Convert an Xcode 26 xcresult bundle to Cobertura XML.

Uses xcresulttool + xccov directly, because xcresultparser 2.0.1 is incompatible
with the fileBacked2 storage format and coverage JSON schema that Xcode 26
produces (it calls `xccov view --report --json <xcresult>`, which now fails with
"unrecognized file format", and its Codable models expect `coveredLines` as an
array where Xcode 26 emits a scalar count).
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path
from xml.etree import ElementTree as ET


def run(cmd: list[str]) -> str:
    return subprocess.run(cmd, capture_output=True, text=True, check=True).stdout


def export_coverage(xcresult: Path, output_dir: Path) -> tuple[Path, Path]:
    run([
        "xcrun", "xcresulttool", "export", "coverage",
        "--path", str(xcresult),
        "--output-path", str(output_dir),
    ])
    report: Path | None = None
    archive: Path | None = None
    for entry in output_dir.iterdir():
        if entry.is_file() and entry.name.endswith("CoverageReport"):
            report = entry
        elif entry.is_dir() and entry.name.endswith("CoverageArchive"):
            archive = entry
    if report is None or archive is None:
        sys.exit(f"expected CoverageReport and CoverageArchive in {output_dir}")
    # xccov refuses to read the exported files without the expected extensions.
    renamed_report = report.with_suffix(".xccovreport")
    renamed_archive = archive.with_suffix(".xccovarchive")
    report.rename(renamed_report)
    archive.rename(renamed_archive)
    return renamed_report, renamed_archive


def build_cobertura(
    report: Path,
    archive: Path,
    project_root: str,
    excluded_dirs: tuple[str, ...],
) -> ET.Element:
    report_json = json.loads(run(["xcrun", "xccov", "view", "--json", str(report)]))
    archive_json = json.loads(run(["xcrun", "xccov", "view", "--json", str(archive)]))

    root_abs = os.path.abspath(project_root).rstrip("/") + "/"

    def in_project(path: str) -> bool:
        if not path.startswith(root_abs):
            return False
        return not any(excluded in path for excluded in excluded_dirs)

    coverage = ET.Element("coverage", {
        "line-rate": f"{report_json.get('lineCoverage', 0.0):.6f}",
        "lines-covered": str(report_json.get("coveredLines", 0)),
        "lines-valid": str(report_json.get("executableLines", 0)),
        "branch-rate": "0",
        "branches-covered": "0",
        "branches-valid": "0",
        "complexity": "0",
        "version": "1.0",
        "timestamp": "0",
    })
    sources = ET.SubElement(coverage, "sources")
    ET.SubElement(sources, "source").text = root_abs.rstrip("/")
    packages = ET.SubElement(coverage, "packages")

    for target in report_json.get("targets", []):
        kept_files = [f for f in target.get("files", []) if in_project(f.get("path", ""))]
        if not kept_files:
            continue

        covered = sum(f["coveredLines"] for f in kept_files)
        executable = sum(f["executableLines"] for f in kept_files)
        pkg_rate = covered / executable if executable else 0.0
        package = ET.SubElement(packages, "package", {
            "name": target["name"],
            "line-rate": f"{pkg_rate:.6f}",
            "branch-rate": "0",
            "complexity": "0",
        })
        classes_el = ET.SubElement(package, "classes")

        for f in kept_files:
            path = f["path"]
            rel_path = os.path.relpath(path, root_abs.rstrip("/"))
            class_el = ET.SubElement(classes_el, "class", {
                "name": os.path.splitext(f["name"])[0],
                "filename": rel_path,
                "line-rate": f"{f.get('lineCoverage', 0.0):.6f}",
                "branch-rate": "0",
                "complexity": "0",
            })
            ET.SubElement(class_el, "methods")
            lines_el = ET.SubElement(class_el, "lines")
            for entry in archive_json.get(path, []):
                if not entry.get("isExecutable"):
                    continue
                ET.SubElement(lines_el, "line", {
                    "number": str(entry["line"]),
                    "hits": str(entry.get("executionCount", 0)),
                })

    return coverage


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("xcresult", help="Path to xcresult bundle (or extracted contents dir)")
    parser.add_argument("-o", "--output", required=True, help="Cobertura XML output path")
    parser.add_argument("-p", "--project-root", default=os.getcwd(),
                        help="Project root; absolute file paths in the report are made relative to it")
    parser.add_argument("--exclude-dir", action="append", default=["/DerivedData/", "/.build/"],
                        help="Substring to exclude from file paths (default: DerivedData, .build)")
    args = parser.parse_args()

    xcresult = Path(args.xcresult)
    if not xcresult.exists():
        sys.exit(f"xcresult not found: {xcresult}")

    with tempfile.TemporaryDirectory() as tmp:
        report, archive = export_coverage(xcresult, Path(tmp))
        coverage = build_cobertura(report, archive, args.project_root, tuple(args.exclude_dir))

    xml = ET.tostring(coverage, encoding="unicode")
    Path(args.output).write_text('<?xml version="1.0" ?>\n' + xml + "\n")


if __name__ == "__main__":
    main()
