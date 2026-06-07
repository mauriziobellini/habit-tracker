---
name: App Store Approval Audit
overview: Comprehensive audit of the Habit Tracker iOS app against Apple's App Store Review Guidelines, identifying 13 issues across 4 severity levels (3 critical, 4 high, 3 moderate, 3 low) with a remediation plan.
todos:
  - id: privacy-policy
    content: "C1: Add privacy policy link (https://habit-ring.lovable.app/privacy) in AppSettingsView supportSection"
    status: completed
  - id: ip-differentiation
    content: "C2: Sanitize README.md and docs of Streak 'copy' language (no UX changes)"
    status: completed
  - id: rename-app
    content: "C3: Rename app to 'Habit Ring', update bundle ID to co.fooshi.habitring, update display name in project.yml"
    status: completed
  - id: store-metadata
    content: "H1: Prepare App Store Connect metadata (description, keywords, screenshots, copyright, support URL)"
    status: completed
  - id: notification-context
    content: "H2: Add pre-permission explanation before requesting notification authorization"
    status: completed
  - id: review-notes
    content: "H4: Write App Store review notes explaining tap-and-hold mechanic and local-only architecture"
    status: completed
  - id: delete-all-data
    content: "H3: Add 'Reset All Data' option in AppSettingsView with confirmation dialog"
    status: completed
  - id: launch-screen
    content: "M3: Create a branded launch screen replacing auto-generated one"
    status: completed
isProject: false
---

# App Store Approval Audit Report & Remediation Plan

## App Summary

- **Name:** Habit Ring
- **Bundle ID:** `co.fooshi.habitring`
- **iOS Target:** 17.0+
- **Architecture:** SwiftUI + SwiftData, fully local, no network, no accounts
- **Monetization:** None (free app, no IAP)

---

## CRITICAL Issues (Will cause rejection)

### C1. Missing Privacy Policy (Guideline 5.1.1)

Apple requires **every app** to have a privacy policy URL, provided both in App Store Connect and ideally accessible within the app. The codebase has **zero** references to a privacy policy or terms of service.

Even though the app collects no data and makes no network requests, you must still provide a privacy policy that states this clearly.

**What to do:**

- Privacy policy is hosted at: `https://habit-ring.lovable.app/privacy`
- Add a "Privacy Policy" link in `AppSettingsView.swift` under the Support section that opens this URL in Safari
- Provide the same URL in App Store Connect during submission

**Files to change:** [HabitTracker/Views/AppSettingsView.swift](HabitTracker/Views/AppSettingsView.swift) (add link in `supportSection`)

---

### C2. Intellectual Property / Documentation Sanitization (Guidelines 4.1, 5.2.1)

The PRD and README contain explicit references to the competitor app "Streak" that should be cleaned up before submission. While the tap-and-hold ring gesture is a common pattern in habit trackers and will be kept as-is, the documentation should not reference the competitor.

**Current risks:**

- The [README.md](README.md) line 3 says: *"An iOS habit tracker app inspired by Streak"* with a direct link to streaksapp.com
- The internal docs (`prd.md`) contain explicit "copy of Streak" language
- The [docs/tech-stack.md](docs/tech-stack.md) references "Streak-quality polish" and benchmarking against Streak

**What to do (documentation sanitization only -- no UX changes):**

- **Sanitize [README.md](README.md):** Remove the "inspired by Streak" mention and the link to streaksapp.com. Replace with a generic description of the app
- **Sanitize [docs/prd.md](docs/prd.md):** Remove lines referencing "copy/cut of Streak" and "similar to Streak" (lines 5, 12, 292)
- **Sanitize [docs/tech-stack.md](docs/tech-stack.md):** Remove "Streak" benchmarking references (lines 26, 85)
- **Do NOT mention Streak** anywhere in App Store metadata (description, keywords, screenshots)

**Note:** The tap-and-hold ring completion UX is kept unchanged. The app has unique differentiators (reward system, custom categories, general stats aggregation) that set it apart. The new app name "Habit Ring" further distinguishes it.

---

### C3. Rename App to "Habit Ring" and Update Bundle ID

The current bundle ID `com.habittracker.app` and display name "Habit Tracker" are extremely generic. The app will be renamed to **"Habit Ring"** with bundle ID `com.fooshi.habitring`.

**What to do:**

- Update display name from "Habit Tracker" to "Habit Ring" in [project.yml](project.yml) line 28: `INFOPLIST_KEY_CFBundleDisplayName: "Habit Ring"`
- Update bundle ID from `com.habittracker.app` to `app.fooshidigital.habitring` in [project.yml](project.yml) line 27
- Update `bundleIdPrefix` from `com.habittracker` to `co.fooshi` in [project.yml](project.yml) line 3
- Update test bundle IDs accordingly: `co.fooshi.habitring.tests` and `co.fooshi.habitring.uitests`
- Update the navigation title "My Habits" string and any references to "Habit Tracker" in user-facing strings
- Update the support email subject or references if they contain the old name

---

## HIGH-RISK Issues (May cause rejection or delay)

### H1. No App Store Connect Metadata Preparation

Apple requires specific metadata that must be prepared before submission:

