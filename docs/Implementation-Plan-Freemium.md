# Implementation Plan — Ringhabit Freemium

> Multi-agent delivery plan derived from [PRD - Freemium.md](/Users/maurizio.bellini/Documents/Vault/Product/Ring%20habit/PRD%20-%20Freemium.md) and supporting project docs.

**Feature:** Convert Ringhabit from €0.99 paid download to freemium (2 free habits, paywall on 3rd) with monthly €0.99, yearly €8, and lifetime €15 options.

**Target repo:** `habit-tracker` (bundle ID `co.fooshi.habitring`)

**Status:** Draft  
**Date:** 2026-06-14

---

## Input document validation

| Document | Path | Status |
|----------|------|--------|
| PRD (Freemium) | `Vault/Product/Ring habit/PRD - Freemium.md` | ✅ Provided |
| UX principles | `docs/ux-ui-principles.md` + PRD §8 | ✅ Available (paywall UX in PRD §8) |
| Tech stack | `docs/tech-stack.md` + PRD §9 | ✅ Available |
| Data model | `docs/data-model.md` | ✅ Available |
| Freemium acceptance criteria | — | ⚠️ **Missing** — create in Phase 0 |
| Dedicated UX plan (Figma) | — | ⚠️ **Missing** — PRD §8 is sufficient for v1 |

---

## Product IDs (do not rename after launch)

| Product | Type | Price | Product ID |
|---------|------|-------|------------|
| Monthly | Auto-renewable subscription | €0.99/mo | `co.fooshi.habitring.premium.monthly` |
| Yearly | Auto-renewable subscription | €8/yr | `co.fooshi.habitring.premium.yearly` |
| Lifetime | Non-consumable | €15 | `co.fooshi.habitring.premium.lifetime` |

**Entitlement logic:** `isPremium = hasActiveSubscription OR hasLifetimePurchase`  
**Legacy mapping:** €0.99 paid-app download owners → `hasLifetimePurchase` via `AppTransaction` / original app receipt.

**Free tier limit:** `freeHabitLimit = 2`

---

## Delivery phases overview

| Phase | Focus | Agents |
|-------|--------|--------|
| 0 | Prep & App Store Connect | Product / Release |
| 1 | StoreKit foundation | iOS / StoreKit |
| 2 | Paywall UI | iOS / SwiftUI |
| 3 | Habit gating & lapse UX | iOS / SwiftUI |
| 4 | Settings, analytics, localization | iOS |
| 5 | App Store & legal surface | Release / Docs |
| 6 | QA, Sandbox, submission | QA / Release |

---

## Phase 0 — Preparation

### Step 0.1 — Freemium acceptance criteria

**Objective:** Define testable Given/When/Then scenarios for paywall, entitlements, legacy mapping, and subscription lapse.

**Inputs:** PRD §4, §6, §7, §8, §10

**Deliverable:** `docs/acceptance-criteria-freemium.md` (Gherkin format, mirrors `docs/acceptance-criteria.md` style)

**Agent prompt:**
```
Read PRD - Freemium.md (Vault/Product/Ring habit/) and docs/acceptance-criteria.md for format reference.
Create docs/acceptance-criteria-freemium.md with Given/When/Then scenarios covering:
- Free tier (2 habits, delete/re-add under limit)
- Paywall on 3rd habit (+ button)
- All 3 purchase paths (monthly, yearly, lifetime)
- Restore Purchases (paywall + settings)
- Legacy €0.99 paid-app → lifetime mapping
- Expired subscription (2 active, 3+ greyed)
- Paywall bottom sheet UX (dismiss, close, chained NewTaskSelector)
- Settings: Restore Purchases, Manage Subscription
Do not implement code — acceptance criteria only.
```

**Existing tests that must pass:** All tests in `HabitTrackerTests/` and `HabitTrackerUITests/` (no regressions).

**New tests to implement:** None (documentation only).

---

### Step 0.2 — App Store Connect IAP setup

**Objective:** Configure products in App Store Connect before code integration.

