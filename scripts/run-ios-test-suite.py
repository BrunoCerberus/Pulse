#!/usr/bin/env python3
"""Run a prebuilt XCTest or Swift Testing suite with streaming output and a hard timeout."""

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
    r"Test Suite.*(?:started|passed|failed)|Executed [0-9]+ test|Test run with [0-9]+ test",
)

EXECUTED_PATTERN = re.compile(r"(?:Executed|Test run with) ([0-9]+) test")

# The iPhone leg is fixed (it must match the simulator the build job used); the
# iPad model is discovered so the destination survives a runner-image rotation,
# preferring a Pro. Both workflows used to carry their own copy of this as a
# shell + jq step.
IPHONE_DEVICE = "iPhone Air"
IPAD_FALLBACK_DEVICE = "iPad Pro 13-inch (M4)"


def parse_selectors(value: str) -> list[str]:
    selectors = [selector.strip() for selector in value.split(",")]
    if not selectors or any(not selector for selector in selectors):
        raise ValueError("test selectors must be a non-empty comma-separated list")
    return selectors


def pick_ipad(devices_payload: dict) -> str:
    """First available iPad from `simctl list devices available --json`,
    preferring an iPad Pro; falls back to the pinned model when none is listed.

    The Pro match is on the model name prefix, not a substring: the jq this
    replaced used `test("Pro")`, which also matches "iPad mini (A17 Pro)" —
    a chip name, not a Pro-sized device, and the wrong screen for the
    regular-width layouts this destination exists to exercise."""
    names = [
        device["name"]
        for runtime_devices in devices_payload.get("devices", {}).values()
        for device in runtime_devices
        if device.get("isAvailable") and str(device.get("name", "")).startswith("iPad")
    ]
    pro = [name for name in names if name.startswith("iPad Pro")]
    return (pro + names + [IPAD_FALLBACK_DEVICE])[0]


def resolve_destination(device_kind: str) -> str:
    if device_kind == "iphone":
        return f"platform=iOS Simulator,name={IPHONE_DEVICE},OS=latest"
    payload = json.loads(
        subprocess.run(
            ["xcrun", "simctl", "list", "devices", "available", "--json"],
            check=True,
            capture_output=True,
            text=True,
        ).stdout
    )
    return f"platform=iOS Simulator,name={pick_ipad(payload)},OS=latest"


def executed_test_count(summary_lines: list[str]) -> int | None:
    """Evidence that at least one test ran, never a retry-sensitive total.

    XCTest can report zero before Swift Testing runs in the same process.
    Taking the maximum avoids both that false zero and double-counting retries.
    """
    counts = [int(match.group(1)) for line in summary_lines if (match := EXECUTED_PATTERN.search(line))]
    return max(counts) if counts else None


def structured_execution_count(data: dict) -> int | None:
    # totalTestCount includes skipped tests. A suite of disabled tests is not
    # proof of execution, so use the explicit outcome counts instead.
    keys = ("passedTests", "failedTests", "expectedFailures")
    values = [data.get(key) for key in keys]
    if any(type(value) is not int or value < 0 for value in values):
        return None
    return sum(values)


def result_execution_count(bundle: Path) -> int | None:
    try:
        result = subprocess.run(
            ["xcrun", "xcresulttool", "get", "test-results", "summary",
             "--path", str(bundle), "--format", "json"],
            capture_output=True, text=True, timeout=30, check=True,
        )
        data = json.loads(result.stdout)
        return structured_execution_count(data) if isinstance(data, dict) else None
    except (OSError, ValueError, subprocess.SubprocessError):
        return None


def validate_execution(status: int, structured: int | None, lines: list[str]) -> tuple[int, int | None]:
    count = structured if structured is not None else executed_test_count(lines)
    # Preserve xcodebuild's failure/timeout; missing evidence is only diagnosed
    # when the command otherwise succeeded.
    return (1 if status == 0 and (count is None or count == 0) else status), count


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
                # Do NOT break on `process.poll() is not None`: the pipe can
                # still hold buffered output after the child exits, and the
                # last line xcodebuild writes is the "Executed N tests" summary
                # this report is built from. Only the reader's sentinel — sent
                # after the pipe reaches EOF — means the output is complete.
                continue
            if line is None:
                break
            sys.stdout.write(line)
            sys.stdout.flush()
            log.write(line)
            log.flush()
            if SUMMARY_PATTERN.search(line):
                summary_lines.append(line.rstrip())

        # After a timeout the process group is already dead, so the pipe closes
        # promptly; the join is bounded anyway so a wedged reader cannot hang
        # the job past its own timeout.
        reader.join(timeout=30)
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


