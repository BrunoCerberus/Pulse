#!/bin/bash
# boot-simulator.sh
# Reliably boot and warm up an iOS simulator for CI.
# Addresses "Host is down" / "system shell crashed" flakiness on iOS 26.3.
#
# Usage: ./scripts/boot-simulator.sh [device_name] [warmup_seconds]
#   device_name    - Simulator name (default: "iPhone Air")
#   warmup_seconds - Extra sleep after boot (default: 30)

set -euo pipefail

DEVICE_NAME="${1:-iPhone Air}"
WARMUP_SECONDS="${2:-30}"

echo "=== Simulator Pre-boot & Warmup ==="
echo "Device: $DEVICE_NAME"
echo ""

# 1. Shutdown all running simulators for a clean state
echo "Shutting down all simulators..."
xcrun simctl shutdown all 2>/dev/null || true

# 2. Find the device UDID
echo "Looking up simulator UDID..."
UDID=$(xcrun simctl list devices available -j | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data.get('devices', {}).items():
    if 'iOS' in runtime:
        for d in devices:
            if d['name'] == '${DEVICE_NAME}' and d['isAvailable']:
                print(d['udid'])
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

# 4. Boot the simulator
echo "Booting simulator..."
xcrun simctl boot "$UDID"

# 5. Wait for the simulator to report fully booted
echo "Waiting for boot to complete..."
xcrun simctl bootstatus "$UDID" -b

# 6. Extra warmup time — iOS 26.3 simulators on CI need this to stabilise
echo "Warming up simulator (${WARMUP_SECONDS}s)..."
sleep "$WARMUP_SECONDS"

# 7. Verify
echo ""
echo "Booted simulators:"
xcrun simctl list devices booted
echo "=== Simulator ready ==="