**Inputs:** PRD §7, §10; product ID table above

**Deliverable:** Subscription group + 3 products live in ASC (Sandbox-testable); StoreKit Configuration file in Xcode project

**Agent prompt:**
```
You are a release engineer. Using PRD - Freemium.md §7 and §10:
1. Document step-by-step App Store Connect setup for subscription group + monthly/yearly + lifetime non-consumable.
2. Create HabitTracker/Configuration.storekit in the Xcode project with product IDs:
   - co.fooshi.habitring.premium.monthly (€0.99)
   - co.fooshi.habitring.premium.yearly (€8)
   - co.fooshi.habitring.premium.lifetime (€15)
3. Add StoreKit Configuration to the HabitTracker scheme for local testing.
Output a checklist markdown section in docs/app-store-connect-metadata.md for freemium products.
Note: ASC web UI steps must be done manually; provide exact field values.
```

**Existing tests that must pass:** All existing unit/UI tests.

**New tests to implement:** None.

---

## Phase 1 — StoreKit foundation

### Step 1.1 — EntitlementManager & PurchaseService

**Objective:** Core StoreKit 2 layer — product loading, purchase, entitlement check, restore, legacy paid-app detection.

**Inputs:** PRD §7, §9; `Configuration.storekit`; `docs/tech-stack.md`

**Deliverable:**
- `HabitTracker/Services/EntitlementManager.swift` (`@Observable`)
- `HabitTracker/Services/PurchaseService.swift`
- `HabitTracker/Models/PremiumPlan.swift` (enum: monthly, yearly, lifetime)
- `HabitTracker/Utilities/ProductIDs.swift`

**Agent prompt:**
```
Implement StoreKit 2 purchase infrastructure for Ringhabit freemium in habit-tracker.

Requirements (from PRD - Freemium.md §7, §9):
- Native StoreKit 2 only (no RevenueCat)
- Product IDs: co.fooshi.habitring.premium.monthly, .yearly, .lifetime
- EntitlementManager (@Observable): isPremium, hasActiveSubscription, hasLifetimePurchase
- On launch: async check Transaction.currentEntitlements + legacy paid-app via AppTransaction
- Legacy: map €0.99 paid-app download owners to hasLifetimePurchase (same as €15 lifetime IAP)
- PurchaseService: load products, purchase(plan), restore() via AppStore.sync()
- Inject EntitlementManager via @Environment or app-level @State in HabitTrackerApp.swift
- Use Configuration.storekit for local dev

Match existing code style: MVVM, @Observable, Services/ folder pattern (see NotificationService.swift).
Add unit tests in HabitTrackerTests/ with StoreKit Test framework / mocked entitlements where possible.
Do not build UI yet.
```

**Existing tests that must pass:** All `HabitTrackerTests` enum/model/statistics tests; all `HabitTrackerUITests`.

**New tests to implement:**
- `EntitlementManagerTests`: `isPremium` true when subscription entitlement present
- `EntitlementManagerTests`: `isPremium` true when lifetime entitlement present
- `EntitlementManagerTests`: `isPremium` false when no entitlements
- `EntitlementManagerTests`: legacy paid-app mapping grants `hasLifetimePurchase`
- `PurchaseServiceTests`: product loading returns 3 products (StoreKit config)

---

### Step 1.2 — Optional premium cache in AppSettings

**Objective:** Cache verified premium state for faster cold launch; StoreKit remains source of truth.

**Inputs:** PRD §9; `HabitTracker/Models/AppSettings.swift`; `docs/data-model.md`

**Deliverable:** `AppSettings` fields + migration; update `data-model.md`

**Agent prompt:**
```
Add optional premium cache to AppSettings per PRD §9:
- Fields: lastKnownIsPremium (Bool), lastEntitlementCheckAt (Date) — or use Keychain for isPremium cache
- EntitlementManager updates cache after successful StoreKit check
- On launch: show cached value optimistically, refresh async from StoreKit
Update docs/data-model.md with new AppSettings fields.
Add unit test for cache read/write. All existing tests must pass.
```

