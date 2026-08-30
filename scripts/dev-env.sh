#!/bin/bash
#
# Opens the Habit Tracker dev environment on a fresh desktop:
#   - Cursor on the habit-tracker workspace (new window)
#   - Xcode with HabitTracker.xcodeproj (new window)
#   - Terminal cd'd into the project folder (new window)
#
# Run from anywhere: habit-dev
#
# Requires Accessibility permission for Terminal (or your shell) so Mission
# Control can create a new desktop via UI scripting.

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CODE_DIR="$(dirname "$PROJECT_DIR")"
WORKSPACE_FILE="$CODE_DIR/habit-tracker.code-workspace"
CURSOR_CLI="/Applications/Cursor.app/Contents/Resources/app/bin/cursor"

# Create a new desktop and switch to it before opening apps.
osascript <<'SPACE'
tell application "Finder"
	set screenBounds to bounds of window of desktop
	set screenWidth to item 3 of screenBounds
end tell

tell application "System Events"
	key code 126 using control down -- Mission Control
	delay 0.8
	click at {screenWidth - 40, 30} -- "+" in the top-right corner
	delay 0.5
end tell
SPACE

if [[ ! -f "$WORKSPACE_FILE" ]]; then
	echo "Workspace not found: $WORKSPACE_FILE" >&2
	exit 1
fi

if [[ -x "$CURSOR_CLI" ]]; then
	"$CURSOR_CLI" -n "$WORKSPACE_FILE"
else
	open -na Cursor "$WORKSPACE_FILE"
fi

open -n "$PROJECT_DIR/HabitTracker.xcodeproj"

# `do script` opens a new window on its own. The older `make new window` +
# `do script in w` pattern fails on recent macOS (-10000 AppleEvent handler).
SAFE_DIR="$(printf '%q' "$PROJECT_DIR")"
if ! osascript <<EOF
tell application "Terminal"
	do script "cd ${SAFE_DIR} && clear && echo 'Habit Tracker dev environment ready.'"
	activate
end tell
EOF
then
	COMMAND_FILE="$(mktemp "${TMPDIR:-/tmp}/habit-dev.XXXXXX.command")"
	cat > "$COMMAND_FILE" <<SCRIPT
#!/bin/bash
cd $(printf '%q' "$PROJECT_DIR")
clear
echo 'Habit Tracker dev environment ready.'
exec \$SHELL -l
SCRIPT
	chmod +x "$COMMAND_FILE"
	open -a Terminal "$COMMAND_FILE"
	(sleep 2 && rm -f "$COMMAND_FILE") &
fi
