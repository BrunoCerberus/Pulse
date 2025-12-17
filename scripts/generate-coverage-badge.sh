#!/bin/bash

# Generate coverage badge from test results

RESULT_BUNDLE="./TestResults.xcresult"
BADGE_DIR="./badges"

if [ ! -d "$RESULT_BUNDLE" ]; then
    echo "Error: TestResults.xcresult not found. Run 'make coverage' first."
    exit 1
fi

mkdir -p "$BADGE_DIR"

# Extract coverage percentage
COVERAGE=$(xcrun xccov view --report "$RESULT_BUNDLE" 2>/dev/null | grep "Pulse.app" | head -1 | awk '{print $NF}' | tr -d '%')

if [ -z "$COVERAGE" ]; then
    COVERAGE="0"
fi

# Determine badge color based on coverage
if (( $(echo "$COVERAGE >= 80" | bc -l) )); then
    COLOR="brightgreen"
elif (( $(echo "$COVERAGE >= 60" | bc -l) )); then
    COLOR="yellow"
elif (( $(echo "$COVERAGE >= 40" | bc -l) )); then
    COLOR="orange"
else
    COLOR="red"
fi

# Generate SVG badge
cat > "$BADGE_DIR/coverage.svg" << EOF
<svg xmlns="http://www.w3.org/2000/svg" width="104" height="20">
  <linearGradient id="b" x2="0" y2="100%">
    <stop offset="0" stop-color="#bbb" stop-opacity=".1"/>
    <stop offset="1" stop-opacity=".1"/>
  </linearGradient>
  <mask id="a">
    <rect width="104" height="20" rx="3" fill="#fff"/>
  </mask>
  <g mask="url(#a)">
    <path fill="#555" d="M0 0h61v20H0z"/>
    <path fill="$COLOR" d="M61 0h43v20H61z"/>
    <path fill="url(#b)" d="M0 0h104v20H0z"/>
  </g>
  <g fill="#fff" text-anchor="middle" font-family="DejaVu Sans,Verdana,Geneva,sans-serif" font-size="11">
    <text x="30.5" y="15" fill="#010101" fill-opacity=".3">coverage</text>
    <text x="30.5" y="14">coverage</text>
    <text x="81.5" y="15" fill="#010101" fill-opacity=".3">${COVERAGE}%</text>
    <text x="81.5" y="14">${COVERAGE}%</text>
  </g>
</svg>
EOF

echo "Badge generated: $BADGE_DIR/coverage.svg (${COVERAGE}%)"
