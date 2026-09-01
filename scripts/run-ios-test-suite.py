#!/usr/bin/env python3
"""Run a prebuilt XCTest suite with streaming output and a hard timeout."""

from __future__ import annotations

import argparse
import json
import os
import queue
import re
import signal
import subprocess
import sys
import threading
import time
from pathlib import Path


SUMMARY_PATTERN = re.compile(
    r"Test Suite.*(?:started|passed|failed)|Executed [0-9]+ test",
)


def parse_selectors(value: str) -> list[str]:
    selectors = [selector.strip() for selector in value.split(",")]
    if not selectors or any(not selector for selector in selectors):
        raise ValueError("test selectors must be a non-empty comma-separated list")
    return selectors


def terminate_process_group(process: subprocess.Popen[str]) -> None:
    try:
        os.killpg(process.pid, signal.SIGTERM)
        process.wait(timeout=10)
    except ProcessLookupError:
        return
    except subprocess.TimeoutExpired:
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        process.wait()


def stream_command(
    command: list[str],
    log_path: Path,
    timeout_seconds: float,
    *,
    report_timeout: bool = True,
) -> tuple[int, list[str]]:
    process = subprocess.Popen(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
        start_new_session=True,
    )
    assert process.stdout is not None

    output_queue: queue.Queue[str | None] = queue.Queue()

    def read_output() -> None:
        for line in process.stdout:
            output_queue.put(line)
        output_queue.put(None)

    reader = threading.Thread(target=read_output, daemon=True)
    reader.start()
    deadline = time.monotonic() + timeout_seconds
    summary_lines: list[str] = []
    timed_out = False

    with log_path.open("w") as log:
        while True:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                if process.poll() is None:
                    timed_out = True
                    terminate_process_group(process)
                break
            try:
                line = output_queue.get(timeout=min(0.5, remaining))
            except queue.Empty:
                if process.poll() is not None:
                    break
                continue
            if line is None:
                break
            sys.stdout.write(line)
            sys.stdout.flush()
            log.write(line)
            log.flush()
            if SUMMARY_PATTERN.search(line):
                summary_lines.append(line.rstrip())

        reader.join(timeout=1)
        while True:
            try:
                line = output_queue.get_nowait()
            except queue.Empty:
                break
            if line is None:
                continue
            sys.stdout.write(line)
            log.write(line)
            if SUMMARY_PATTERN.search(line):
                summary_lines.append(line.rstrip())

    if timed_out:
        if report_timeout:
            print(f"::error::Test command exceeded {timeout_seconds / 60:g} minutes")
        return 124, summary_lines
    return process.wait(), summary_lines


def build_command(args: argparse.Namespace, selectors: list[str]) -> list[str]:
    command = [
        "xcodebuild",
        "test-without-building",
        "-project",
        "Pulse.xcodeproj",
        "-scheme",
        args.scheme,
    ]
    command.extend(f"-only-testing:{selector}" for selector in selectors)
    command.extend(
        [
            "-destination",
            args.destination,
            "-derivedDataPath",
            "./DerivedData",
            "-resultBundlePath",
            f"test-results/{args.artifact_name}.xcresult",
        ]
    )
    if args.enable_code_coverage == "true":
        command.extend(["-enableCodeCoverage", "YES"])
    command.extend(["-disableAutomaticPackageResolution", "-retry-tests-on-failure"])
    return command


def self_test() -> None:
    assert parse_selectors("One, Two/test") == ["One", "Two/test"]
    try:
        parse_selectors("One,")
    except ValueError:
        pass
    else:
        raise AssertionError("empty selector was accepted")

    started = time.monotonic()
    status, _ = stream_command(
        [sys.executable, "-c", "import time; time.sleep(5)"],
        Path(os.devnull),
        timeout_seconds=0.1,
        report_timeout=False,
    )
    assert status == 124
    assert time.monotonic() - started < 2
    print("self-test passed")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--scheme")
    parser.add_argument("--test-selectors")
    parser.add_argument("--test-name")
    parser.add_argument("--artifact-name")
    parser.add_argument("--destination")
    parser.add_argument("--timeout-minutes", type=float)
    parser.add_argument("--enable-code-coverage", choices=["true", "false"], default="false")
    parser.add_argument("--duration-suite", default="")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()

    if args.self_test:
        self_test()
        return 0

    required = [
        args.scheme,
        args.test_selectors,
        args.test_name,
        args.artifact_name,
        args.destination,
        args.timeout_minutes,
    ]
    if any(value is None for value in required):
        parser.error("all suite arguments are required")

    selectors = parse_selectors(args.test_selectors)
    Path("test-results").mkdir(exist_ok=True)
    command = build_command(args, selectors)

    print(f"Test destination: {args.destination}")
    print(f"Test selectors: {' '.join(selectors)}")
    started = time.monotonic()
    status, summary_lines = stream_command(
        command,
        Path("/tmp/test_output.log"),
        timeout_seconds=args.timeout_minutes * 60,
    )
    seconds = round(time.monotonic() - started)

    if args.duration_suite:
        duration_path = Path(f"suite-duration-{args.duration_suite}.json")
        duration_path.write_text(json.dumps({"suite": args.duration_suite, "seconds": seconds}) + "\n")
        print(f"{args.test_name} wall clock: {seconds // 60}m{seconds % 60}s")

    print("\n============================================")
    print("              TEST SUMMARY")
    print("============================================")
    if summary_lines:
        print("\n".join(summary_lines[-10:]))
    else:
        print(f"{args.test_name} completed")
    return status


if __name__ == "__main__":
    raise SystemExit(main())
