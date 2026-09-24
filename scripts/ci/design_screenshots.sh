#!/usr/bin/env bash
# Runs the UI tests (design screenshots) on one simulator.
# Usage: design_screenshots.sh <udid> <label>   e.g. design_screenshots.sh ABC-123 iphone-16
# Needs a prior `xcodebuild build-for-testing ... -derivedDataPath build/DerivedData`.
set -euo pipefail
UDID="$1"
LABEL="$2"

xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b
# Clean, repeatable status bar in the screenshots (best effort).
xcrun simctl status_bar "$UDID" override --time "9:41" --batteryState charged --batteryLevel 100 \
  --wifiBars 3 --cellularBars 4 || true

mkdir -p build/results
rm -rf "build/results/$LABEL.xcresult"
xcodebuild test-without-building -project BJS.xcodeproj -scheme BJS \
  -destination "id=$UDID" \
  -derivedDataPath build/DerivedData \
  -only-testing:BJSUITests \
  -resultBundlePath "build/results/$LABEL.xcresult" 2>&1 | tail -60