**Existing tests that must pass:** All `HabitTrackerTests` including `AppSettings` tests if any.

**New tests to implement:**
- `AppSettingsTests`: premium cache round-trip

---

## Phase 2 — Paywall UI

### Step 2.1 — PaywallView bottom sheet

**Objective:** Paywall UI per PRD §6, §8 — bottom sheet with 3 plans, CTA, restore, legal links.

**Inputs:** PRD §8; `EntitlementManager`; `PurchaseService`; `ux-ui-principles.md`

**Deliverable:**
- `HabitTracker/Views/PaywallView.swift`
- `HabitTracker/ViewModels/PaywallViewModel.swift`
- Localized strings in String Catalog (English first; keys for 12 languages)

**Agent prompt:**
```
Build PaywallView for Ringhabit freemium per PRD §8.

UI requirements:
- .sheet with presentationDetents([.medium, .large]), default .large, drag indicator visible
- Title: "Unlock unlimited habits"; subtitle: "You've reached the free limit of 2 habits."
- 3 radio-style plan rows: Yearly (default, "Best value" badge), Monthly, Lifetime
- Prices from Product.displayPrice (StoreKit), not hardcoded
- Full-width Continue button at bottom; label varies by plan (Subscribe / Buy lifetime)
- Footer: Restore Purchases, Terms + Privacy links, auto-renew disclaimer (monthly/yearly only)
- Close button top-trailing (xmark, 44pt)
- Loading spinner on Continue; disable plan selector during purchase
- Success: dismiss sheet; Failure: alert with reason
- Accessibility: VoiceOver labels, 44pt targets, Dynamic Type support
- Reduce Motion: instant transitions

PaywallViewModel calls PurchaseService + EntitlementManager.
Match TaskListView/AppSettingsView patterns (semantic colors, SF Pro, 16pt padding).
Add accessibility identifiers for UI tests (e.g. paywallContinue, paywallRestore, planYearly).
```

**Existing tests that must pass:** All existing UI tests (paywall not shown yet).

**New tests to implement:**
- `PaywallViewModelTests`: default plan is yearly
- `PaywallViewModelTests`: purchase success sets isPremium
- `PaywallViewModelTests`: purchase cancelled shows error
- UI: `testPaywall_ShowsThreePlans` (with launch argument to force paywall)

---

## Phase 3 — Habit gating & subscription lapse

### Step 3.1 — Gate habit creation at 2 habits

**Objective:** Intercept `+` button; show paywall when `habitCount >= 2` and `!isPremium`.

**Inputs:** PRD §7; `TaskListView.swift`; `TaskListViewModel.swift`; `PaywallView`

**Deliverable:** Updated `TaskListView` / `TaskListViewModel` with paywall gating; chained sheet to `NewTaskSelectorView` on success

**Agent prompt:**
```
Integrate freemium gating into TaskListView per PRD §7.

Logic:
- freeHabitLimit = 2
- When user taps + and tasks.count >= 2 and !entitlementManager.isPremium → show PaywallView sheet
- When user taps + and (tasks.count < 2 or isPremium) → show NewTaskSelectorView (existing behavior)
- Delete habit then add new one while at 2 habits: still free, no paywall (PRD §7)
- On successful purchase: dismiss paywall, then present NewTaskSelectorView via onDismiss (no stacked sheets)

Inject EntitlementManager into TaskListViewModel.
Add --uitesting launch flag support to bypass paywall or force premium state for tests.
```

**Existing tests that must pass:**
- `testTaskList_AddButtonOpensSelector` (must still pass for users with <2 habits or premium)
- `testTaskConfiguration_SaveTask`
- All other existing UI tests

**New tests to implement:**
- `testPaywall_AppearsOnThirdHabitAttempt` — create 2 habits, tap +, paywall visible
- `testPaywall_DismissReturnsToTaskList` — close paywall, still 2 habits
- `testFreeTier_DeleteAndReadd_NoPaywall` — delete one habit, add another, no paywall
- `testPremiumUser_AddButtonOpensSelector` — premium user with 2+ habits, + opens selector