def build_command(args: argparse.Namespace, selectors: list[str], destination: str) -> list[str]:
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
            destination,
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
    for bad in ("One,", "", " , "):
        try:
            parse_selectors(bad)
        except ValueError:
            pass
        else:
            raise AssertionError(f"empty selector was accepted: {bad!r}")

    # Device resolution: Pro preferred, any iPad otherwise, pinned model when
    # the runner image ships none.
    payload = {
        "devices": {
            "com.apple.CoreSimulator.SimRuntime.iOS-26-0": [
                {"name": "iPhone Air", "isAvailable": True},
                {"name": "iPad mini (A17 Pro)", "isAvailable": True},
                {"name": "iPad Pro 13-inch (M4)", "isAvailable": True},
                {"name": "iPad Air 11-inch (M3)", "isAvailable": False},
            ]
        }
    }
    # "iPad mini (A17 Pro)" names a chip, not a Pro-sized device, and must not
    # win the Pro preference over an actual iPad Pro.
    assert pick_ipad(payload) == "iPad Pro 13-inch (M4)", pick_ipad(payload)
    assert pick_ipad({"devices": {"r": [{"name": "iPad mini (A17 Pro)", "isAvailable": True}]}}) == "iPad mini (A17 Pro)"
    assert pick_ipad({"devices": {"r": [{"name": "iPad Air 11-inch (M3)", "isAvailable": True}]}}) == "iPad Air 11-inch (M3)"
    assert pick_ipad({}) == IPAD_FALLBACK_DEVICE
    # An unavailable iPad must not be selected just because it is named Pro.
    assert pick_ipad({"devices": {"r": [{"name": "iPad Pro 11-inch", "isAvailable": False}]}}) == IPAD_FALLBACK_DEVICE
    assert resolve_destination("iphone") == f"platform=iOS Simulator,name={IPHONE_DEVICE},OS=latest"

    # Zero-test detection: the silent no-op a renamed -only-testing selector
    # produces, versus a real run, versus output that said nothing at all.
    assert executed_test_count(["Executed 0 tests, with 0 failures (0 unexpected) in 0.000 seconds"]) == 0
    assert executed_test_count(["Executed 12 tests, with 0 failures", "Executed 3 tests, with 0 failures"]) == 12
    assert executed_test_count(["Test Suite 'All tests' passed"]) is None

    swift = "✔ Test run with 30 tests in 8 suites passed after 0.152 seconds."
    empty = "Executed 0 tests, with 0 failures"
    assert executed_test_count([empty, swift]) == 30
    assert executed_test_count([swift, swift]) == 30
    assert executed_test_count(["Test run with 0 tests passed"]) == 0
    assert SUMMARY_PATTERN.search(swift)
    assert structured_execution_count({"passedTests": 30, "failedTests": 0, "expectedFailures": 0, "skippedTests": 9}) == 30
    assert structured_execution_count({"passedTests": 0, "failedTests": 0, "expectedFailures": 0, "skippedTests": 9}) == 0
    assert structured_execution_count({"totalTestCount": 30}) is None
    assert structured_execution_count({"passedTests": "30", "failedTests": 0, "expectedFailures": 0}) is None
    assert validate_execution(0, 30, [empty]) == (0, 30)
    assert validate_execution(0, 0, [swift]) == (1, 0)
    assert validate_execution(0, None, [empty, swift]) == (0, 30)
    assert validate_execution(0, None, []) == (1, None)
    assert validate_execution(65, None, []) == (65, None)
    assert validate_execution(124, 0, []) == (124, 0)

    started = time.monotonic()
    status, _ = stream_command(
        [sys.executable, "-c", "import time; time.sleep(5)"],
        Path(os.devnull),
        timeout_seconds=0.1,
        report_timeout=False,
    )
    assert status == 124
    assert time.monotonic() - started < 2

    # Output written just before exit must still reach the summary: an earlier
    # version broke out of the read loop as soon as the child had exited and
    # lost the trailing "Executed N tests" line.
    status, summary = stream_command(
        [sys.executable, "-c", "print('Executed 7 tests, with 0 failures')"],
        Path(os.devnull),
        timeout_seconds=30,
    )
    assert status == 0 and executed_test_count(summary) == 7, summary
    print("self-test passed")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--scheme")
    parser.add_argument("--test-selectors")
    parser.add_argument("--test-name")
    parser.add_argument("--artifact-name")
    parser.add_argument("--device", choices=["iphone", "ipad"], default="iphone")
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
        args.timeout_minutes,
    ]
    if any(value is None for value in required):
        parser.error("all suite arguments are required")
    if args.timeout_minutes <= 0:
        parser.error("--timeout-minutes must be greater than zero")

    selectors = parse_selectors(args.test_selectors)
    destination = resolve_destination(args.device)
    Path("test-results").mkdir(exist_ok=True)
    command = build_command(args, selectors, destination)

    print(f"Test destination: {destination}")
    print(f"Test selectors: {' '.join(selectors)}")
    started = time.monotonic()
    status, summary_lines = stream_command(
        command,
        Path("/tmp/test_output.log"),
        timeout_seconds=args.timeout_minutes * 60,
    )
    seconds = round(time.monotonic() - started)

    # A suite that xcodebuild reports as green while having run nothing is the
    # `-only-testing` silent no-op: an unmatched class or method selector runs
    # zero tests and still exits 0, so a rename would leave the leg green while
    # covering nothing. Only assert this on an otherwise-passing run — a failed
    # run has its own, better error.
    structured = result_execution_count(Path(f"test-results/{args.artifact_name}.xcresult")) if status == 0 else None
    validated_status, executed = validate_execution(status, structured, summary_lines)
    if status == 0 and validated_status != 0:
        reason = "executed 0 tests" if executed == 0 else "has no verifiable executed-test count"
        print(f"::error::{args.test_name} {reason} — inspect the xcresult and selectors: {', '.join(selectors)}")
    status = validated_status

    # Only a completed run measures. A failed or timed-out leg would record a
    # truncated (or exactly-at-the-timeout) wall clock, and the duration ratchet
    # reports a missing leg as missing rather than treating it as a regression.
    if args.duration_suite and status == 0:
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
