#!/bin/bash
#
# Captures the App Store screenshots.
#
# Runs the `AppScreenshots` walkthrough on a dark-mode simulator and polls the
# screen throughout, then picks the frame that landed on each screen and scales
# it to the 6.5" display slot.
#
# Note that App Store *screenshots* and *app previews* take different sizes —
# 1242x2688 here, against 886x1920 for the video.
#
# Output: marketing/screenshots-6.5/

set -euo pipefail

cd "$(dirname "$0")/.."

DEVICE_NAME="${DEVICE_NAME:-iPhone 17 Pro Max}"
WORK="build/app-screenshots"
POLL="$WORK/poll"
OUT_DIR="marketing/screenshots-6.5"
LOG="$WORK/xcodebuild.log"

# The 6.5" slot (iPhone 11 Pro Max and friends). No 6.5" runtime is installed,
# so this captures at the Pro Max's native 1320x2868 and scales down: the
# aspect ratios differ by 0.4%, taken off the height rather than squashed in.
TARGET_WIDTH=1242
TARGET_HEIGHT=2688

rm -rf "$WORK"
mkdir -p "$POLL" "$OUT_DIR"

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

echo "==> Polling the screen"
# Polled rather than triggered off the walkthrough's own output: xcodebuild
# block-buffers when its stdout is a pipe, so a mark can reach the host long
# after the screen it names has moved on.
(
  while true; do
    stamp=$(python3 -c 'import time; print(int(time.time() * 1000))')
    xcrun simctl io "$UDID" screenshot --type png "$POLL/$stamp.png" >/dev/null 2>&1 || true
    sleep 0.15
  done
) &
POLL_PID=$!

cleanup() {
  kill "$POLL_PID" 2>/dev/null || true
  wait "$POLL_PID" 2>/dev/null || true
}
trap cleanup EXIT

echo "==> Running the walkthrough"
set +e
CAPTURE_APP_SCREENSHOTS=1 TEST_RUNNER_CAPTURE_APP_SCREENSHOTS=1 xcodebuild test-without-building \
  -project HabitTracker.xcodeproj \
  -scheme HabitTracker \
  -destination "id=$UDID" \
  -derivedDataPath build/DerivedData \
  -only-testing:HabitTrackerUITests/AppScreenshots \
  > "$LOG" 2>&1
TEST_STATUS=$?
set -e

cleanup
trap - EXIT

if [ "$TEST_STATUS" -ne 0 ]; then
  echo "!! The walkthrough failed. Last lines of $LOG:" >&2
  tail -40 "$LOG" >&2
  exit "$TEST_STATUS"
fi

echo "==> Selecting frames"
python3 - "$LOG" "$POLL" "$OUT_DIR" "$TARGET_WIDTH" "$TARGET_HEIGHT" <<'PY'
import re, subprocess, sys
from pathlib import Path

log_path, poll_dir, out_dir, width, height = sys.argv[1:6]
width, height = int(width), int(height)

marks = {}
for line in Path(log_path).read_text(errors="replace").splitlines():
    m = re.search(r"SCREENSHOT_MARK ([\w-]+) (\d+\.\d+)", line)
    if m and m.group(1) not in marks:
        marks[m.group(1)] = float(m.group(2))

if not marks:
    sys.exit("No SCREENSHOT_MARK lines found in " + log_path)

frames = sorted(int(p.stem) / 1000 for p in Path(poll_dir).glob("*.png"))
if not frames:
    sys.exit("No screenshots were captured")

for index, (name, at) in enumerate(marks.items(), start=1):
    # A beat after the mark: the screen is announced as it settles, and the
    # capture in flight at that instant may still show the transition.
    wanted = at + 1.0
    chosen = next((f for f in frames if f >= wanted), frames[-1])
    source = Path(poll_dir) / f"{int(round(chosen * 1000))}.png"
    target = Path(out_dir) / f"{index:02d}-{name}.png"
    subprocess.run([
        "ffmpeg", "-y", "-hide_banner", "-loglevel", "error",
        "-i", str(source),
        "-vf", f"scale={width}:-2:flags=lanczos,crop={width}:{height}",
        str(target),
    ], check=True)
    print(f"    {target.name:<28} (+{chosen - at:.2f}s)")
PY

xcrun simctl status_bar "$UDID" clear || true
rm -rf "$POLL"

echo
echo "Screenshots: $OUT_DIR"