---

### Step 3.2 — Expired subscription greyed habits

**Objective:** When subscription lapses, habits 1–2 (oldest by `createdAt`) stay active; habits 3+ greyed; tap opens paywall.

**Inputs:** PRD §7, §8; `TaskCircleView.swift`; `TapAndHoldTaskView.swift`

**Deliverable:** `HabitAccessPolicy` helper; greyed state in task grid; paywall on greyed tap

**Agent prompt:**
```
Implement expired-subscription UX per PRD §7 and §8.

Rules:
- isPremium via subscription OR lifetime
- When !isPremium and tasks.count > 2:
  - Sort tasks by createdAt ascending
  - First 2: full interaction (complete, edit, delete)
  - Rest: greyed (~50% opacity), no completion ring, tap opens PaywallView
- Lifetime users (purchased or legacy-mapped): never greyed, never paywalled

Create HabitTracker/Services/HabitAccessPolicy.swift with:
  func isAccessible(task: HabitTask, allTasks: [HabitTask], isPremium: Bool) -> Bool
  func isGreyedOut(task: HabitTask, ...) -> Bool

Update TaskCircleView / TapAndHoldTaskView to respect policy.
Use icon/state change in addition to opacity (accessibility).
Add unit tests for HabitAccessPolicy edge cases (exactly 2, 3, 5 habits; premium bypass).
```

**Existing tests that must pass:** All tap-and-hold and task list UI tests for accessible habits.

**New tests to implement:**
- `HabitAccessPolicyTests`: first 2 by createdAt accessible when not premium
- `HabitAccessPolicyTests`: 3rd+ not accessible when not premium
- `HabitAccessPolicyTests`: all accessible when premium
- UI: `testExpiredSub_GreyedHabitOpensPaywall`

---

## Phase 4 — Settings, analytics, localization

### Step 4.1 — Settings: Restore & Manage Subscription

**Objective:** Add purchase management rows to `AppSettingsView`.

**Inputs:** PRD §7, §8; `AppSettingsView.swift`

**Deliverable:** Restore Purchases + Manage Subscription in support section; restore triggers `EntitlementManager.restore()`

**Agent prompt:**
```
Add to AppSettingsView support section (PRD §7, §8):
- "Restore Purchases" row → calls EntitlementManager.restore(), shows success/failure alert
- "Manage Subscription" row → opens https://apps.apple.com/account/subscriptions or StoreKit manage subscriptions
Match existing Form section style in AppSettingsView.
Localize new strings.
Add UI test: testSettings_RestorePurchasesExists, testSettings_ManageSubscriptionExists.
```

**Existing tests that must pass:** `testSettings_SectionsExist`

**New tests to implement:**
- `testSettings_RestorePurchasesExists`
- `testSettings_ManageSubscriptionExists`

---

### Step 4.2 — AnalyticsService (TelemetryDeck or no-op)

**Objective:** Fire PRD §9 events for paywall funnel measurement.

**Inputs:** PRD §5, §9

**Deliverable:** `AnalyticsService` protocol + `TelemetryDeckAnalyticsService` (or `NoOpAnalyticsService` for offline); calls in PaywallViewModel, EntitlementManager

**Agent prompt:**
```
Implement analytics per PRD §9.

Events: paywall_shown, plan_selected, purchase_started, purchase_completed, purchase_failed,
        restore_tapped, restore_success, restore_failed, legacy_premium_detected

Create:
- HabitTracker/Services/AnalyticsService.swift (protocol + NoOp implementation)
- Optional: TelemetryDeck via SPM (privacy-friendly, anonymous) — gate behind compile flag or config

Fire events from PaywallViewModel and EntitlementManager only (single responsibility).
Properties: plan name, source (add_habit, greyed_habit, settings), error reason — no PII, no habit data.
Update privacy policy note in docs (analytics section) — do not edit live URL.
Add unit test verifying events fire on mock analytics.
```

