#!/bin/sh
# Freeze the simulator status bar so screen-tour PNGs don't git-diff on the clock.
# Apple's screenshot time is 9:41. Pass a UDID, or default to whatever is booted.
set -e
UDID="${1:-booted}"
xcrun simctl status_bar "$UDID" override \
  --time "9:41" \
  --dataNetwork wifi --wifiMode active --wifiBars 3 \
  --cellularMode active --cellularBars 4 \
  --operatorName "" \
  --batteryState charged --batteryLevel 100
