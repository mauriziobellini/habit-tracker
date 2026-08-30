#!/bin/bash
#
# Records the raw footage for the App Store app preview.
#
# Boots an iPhone 6.9" simulator in dark mode with a clean status bar, runs the
# `AppPreviewRecording` walkthrough, and captures the screen while it plays.
#
# Output (build/app-preview/):
#   raw.mov    the full uncut screen recording
#   marks.txt  cut points in video time, written by the walkthrough
#
# Run `scripts/build-app-preview.sh` afterwards to cut and title it.

set -euo pipefail

cd "$(dirname "$0")/.."

DEVICE_NAME="${DEVICE_NAME:-iPhone 17 Pro Max}"
OUT_DIR="build/app-preview"
RAW="$OUT_DIR/raw.mov"
MARKS="$OUT_DIR/marks.txt"
LOG="$OUT_DIR/xcodebuild.log"

mkdir -p "$OUT_DIR"

echo "==> Resolving simulator: $DEVICE_NAME"
UDID=$(xcrun simctl list devices available -j \
  | python3 -c "
import json,sys
name = sys.argv[1]
data = json.load(sys.stdin)['devices']
for runtime, devices in sorted(data.items(), reverse=True):
    for d in devices:
        if d['name'] == name and d['isAvailable']:
            print(d['udid']); sys.exit(0)
sys.exit('No available simulator named ' + name)
" "$DEVICE_NAME")
echo "    $UDID"

echo "==> Booting and preparing the simulator"
xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1 || xcrun simctl boot "$UDID" || true
xcrun simctl bootstatus "$UDID" -b >/dev/null
xcrun simctl ui "$UDID" appearance dark
# A marketing-clean status bar: no carrier text, full bars, no low-battery tint.
xcrun simctl status_bar "$UDID" override \
  --time "9:41" \
  --dataNetwork wifi \
  --wifiMode active \
  --wifiBars 3 \
  --cellularMode active \
  --cellularBars 4 \
  --batteryState charged \
  --batteryLevel 100

echo "==> Building for testing"
xcodebuild build-for-testing \
  -project HabitTracker.xcodeproj \
  -scheme HabitTracker \
  -destination "id=$UDID" \
  -derivedDataPath build/DerivedData \
  -quiet

echo "==> Starting screen recording"
rm -f "$RAW"
xcrun simctl io "$UDID" recordVideo --codec h264 --force "$RAW" &
RECORD_PID=$!
# Captured after the process is up but before the first frame the walkthrough
# cares about. `build-app-preview.sh` exposes SYNC_OFFSET to trim any residual
# start-up latency without re-recording.
sleep 2
RECORD_START=$(python3 -c 'import time; print(repr(time.time()))')

cleanup() {
  if kill -0 "$RECORD_PID" 2>/dev/null; then
    kill -INT "$RECORD_PID" 2>/dev/null || true
    wait "$RECORD_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

echo "==> Running the walkthrough"
set +e
TEST_RUNNER_RECORD_APP_PREVIEW=1 xcodebuild test-without-building \
  -project HabitTracker.xcodeproj \
  -scheme HabitTracker \
  -destination "id=$UDID" \
  -derivedDataPath build/DerivedData \
  -only-testing:HabitTrackerUITests/AppPreviewRecording \
  > "$LOG" 2>&1
TEST_STATUS=$?
set -e

# Two seconds of tail, so the last segment never runs into the end of the file.
sleep 2
echo "==> Stopping screen recording"
cleanup
trap - EXIT

if [ "$TEST_STATUS" -ne 0 ]; then
  echo "!! The walkthrough failed. Last lines of $LOG:" >&2
  tail -40 "$LOG" >&2
  exit "$TEST_STATUS"
fi

echo "==> Writing cut points"
python3 - "$LOG" "$MARKS" "$RECORD_START" <<'PY'
import re, sys

log_path, marks_path, record_start = sys.argv[1], sys.argv[2], float(sys.argv[3])
pattern = re.compile(r"PREVIEW_MARK (\w+) (\d+\.\d+)")

seen = {}
for line in open(log_path, errors="replace"):
    m = pattern.search(line)
    if m and m.group(1) not in seen:
        seen[m.group(1)] = float(m.group(2)) - record_start

if not seen:
    sys.exit("No PREVIEW_MARK lines found in " + log_path)

with open(marks_path, "w") as out:
    for name, offset in seen.items():
        out.write(f"{name} {offset:.3f}\n")

for name, offset in seen.items():
    print(f"    {name:<14} {offset:7.3f}s")
PY

xcrun simctl status_bar "$UDID" clear || true

echo
echo "Raw footage: $RAW"
echo "Cut points:  $MARKS"
echo "Next:        scripts/build-app-preview.sh"