**Existing tests that must pass:** All existing tests.

**New tests to implement:**
- `AnalyticsServiceTests`: paywall_shown fired when paywall appears
- `AnalyticsServiceTests`: purchase_completed fired on success

---

### Step 4.3 — Localization (12 languages)

**Objective:** All paywall and premium strings in String Catalog.

**Inputs:** PRD §7; existing `LanguageManager` / String Catalog setup

**Deliverable:** Localized paywall strings for all 12 supported languages

**Agent prompt:**
```
Localize all freemium strings per PRD §7:
- Paywall title, subtitle, plan labels, CTA variants, restore, legal disclaimer
- Settings: Restore Purchases, Manage Subscription
- Error alerts: purchase failed, restore failed, restore success
- Use Xcode String Catalog; follow existing localization pattern in the project
Do not hardcode prices — use Product.displayPrice from StoreKit.
Verify existing 12 languages from ux-ui-principles.md / Feature injection - Multi language.md.
```

**Existing tests that must pass:** All tests.

**New tests to implement:** None (manual QA per language optional).

---

## Phase 5 — App Store & legal surface

### Step 5.1 — Update metadata, review notes, privacy

**Objective:** Align App Store listing and legal docs with freemium model.

**Inputs:** PRD §7 App Store checklist

**Deliverable:** Updated `docs/app-store-connect-metadata.md`, `docs/app-store-review-notes.md`; privacy policy update (external)

**Agent prompt:**
```
Update release documentation per PRD §7 App Store & legal surface checklist:

1. docs/app-store-connect-metadata.md — replace "no subscription" copy; add freemium pricing
2. docs/app-store-review-notes.md — add Sandbox steps: create 3rd habit, test 3 plans, restore legacy buyer
3. Sync Vault copies if they exist at Vault/Product/Ring habit/
4. Document App Privacy label changes needed (analytics if TelemetryDeck added)
5. Age rating: note re-completion for IAP

Do not change live privacy policy URL content — provide draft text for manual publish.
```

**Existing tests that must pass:** All tests.

**New tests to implement:** None.

---

### Step 5.2 — Optional migration release

**Objective:** Ship StoreKit + legacy detection while app is still €0.99 paid (PRD §10).

**Inputs:** PRD §10 release sequence

**Deliverable:** Release build with EntitlementManager only (no paywall gating); caches legacy premium

**Agent prompt:**
```
Prepare optional migration release per PRD §10:
- Ship EntitlementManager + legacy paid-app detection in a build that is STILL €0.99 paid download
- No paywall, no habit limit — all users keep unlimited habits
- Cache hasLifetimePurchase for paid-app owners locally
- This de-risks freemium launch for users who skip intermediate update
Document in docs/Implementation-Plan-Freemium.md whether this release was shipped or skipped.
```

**Existing tests that must pass:** All tests.

**New tests to implement:** `EntitlementManagerTests`: migration cache persists across launches

---

## Phase 6 — QA, Sandbox verification & submission

### Step 6.1 — Sandbox test matrix

**Objective:** Execute PRD §10 pre-launch verification checklist.

**Inputs:** PRD §10; Sandbox Apple IDs

**Deliverable:** Completed test matrix (pass/fail) documented in `docs/freemium-sandbox-test-results.md`

**Agent prompt:**
```
Create and execute Sandbox test matrix per PRD §10:

Accounts needed:
1. Legacy paid-app buyer (purchased €0.99 before freemium)
2. Fresh account (no purchase)
3. Accounts for monthly, yearly, lifetime purchase each

Verify:
- Legacy: auto premium on launch, >2 habits, no paywall, restore works
- Free: 2 habits OK, paywall on 3rd, all 3 plans purchasable
- Each plan grants unlimited habits
- Expired sub: greyed habits behavior
- Legacy user NOT prompted for €15 lifetime

Document results in docs/freemium-sandbox-test-results.md.
File bugs for any failure before submission.
```

**Existing tests that must pass:** Full `HabitTrackerTests` + `HabitTrackerUITests` suites green in CI.

