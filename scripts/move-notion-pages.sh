#!/usr/bin/env bash
# Move the 3 App Store doc pages into Notion Fds → Habit-Tracker.
# Requires NOTION_API_KEY (or NOTION_TOKEN) with access to the workspace.
# Run: NOTION_API_KEY=your_secret_xxx ./scripts/move-notion-pages.sh

set -e

TOKEN="${NOTION_API_KEY:-$NOTION_TOKEN}"
if [ -z "$TOKEN" ]; then
  echo "Error: Set NOTION_API_KEY or NOTION_TOKEN (Notion integration secret)."
  exit 1
fi

HABIT_TRACKER_PAGE_ID="ca129892-cffb-4c38-8708-d4cb75e1d83d"

PAGES=(
  "30fa4fc6-9abf-8190-8e8c-f4831ffbec99"   # App Store Connect Metadata
  "30fa4fc6-9abf-81c4-ad97-facbedeecd2e"   # App Store Review Notes
  "30fa4fc6-9abf-8166-b6ad-e307aef53124"   # App Store Approval Audit
)

for PAGE_ID in "${PAGES[@]}"; do
  echo "Moving page ${PAGE_ID} under Habit-Tracker..."
  curl -s -X PATCH "https://api.notion.com/v1/pages/${PAGE_ID}" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Notion-Version: 2022-06-28" \
    -H "Content-Type: application/json" \
    -d "{\"parent\": {\"page_id\": \"${HABIT_TRACKER_PAGE_ID}\"}}" > /dev/null || {
    echo "Failed to move ${PAGE_ID}"
    exit 1
  }
done

echo "Done. All 3 pages are now under Fds → Habit-Tracker."
