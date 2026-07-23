# App Store Connect — Notes for Reviewer

Copy the text below into the **"Notes for Reviewer"** field when submitting Habit Ring for review.

---

## Notes for Reviewer

**How to complete a habit (required for testing):**  
Press and **hold** a habit circle for about 2 seconds. A progress ring fills around the circle; when it completes, you feel haptic feedback and the task is marked done. A short tap opens the context menu (Stats, Edit, Remove) instead of completing.

**First launch:**  
New users see an onboarding flow that teaches the tap-and-hold gesture and prompts them to create their first habit. You can tap "Skip" to go straight to the task list.

**Architecture:**  
The app is local-first and has no account or user login. All habit data is stored on-device with SwiftData and is never uploaded. Notifications are local only (UserNotifications), no push service. The app uses anonymous product analytics (PostHog) to understand aggregate usage, and Firebase Analytics to measure app installs and purchases for advertising (Google Ads) conversion tracking. No habit content (titles, notes, reward text) and no personal identifiers are sent; in-app purchases are processed by Apple.

**Support:**  
Support URL: https://habit-ring.lovable.app  
Privacy policy: https://habit-ring.lovable.app/privacy  
Email: habit-tracker@fooshi.co

---