**New tests to implement:** Any gaps found in Sandbox → add XCUITest before submission.

---

### Step 6.2 — App Review submission

**Objective:** Submit freemium build with free download pricing.

**Inputs:** PRD §10; updated review notes; Sandbox credentials

**Deliverable:** App submitted; App Store Connect pricing = free; IAP products attached

**Agent prompt:**
```
Prepare App Review submission for freemium release:
1. Set app price to Free in App Store Connect
2. Attach subscription group + lifetime IAP to build
3. Paste review notes from docs/app-store-review-notes.md
4. Include Sandbox test account credentials for legacy buyer + new user
5. Verify paywall shows Terms, Privacy, auto-renew disclosure
6. Confirm Manage Subscription in Settings works
Run full regression: all unit + UI tests pass; manual smoke on device.
```

**Existing tests that must pass:** Entire test suite; crash-free smoke on iOS 17+ device.

**New tests to implement:** None if Phase 6.1 matrix is green.

---

## Regression gate — existing tests (all phases)

Every phase must keep these passing:

### Unit tests (`HabitTrackerTests`)
- Enum round-trips (MeasurementDuration, GoalType, FrequencyType, etc.)
- PresetTaskCatalog (28 entries, categories)
- HabitTask defaults and scheduling
- StatisticsService (completionCount, trendData, percentages)
- ColorPalette / TaskColor

### UI tests (`HabitTrackerUITests`)
- `testOnboarding_WelcomeScreenAppears`, `testOnboarding_SkipButton`
- `testTaskList_EmptyState`, `testTaskList_AddButtonExists`, `testTaskList_SettingsButtonExists`
- `testTaskList_AddButtonOpensSelector`, `testTaskList_SettingsOpens`
- `testNewTaskSelector_CustomTaskInput`, `testNewTaskSelector_CategoryTabs`, `testNewTaskSelector_PresetNavigatesToConfig`
- `testTaskConfiguration_SaveTask`, `testTaskMenu_ContextMenuOptions`
- `testSettings_SectionsExist`

---

## New tests summary (to implement across phases)

| Test | Type | Phase |
|------|------|-------|
| EntitlementManager entitlement states | Unit | 1.1 |
| Legacy paid-app mapping | Unit | 1.1 |
| PurchaseService product loading | Unit | 1.1 |
| AppSettings premium cache | Unit | 1.2 |
| PaywallViewModel plan/purchase | Unit | 2.1 |
| HabitAccessPolicy rules | Unit | 3.2 |
| Analytics event firing | Unit | 4.2 |
| Paywall shows 3 plans | UI | 2.1 |
| Paywall on 3rd habit | UI | 3.1 |
| Free tier delete/re-add | UI | 3.1 |
| Premium user bypasses paywall | UI | 3.1 |
| Greyed habit opens paywall | UI | 3.2 |
| Settings restore/manage rows | UI | 4.1 |

---

## Risks & dependencies

| Risk | Mitigation |
|------|------------|
| Legacy paid-app detection unreliable | Phase 0.2 Sandbox + optional migration release (5.2) |
| App Review rejection on subscriptions | §7 legal checklist; review notes with Sandbox steps |
| Stacked sheets UX bug | PRD §8 chained sheet via onDismiss |
| No analytics without SDK | TelemetryDeck in 4.2 or ASC-only metrics for v1 |
| Product ID mismatch ASC ↔ code | Single source in `ProductIDs.swift` + StoreKit config |

---

## Appendix

- **PRD:** `Vault/Product/Ring habit/PRD - Freemium.md`
- **UX:** `docs/ux-ui-principles.md`, PRD §8
- **Stack:** `docs/tech-stack.md`, PRD §9
- **Data:** `docs/data-model.md`
- **Existing AC:** `docs/acceptance-criteria.md`
- **Key files to modify:** `TaskListView.swift`, `TaskListViewModel.swift`, `AppSettingsView.swift`, `HabitTrackerApp.swift`, `TaskCircleView.swift`
