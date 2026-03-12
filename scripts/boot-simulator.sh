#!/bin/bash
# boot-simulator.sh
# Reliably boot and warm up an iOS simulator for CI.
# Addresses "Host is down" / "system shell crashed" flakiness on iOS 26.3.
#
# Usage: ./scripts/boot-simulator.sh [device_name] [warmup_seconds]
#   device_name    - Simulator name (default: "iPhone Air")
#   warmup_seconds - Extra sleep after boot (default: 20)

set -euo pipefail

DEVICE_NAME="${1:-iPhone Air}"
WARMUP_SECONDS="${2:-20}"

echo "=== Simulator Pre-boot & Warmup ==="
echo "Device: $DEVICE_NAME"
echo ""

# 1. Shutdown all running simulators for a clean state
echo "Shutting down all simulators..."
xcrun simctl shutdown all 2>/dev/null || true

# 2. Find the device UDID
echo "Looking up simulator UDID..."
UDID=$(xcrun simctl list devices available -j | python3 -c "
import json, sys, re
data = json.load(sys.stdin)
best_udid = None
best_version = (0, 0, 0)
for runtime, devices in data.get('devices', {}).items():
    if 'iOS' not in runtime:
        continue
    # Extract version from runtime identifier (e.g. 'com.apple.CoreSimulator.SimRuntime.iOS-26-3')
    m = re.search(r'iOS[- ](\d+)[.-](\d+)(?:[.-](\d+))?', runtime)
    if not m:
        continue
    version = (int(m.group(1)), int(m.group(2)), int(m.group(3) or 0))
    for d in devices:
        if d['name'] == '${DEVICE_NAME}' and d['isAvailable']:
            if version >= best_version:
                best_version = version
                best_udid = d['udid']
if best_udid:
    print(best_udid)
    sys.exit(0)
sys.exit(1)
") || {
    echo "ERROR: '$DEVICE_NAME' simulator not found!"
    echo "Available devices:"
    xcrun simctl list devices available
    exit 1
}

echo "Found UDID: $UDID"

# 3. Erase the simulator for a pristine state
echo "Erasing simulator..."
xcrun simctl erase "$UDID" 2>/dev/null || true

# 4. Boot the simulator (background with 30s timeout to prevent hanging)
echo "Booting simulator..."
xcrun simctl boot "$UDID" &
BOOT_PID=$!
BOOT_WAIT=0
while kill -0 "$BOOT_PID" 2>/dev/null && [ "$BOOT_WAIT" -lt 30 ]; do
    sleep 1
    BOOT_WAIT=$((BOOT_WAIT + 1))
done
if kill -0 "$BOOT_PID" 2>/dev/null; then
    kill "$BOOT_PID" 2>/dev/null || true
    echo "ERROR: simctl boot timed out after 30s"
    exit 1
fi
wait "$BOOT_PID" || true

# 5. Wait for the simulator to report fully booted (polling with 120s timeout)
echo "Waiting for boot to complete..."
BOOT_TIMEOUT=120
POLL_INTERVAL=5
ELAPSED=0
while [ "$ELAPSED" -lt "$BOOT_TIMEOUT" ]; do
    if xcrun simctl list devices booted | grep -q "$UDID"; then
        echo "Simulator booted successfully after ${ELAPSED}s."
        break
    fi
    sleep "$POLL_INTERVAL"
    ELAPSED=$((ELAPSED + POLL_INTERVAL))
done

if [ "$ELAPSED" -ge "$BOOT_TIMEOUT" ]; then
    echo "ERROR: Simulator failed to boot within ${BOOT_TIMEOUT}s!"
    xcrun simctl list devices
    exit 1
fi

# 6. Extra warmup time — iOS 26.3 simulators on CI need this to stabilise
echo "Warming up simulator (${WARMUP_SECONDS}s)..."
sleep "$WARMUP_SECONDS"

# 7. Verify
echo ""
echo "Booted simulators:"
xcrun simctl list devices booted
echo "=== Simulator ready ==="