- App description (max 4000 chars)
- Keywords (max 100 chars)
- Screenshots for **all required device sizes** (iPhone 6.9", 6.7", 6.5", 5.5")
- App preview video (optional but strongly recommended)
- Copyright text (currently "TBD" in [README.md](README.md) line 28)
- Support URL (must be a working web page, not just an email)
- Age rating questionnaire answers

**What to do:**

- Write compelling app description and keywords
- Create screenshots on all required device sizes
- Set proper copyright (e.g., "(c) 2026 Fooshi")
- Create a public support page (could use `https://habit-ring.lovable.app` as the support URL alongside the privacy page)

---

### H2. Missing Notification Permission Context (Guideline 5.1.1)

The app requests notification permissions in [NotificationService.swift](HabitTracker/Services/NotificationService.swift) line 16 via `requestAuthorization()`, but the system prompt gives no context to users about why notifications are needed. While iOS doesn't require a plist key for local notifications, Apple reviewers may flag a bare permission prompt with no pre-explanation.

**What to do:**

- Add a pre-permission screen or explanatory text **before** calling `requestAuthorization()` that explains: "We'll send you gentle reminders to help you build your habits"
- This should appear in the task configuration flow when the user first enables notifications

---

### H3. No "Delete All Data" Option (Best practice for Guideline 5.1.1)

While Apple's account deletion requirement (5.1.1(v)) only applies to apps with account creation, having **no way to reset all app data** is a UX gap and potential review concern.

**What to do:**

- Add a "Delete All Data" / "Reset App" option in [AppSettingsView.swift](HabitTracker/Views/AppSettingsView.swift) with confirmation dialog
- This also helps with GDPR "right to erasure"

---

### H4. App Store Review Notes Needed

The reviewer may not understand the tap-and-hold mechanic without guidance.

**What to do:**

- Prepare clear review notes explaining:
  - How to complete a task (press and hold for 2 seconds)
  - That the app is local-only (no server)
  - That onboarding teaches the gesture
- Include a demo video or step-by-step in the "Notes for Reviewer" field in App Store Connect

---

## MODERATE Issues (Unlikely to cause rejection but should address)

### M1. Incomplete Localization

The PRD mentions 12 languages across 3 tiers, but only English (`en.lproj/Localizable.strings`) is implemented. While English-only is acceptable for submission, if you list additional languages in App Store Connect, you must localize the app for those languages.

**What to do:**

- Either ship with English only (acceptable) and don't claim other languages
- Or implement at least the Tier 1 languages before submission

---

### M2. No Crash Reporting or Analytics

Without crash reporting (Crashlytics, Sentry, etc.), maintaining the target of 99.5% crash-free sessions will be difficult to measure and respond to.

**What to do:**

- At minimum, enable Apple's built-in crash reporting via Xcode Organizer / App Store Connect
- Consider adding MetricKit framework for on-device crash diagnostics (no third-party SDK needed)

---

### M3. Auto-Generated Launch Screen

The app uses `INFOPLIST_KEY_UILaunchScreen_Generation = YES` which creates a plain white/black launch screen. This looks unprofessional and could contribute to a perception of low quality.

**What to do:**

- Create a branded launch screen (e.g., with the app icon gradient) using a LaunchScreen storyboard or the `UILaunchScreen` plist configuration
- Update in [project.yml](project.yml)

---

## LOW-RISK Issues (Polish items, won't cause rejection)

### L1. No Data Export Feature

GDPR's "right to data portability" is satisfied by having a way for users to export their data. Not a blocker for App Store approval, but valuable for EU users.

**What to do (optional):** Add "Export Data" button in Settings that generates a JSON/CSV of all habits and completions.

---

### L2. Support Email Must Be Monitored

The support email `habit-tracker@fooshi.co` in [AppSettingsView.swift](HabitTracker/Views/AppSettingsView.swift) line 188 must be actively monitored. Apple may send compliance inquiries to this address. A bouncing support email can trigger post-launch issues.

---

### L3. TODO Comment in Production Code

[AppSettingsView.swift](HabitTracker/Views/AppSettingsView.swift) line 84 has a `TODO` with commented-out code. Not a rejection risk, but shows unfinished work that a thorough reviewer might note.

---

## Remediation Priority Matrix


| Priority | Issue                              | Effort | Risk if Skipped       |
| -------- | ---------------------------------- | ------ | --------------------- |
| 1        | C1 - Privacy Policy link           | Low    | Guaranteed rejection  |
| 2        | C2 - Doc sanitization (Streak ref) | Low    | Possible rejection    |
| 3        | C3 - Rename to "Habit Ring"        | Low    | Possible rejection    |
| 4        | H1 - App Store metadata            | Medium | Cannot submit         |
| 5        | H2 - Notification context          | Low    | Possible rejection    |
| 6        | H4 - Review notes                  | Low    | Possible confusion    |
| 7        | H3 - Delete all data               | Low    | Unlikely rejection    |
| 8        | M3 - Launch screen                 | Low    | Won't cause rejection |
| 9        | M1 - Localization                  | High   | Won't cause rejection |
| 10       | M2 - Crash reporting               | Low    | Won't cause rejection |

