# Implementation Plan — Habit Strength

> Multi-agent delivery plan derived from [PRD - Habit strength.md](/Users/maurizio.bellini/Documents/Vault/Product/Ring%20habit/PRD%20-%20Habit%20strength.md) and supporting project docs.

**Feature:** Introduce a science-inspired **Habit Strength** score (0–100) and **Habit Stage** (Starting → Mastering) per habit, surfaced on the dashboard rings and in a new habit summary bottom sheet, with stage-advance celebrations and proximity/reversion push notifications.

**Target repo:** `habit-tracker` (bundle ID `co.fooshi.habitring`)

**Status:** Draft
**Date:** 2026-08-21
**Baseline commit:** `f1ae7ea` (Stats tap for data point)

---

## Input document validation

| Document | Path | Status |
|----------|------|--------|
| Feature PRD (Habit strength) | `Vault/Product/Ring habit/PRD - Habit strength.md` | Provided |
| UX plan | `docs/ux-ui-principles.md` + PRD §9 (Version A hero ring, mock in `Vault/.../assets/`) | Available |
| Technical stack plan | `docs/tech-stack.md` + PRD §10 | Available |
| Data plan | `docs/data-model.md` | Available — **stale**, predates freemium and weekly/monthly counter work; update in Phase 0 |
| Acceptance criteria | `docs/acceptance-criteria.md` (product-wide) | Available — no habit-strength scenarios yet; create in Phase 0 |
| Formula simulations | [Google Sheet](https://docs.google.com/spreadsheets/d/1d6gvLQQTBwK8fZ9HuooRtfFAAaHcF6jQNvjG-jirNsc/edit?gid=0#gid=0) | External — **not verifiable from repo**; treat PRD §7 worked example (73) as the contract |
| Drive-hosted specs | Google Drive (per `.cursor/rules/drive-specs.mdc`) | **Not retrieved** — gdrive MCP connection is in an error state. Re-check Drive before Phase 1 in case a newer spec revision exists there. |

**Blocking gaps:** none. Two documentation deliverables (acceptance criteria, refreshed data model) are folded into Phase 0.

---

## Corrections to PRD §10 found in the codebase

The PRD's technical section is accurate in intent but a few details differ from the current code. Agents must follow this table, not the PRD, where they conflict.

| PRD §10 claim | Actual code | Consequence for the plan |
|---|---|---|
| `.topLeading` is the only free overlay alignment on `TaskCircleView` | The lock (`.topTrailing`) and hold ring (`.top`) overlays live in **`TapAndHoldTaskView`**, not `TaskCircleView`. `TaskCircleView` only uses `.bottomTrailing` (counter badge). | The stage badge is added as a `.topLeading` overlay in **`TapAndHoldTaskView`**, so all badges stay in one place. The inner strength ring goes inside `TaskCircleView`'s `ZStack`. |
| Reuse "existing `confirmDelete` plumbing" | `confirmDelete(_:)` is a *method* on `TaskListViewModel`; the flags are `taskToDelete` + `showDeleteConfirmation`. There is no `confirmDelete` property. | Bottom-sheet actions call `viewModel.confirmDelete(task)` and set `taskToEdit` / `taskForStats`. |
| Unit tests live "alongside `HabitTrackerTests.swift`" | `HabitTrackerTests/` uses **Swift Testing** (`import Testing`, `@Suite`, `@Test`, `#expect`). `HabitTrackerUITests/` uses **XCTest**. | All new unit tests use Swift Testing suites; all new UI tests use XCTest with `--uitesting*` launch arguments. |
| Onboarding hold duration needs a separate change | `OnboardingView` calls `TapAndHoldTaskView` without overriding `holdDuration`, so it inherits the `2.0` default. | Changing the single constant to `1.4` satisfies both surfaces; no second edit needed. |
| Settings section is "premium" | Section title is literally `"Premium"`; the free-plan row is a plain non-tappable `HStack`. | Rename to `"Your plan"` (PRD's "You plan" is a typo) and wrap the row in a `Button`. |
| — | `HabitTask.trackingRaw` is the **only** `*Raw` property; no enum in `Enums.swift` conforms to `Comparable`. | `HabitStage: Comparable` must be written explicitly; two new `*Raw` properties follow the documented pattern. |
| — | Localization keys are the **English source string itself** (e.g. `"Congratulations!" = "Congratulations!";`), 223 lines in each of 7 files. | New keys must use English copy as the key, added to all 7 files at identical positions. |
| — | `FirstCompletionCelebrationView` already implements "celebration + reminder opt-in with DatePicker". | The stage celebration reuses this component's structure rather than inventing a new opt-in pattern. |

---

## Semantic rulings (locked before implementation)

These resolve the ambiguities the PRD flags in §10.7. Agents must not re-litigate them.

| # | Question | Ruling |
|---|---|---|
| 1 | Credited or raw completions for **N** and **C**? | **Credited** — `StatisticsService.completionCount`. A daily habit with `timesPerPeriod = 3` earns one repetition per day (forced to `periodComplete` by `PeriodService.effectiveTracking`); a weekly `eachCompletion` habit earns one per session. |
| 2 | Grid highlighting metric | **Raw presence** — a day is highlighted if at least one `TaskCompletion` row falls in it, regardless of period credit. |
| 3 | Eligibility gate metric | Same credited **N** used in the formula, so the ring never unlocks against a different denominator. |
| 4 | Consistency window length | `max(28 days, 3 periods)`. Daily/weekly/specificDays → 28 days. Monthly → ~3 calendar months. |
| 5 | Window anchoring | Window ends at `endOfToday` and is clamped at its start to `task.createdAt`, so a 5-day-old habit is not punished for 23 non-existent opportunities. `C = 0` when the clamped window has zero expected opportunities. |
| 6 | Backfilled completions | Count toward both N and C. Strength is therefore retroactively mutable — reinforces never persisting the score. |
| 7 | Rounding | `Int(round(rawScore))`, half away from zero, then clamped to `0...100`. Stage is mapped from the **rounded** integer so the displayed number and the label can never disagree. |
| 8 | Analytics score type | Widen the protocol to `[String: Any]` (PRD §11 option 1) so `strength_score` aggregates numerically in PostHog. |
| 9 | §11 review prompt trigger | Fire when **total credited completions across all habits reaches 3**, guarded by `AppSettings.hasRequestedAppReview`. |
| 10 | Hold duration | `2.0s → 1.4s` (30% faster). `LongPressGesture(minimumDuration: 0.15)` stays unchanged. |

---

## Delivery phases overview

| Phase | Focus | Agent role |
|-------|-------|-----------|
| 0 | Documentation & decisions | Product / Docs |
| 1 | Domain model & schema | iOS / SwiftData |
| 2 | Strength engine & cache | iOS / Domain |
| 3 | Backfill & daily evaluator | iOS / SwiftData |
| 4 | Dashboard ring & stage badge | iOS / SwiftUI |
| 5 | Habit summary bottom sheet | iOS / SwiftUI |
| 6 | Stage celebration | iOS / SwiftUI |
| 7 | Proximity notifications | iOS / Notifications |
| 8 | Analytics | iOS |
| 9 | Localization | iOS / Localization |
| 10 | PRD §11 minor changes | iOS / SwiftUI |
| 11 | QA, performance, release | QA / Release |

**Critical path:** 1 → 2 → 3 → (4, 5 parallel) → 6 → 7. Phases 8, 9, 10 can run in parallel with 4–7. Phase 11 gates the release.

---

## Phase 0 — Documentation & decisions

### Step 0.1 — Habit strength acceptance criteria

**Objective:** Turn PRD §8 and §9 into testable Given/When/Then scenarios so Phases 1–11 have a shared definition of done.

**Inputs / dependencies:** PRD §7, §8, §9, §11; `docs/acceptance-criteria.md` (format reference); the rulings table above.

**Deliverable:** `docs/acceptance-criteria-habit-strength.md`

**Agent prompt:**
```
You are a product analyst. Read:
- /Users/maurizio.bellini/Documents/Vault/Product/Ring habit/PRD - Habit strength.md
- docs/acceptance-criteria.md (format reference — match its Gherkin style and heading structure)
- docs/Implementation-Plan-Habit-Strength.md sections "Corrections to PRD §10" and "Semantic rulings"

Produce docs/acceptance-criteria-habit-strength.md with Given/When/Then scenarios covering:
1. Score computation: the PRD §7 worked example (40 total credited, 24 of 28 → 73); rounding at .5 boundaries; clamping at 0 and 100.
2. Eligibility gate at exactly 2 and exactly 3 credited completions.
3. Stage boundaries 19/20, 39/40, 59/60, 79/80, 94/95.
4. Reversion: score dropping across a boundary lowers the stage.
5. Frequency variants: daily timesPerPeriod=3, weekly eachCompletion 3x/week, specificDays Mon/Wed/Fri (12 expected opportunities per 28 days), monthly (widened window).
6. New habit younger than the window (window clamped to createdAt).
7. Bottom sheet: opens on single tap, replaces the confirmation dialog, all six elements present, greyed ring under 3 completions, Stats/Edit/Remove still work.
8. Daily grid: 25x7, today bottom-right, scroll back and forward limits, raw-presence highlighting, tap opens manage completions.
9. Dashboard: inner strength ring, stage badge shown from Developing upward only, prominence change from Strong upward.
10. Celebration: shown once per stage advance, notification opt-in only when the habit has notifications off, no celebration on reversion.
11. Notifications: proximity fires only when a completion today crosses a boundary upward; reversion only when a miss crosses one downward; 09:00 local; Mark done / Later actions; cancelled on habit delete.
12. Upgrade backfill: zero celebrations fired on first launch after update.
13. PRD §11 items: review prompt at 3 total completions (once only), dashboard subtitle, faster hold, clickable free-plan row.

Documentation only — do not write or modify any Swift code.
```

**Existing tests that must pass:** All suites in `HabitTrackerTests/` and all classes in `HabitTrackerUITests/` (documentation change, so this is a no-regression check only).

**New tests to implement:** None.

---

### Step 0.2 — Refresh the data model document

**Objective:** `docs/data-model.md` predates the freemium and weekly/monthly work and would mislead every downstream agent. Bring it to the current schema and add the Habit Strength additions.

**Inputs / dependencies:** `docs/data-model.md`; `HabitTracker/Models/*.swift`; `HabitTracker/HabitTrackerApp.swift` (`makeModelContainer`); PRD §10.

**Deliverable:** Updated `docs/data-model.md` with a "Habit Strength" section.

**Agent prompt:**
```
Update docs/data-model.md to match the current SwiftData schema in habit-tracker.

1. Read HabitTracker/HabitTrackerApp.swift (makeModelContainer) and all files in HabitTracker/Models/.
2. Correct any drift: HabitTask.timesPerPeriod uses @Attribute(originalName: "timesPerDay"); HabitTask.trackingRaw/tracking is the optional-enum pattern; AppSettings has cachedIsPremium, lastEntitlementCheckAt, hasSeenFirstCompletionPrompt.
3. Add a "Habit Strength" section documenting the planned additions:
   - enum HabitStage (starting, developing, building, strong, established, mastering) with Comparable
   - struct HabitStrength (non-persisted value type)
   - HabitTask: lastObservedStageRaw, lastCelebratedStageRaw, lastCelebratedAt, strengthEvaluatedAt (all optional)
   - AppSettings: hasSeededHabitStrength, hasRequestedAppReview (both Bool, default false)
4. State explicitly that the score and stage are DERIVED and never persisted, and explain why (editing past completions via ManageCompletionsView would leave a stored score stale).
5. Document that SwiftData lightweight migration suffices (no VersionedSchema, no CloudKit) and that a behavioural backfill runs in MigrationService.

Documentation only — do not modify Swift code.
```

**Existing tests that must pass:** All existing unit and UI tests (no-regression check).

**New tests to implement:** None.

---

## Phase 1 — Domain model & schema

### Step 1.1 — `HabitStage` enum and stage mapping

**Objective:** Add the stage type with an explicit ordering and a pure score→stage mapping.

**Inputs / dependencies:** PRD §7 mapping table, §8 stage rules; `HabitTracker/Models/Enums.swift`.

**Deliverable:** `HabitStage` added to `HabitTracker/Models/Enums.swift`.

**Agent prompt:**
```
In habit-tracker, add a HabitStage enum to HabitTracker/Models/Enums.swift, matching the style of the existing enums there (String raw value, Codable, CaseIterable, Identifiable, a localizable displayName computed property).

enum HabitStage: String, Codable, CaseIterable, Identifiable, Comparable {
    case starting, developing, building, strong, established, mastering
}

Requirements:
- No existing enum in this file conforms to Comparable, so implement `static func < (lhs:rhs:)` explicitly using the allCases index. Add a private `sortIndex` computed property rather than calling firstIndex(of:) on every comparison.
- Add `static func stage(forScore score: Int) -> HabitStage` implementing the PRD §7 table exactly:
  0-19 starting, 20-39 developing, 40-59 building, 60-79 strong, 80-94 established, 95-100 mastering.
  Clamp inputs outside 0...100.
- Add `var sfSymbolName: String` returning: starting=circle.dotted, developing=leaf, building=leaf.fill, strong=flame.fill, established=checkmark.seal.fill, mastering=crown.fill.
- Add `var isProminentBadge: Bool` — true for strong, established, mastering (PRD §8 display rules).
- Add `var showsDashboardBadge: Bool` — false for starting, true otherwise.
- Add `var displayName: LocalizedStringKey` (or String via NSLocalizedString, matching how the other enums in this file localize) using English source strings as keys: "Starting", "Developing", "Building", "Strong", "Established", "Mastering".

Do not touch HabitTask or any service yet. Add no UI.
```

**Existing tests that must pass:** All suites in `HabitTrackerTests/HabitTrackerTests.swift` and `FreemiumTests.swift`.

**New tests to implement (Swift Testing, `HabitTrackerTests/HabitStrengthTests.swift`):**
- `stage(forScore:)` at every boundary pair: 0, 19, 20, 39, 40, 59, 60, 79, 80, 94, 95, 100.
- Out-of-range clamping: `-5 → .starting`, `120 → .mastering`.
- `Comparable`: `.starting < .developing < .building < .strong < .established < .mastering`; equality reflexive.
- `showsDashboardBadge` false only for `.starting`; `isProminentBadge` true only for the top three.
- Round-trip `HabitStage(rawValue:)` for every case (guards against a raw-value typo breaking persistence).

---

### Step 1.2 — `HabitTask` and `AppSettings` schema additions

**Objective:** Add the transition-bookkeeping fields, using the crash-safe optional-enum pattern.

**Inputs / dependencies:** Step 1.1; PRD §10.3, §10.4; `HabitTracker/Models/HabitTask.swift`, `AppSettings.swift`.

**Deliverable:** Updated `HabitTask.swift` and `AppSettings.swift`.

**Agent prompt:**
```
In habit-tracker, add stage-transition bookkeeping fields.

HabitTracker/Models/HabitTask.swift — add:
| Stored | Type | Purpose |
| lastObservedStageRaw | HabitStage? (private) | stage at last daily evaluation |
| lastCelebratedStageRaw | HabitStage? (private) | highest stage already celebrated |
| lastCelebratedAt | Date? | cooldown guard |
| strengthEvaluatedAt | Date? | idempotency for the daily job |

CRITICAL: enum-typed stored properties MUST be optional with a computed accessor, exactly mirroring the existing trackingRaw/tracking pattern in this same file (read it first, including its comment explaining that legacy rows decode as nil and a non-optional enum crashes on a force-cast of Optional<Any>). Expose:
    var lastObservedStage: HabitStage? { get { lastObservedStageRaw } set { lastObservedStageRaw = newValue } }
    var lastCelebratedStage: HabitStage? { get { lastCelebratedStageRaw } set { lastCelebratedStageRaw = newValue } }
These two stay OPTIONAL at the accessor level too — nil is meaningful (never evaluated), distinct from .starting. Add a short comment saying so.

Do NOT add these to the initializer's required parameters; give them default nil so all existing call sites compile untouched.

HabitTracker/Models/AppSettings.swift — add:
- var hasSeededHabitStrength: Bool = false
- var hasRequestedAppReview: Bool = false
Follow the existing hasSeenFirstCompletionPrompt style and add both to the initializer with defaults.

Do NOT store the score or the stage itself — both are derived. Do not add computation logic in this step.
Verify the schema in HabitTrackerApp.makeModelContainer needs no change (no new @Model types), and confirm this is a SwiftData lightweight migration (new optional properties / properties with defaults).
```

**Existing tests that must pass:** All existing unit tests, plus the UI tests — a schema mistake here surfaces as a launch crash, so run `HabitTrackerUITests` in full.

**New tests to implement:**
- In-memory `ModelContainer` round-trip: create a `HabitTask`, save, refetch, assert `lastObservedStage == nil` and `strengthEvaluatedAt == nil` (proves the nil-decode path does not crash).
- Set `lastObservedStage = .strong`, save, refetch, assert value survives.
- `AppSettings` defaults: `hasSeededHabitStrength == false`, `hasRequestedAppReview == false`.
- Existing-row simulation: decode a task with the new columns unset and read every new accessor without a trap.

---

## Phase 2 — Strength engine & cache

### Step 2.1 — `HabitStrengthService`

**Objective:** Implement the PRD §7 formula on top of the existing statistics engine, with no re-implementation of completion counting.

**Inputs / dependencies:** Steps 1.1, 1.2; PRD §7, §8, §10.6, §10.7; `StatisticsService.swift`, `PeriodService.swift`.

**Deliverable:** `HabitTracker/Services/HabitStrengthService.swift` and the `HabitStrength` value type.

**Agent prompt:**
```
Create HabitTracker/Services/HabitStrengthService.swift in habit-tracker.

Read HabitTracker/Services/StatisticsService.swift and PeriodService.swift first and match their conventions exactly: a stateless `enum` with `static` methods and injectable `calendar: Calendar = .current` and `weekStartDay: Int = 1` parameters. There is a project rule that every surface calls the shared counting engine — do NOT re-implement completion counting.

1. Value type (same file or HabitTracker/Models/HabitStrength.swift — plain struct, NOT a @Model):
   struct HabitStrength: Equatable {
       let score: Int            // 0...100, rounded
       let stage: HabitStage
       let repetition: Double    // R
       let consistency: Double   // C
       let totalCompletions: Int // N (credited)
       let isEligible: Bool      // N >= 3
   }

2. static func strength(for task: HabitTask, on date: Date = .now, calendar: Calendar = .current, weekStartDay: Int = 1) -> HabitStrength

   N = StatisticsService.completionCount(for: task, from: task.createdAt, to: <end of `date`>, weekStartDay:calendar:)
   R = 1 - exp(-Double(N) / 40.0)
   Consistency window: end = end of `date`; start = the later of (a) `date` minus 27 days at start of day and (b) start of the 3rd-most-recent period per PeriodService.periodBounds, and then clamped forward to startOfDay(task.createdAt).
     - Daily / weekly / specificDays: this yields 28 days.
     - Monthly: this widens to roughly 3 calendar months (PRD §10.7c).
     Implement it as a documented helper: static func consistencyWindow(for:endingOn:calendar:weekStartDay:) -> (start: Date, end: Date)
   C numerator   = StatisticsService.completionCount over that window
   C denominator = StatisticsService.expectedCompletions over that window
   C = denominator > 0 ? min(1.0, numerator / denominator) : 0.0
   raw = 100 * (0.55 * R + 0.45 * C)
   score = min(100, max(0, Int(raw.rounded())))     // .toNearestOrAwayFromZero
   isEligible = N >= 3
   stage = isEligible ? HabitStage.stage(forScore: score) : .starting   // PRD §8: under 3 completions the stage is forced to starting

   When !isEligible, still populate score/R/C truthfully — the UI decides to hide the number. Never return a placeholder score like -1.

3. Projection functions for notifications (pure, no model writes):
   static func projectedStrength(for task: HabitTask, assumingCompletionOn date: Date, calendar:weekStartDay:) -> HabitStrength
   static func projectedStrengthAssumingMiss(for task: HabitTask, on date: Date, calendar:weekStartDay:) -> HabitStrength

   Implement these WITHOUT inserting into the model context. Because StatisticsService reads task.completions, the cleanest approach is to compute the counting terms directly from a synthesized array of completion dates rather than mutating the task. Extract the arithmetic into a private pure function taking (N, windowNumerator, windowDenominator) so all three entry points share one formula implementation and cannot drift.
   For the completion projection, respect PeriodService.canAcceptCompletion — if today's period is already at quota, a further completion adds no credit, so the projection must equal the current strength.
   For the miss projection, model "today ends with no additional completion": N unchanged, and the window advanced by one day so today's opportunity is counted in the denominator but not the numerator.

4. Doc comment at the top citing PRD §7 and the Lally scaling factor of 40 (~80 at 60 repetitions).

Do not add caching, UI, notifications, or analytics in this step.
```

**Existing tests that must pass:** All suites in `HabitTrackerTests/` — especially the `PeriodService` and streak suites, since this step must not modify them.

**New tests to implement (Swift Testing, extending `HabitStrengthTests.swift`):**
- **PRD worked example:** daily habit, 40 credited completions, 24 of the last 28 days → `score == 73`, `R ≈ 0.632`, `C ≈ 0.857` (tolerance 0.001).
- Eligibility gate: exactly 2 credited → `isEligible == false`, `stage == .starting`; exactly 3 → `isEligible == true`.
- Stage forced to `.starting` at N = 2 even when the raw score maps higher.
- `C` capped at 1.0 when the numerator exceeds the denominator (backfilled extra completions).
- `C == 0` and no crash when the denominator is 0 (habit created today, unscheduled window).
- Window clamping: habit created 5 days ago → denominator counts 5 opportunities, not 28.
- Monthly habit: window widens to ≥ 3 periods; assert the denominator is ≥ 3 and the score does not jump by more than a documented delta from one completion.
- `specificDays` Mon/Wed/Fri: 28-day window yields 12 expected opportunities.
- Daily habit with `timesPerPeriod = 3`: three completions in one day credit **1** toward N (proves credited, not raw).
- Weekly `eachCompletion` habit, 3 sessions/week: each session credits 1 toward N.
- Rounding: construct inputs landing on x.5 and assert half-away-from-zero; assert clamping at 0 and 100.
- `projectedStrength(assumingCompletionOn:)` ≥ current strength; equals current strength when `canAcceptCompletion` is false.
- `projectedStrengthAssumingMiss` ≤ current strength.
- Determinism: two calls with the same inputs return identical values.

---

### Step 2.2 — In-memory strength cache

**Objective:** Prevent recomputation on every SwiftUI body pass, since the dashboard renders every habit and N walks the full history.

**Inputs / dependencies:** Step 2.1; PRD §10.8; `HabitTrackerApp.swift` (environment injection pattern used for `analyticsService` / `EntitlementManager`).

**Deliverable:** `HabitTracker/Services/HabitStrengthCache.swift`, injected via the SwiftUI environment.

**Agent prompt:**
```
Add HabitTracker/Services/HabitStrengthCache.swift to habit-tracker.

Purpose (PRD §10.8): computing strength walks every period since task.createdAt, and the dashboard renders every habit, so a naive implementation recomputes on every body pass.

Requirements:
- @Observable @MainActor final class HabitStrengthCache
- Storage: [CacheKey: HabitStrength] where CacheKey is Hashable over (taskID: UUID, day: Date) with `day` = calendar.startOfDay. Strength changes at most once per day for a fixed completion set, so the day is part of the key.
- func strength(for task: HabitTask, on date: Date = .now, weekStartDay: Int) -> HabitStrength — cache hit returns stored value; miss delegates to HabitStrengthService.strength and stores.
- func invalidate(taskID: UUID) — called when a completion is inserted or deleted, or the habit's frequency/tracking is edited.
- func invalidateAll() — called on app foreground (date may have rolled over) and after the migration backfill.
- Cap the dictionary size or prune entries whose `day` is not today, so scrolling long histories cannot grow it without bound.
- Inject exactly like the existing analyticsService environment key in HabitTrackerApp.swift: define an EnvironmentKey, extend EnvironmentValues, and attach with .environment(...) at the root. Views consume it with @Environment.

Then wire invalidation into every existing write path — find them by searching for `TaskCompletion(` insertions and `modelContext.delete`:
- TaskListViewModel completion insert (tap and hold)
- ManageCompletionsView insert and delete
- TaskConfigurationViewModel save, when frequencyType, timesPerPeriod, tracking, or scheduledDays changed
- habit delete

Cache only. Do not change the formula.
```

**Existing tests that must pass:** All existing unit tests; `HabitTrackerUITests` completion flows (`testTaskCircle_*`, tap-and-hold scenarios) to prove invalidation does not stall the UI.

**New tests to implement:**
- Cache hit returns the identical value as a direct `HabitStrengthService` call.
- `invalidate(taskID:)` forces recomputation and picks up a newly inserted completion.
- Same-day repeated reads compute once (assert via an injected counting spy or a test hook).
- Two tasks do not collide in the cache.
- Key changes across a day boundary → recompute.
- Pruning: entries for stale days are evicted.

---

## Phase 3 — Backfill & daily evaluator

### Step 3.1 — Upgrade backfill in `MigrationService`

**Objective:** Seed the transition baseline for existing habits so no user is hit by a barrage of celebrations on upgrade.

**Inputs / dependencies:** Phases 1–2; PRD §10.5; `MigrationService.swift`, `ContentView.swift`.

**Deliverable:** New backfill step in `MigrationService.normalizeIfNeeded`.

**Agent prompt:**
```
Extend HabitTracker/Services/MigrationService.swift in habit-tracker.

Read the existing normalizeIfNeeded first — it is @MainActor, takes a ModelContext, is invoked synchronously from ContentView.onAppear before seeding, and currently only migrates .everyWeek -> .weekly.

Add a habit-strength backfill, keeping the existing behaviour intact:
1. Read AppSettings.shared(in: context). If hasSeededHabitStrength is true, return immediately (one-shot).
2. For every HabitTask, compute HabitStrengthService.strength(for:) using AppSettings.weekStartDay, then set:
     task.lastObservedStage  = strength.stage
     task.lastCelebratedStage = strength.stage
     task.strengthEvaluatedAt = .now
   Leave lastCelebratedAt nil.
3. Fire ZERO celebrations and ZERO notifications during backfill. Do not call NotificationService. Do not emit analytics.
4. Set hasSeededHabitStrength = true and save once at the end.
5. Order matters: run the existing .everyWeek normalization BEFORE the backfill, since the frequency type changes the computed stage.

Keep it idempotent and cheap: a user with many habits and long histories must not block launch noticeably. If the loop needs a guard, cap by using the cache and reusing one Calendar instance rather than by skipping habits.
```

**Existing tests that must pass:** The migration suite in `HabitTrackerTests.swift` (`.everyWeek → .weekly` behaviour must be unchanged); all UI tests, since this runs at launch.

**New tests to implement:**
- Backfill on a seeded container sets `lastObservedStage` and `lastCelebratedStage` equal to the computed stage on every task.
- **Zero celebrations:** a task whose computed stage is `.established` produces no pending celebration state after backfill.
- `hasSeededHabitStrength` flips to true; a second call is a no-op (asserted via a mutated field staying mutated).
- A legacy `.everyWeek` habit is normalized *before* its stage is computed (assert the stage matches the weekly interpretation).
- Empty database: no crash, flag still set.

---

### Step 3.2 — Daily stage evaluator

**Objective:** Detect advances and reversions opportunistically, since there is no `BGAppRefreshTask` in the project.

**Inputs / dependencies:** Step 3.1; PRD §8, §10.9.

**Deliverable:** `HabitTracker/Services/HabitStageEvaluator.swift` plus foreground and post-completion hooks.

**Agent prompt:**
```
Create HabitTracker/Services/HabitStageEvaluator.swift in habit-tracker.

There is no BGAppRefreshTask in this project and iOS will not reliably run code at a fixed time, so evaluation is opportunistic (PRD §10.9).

API:
    @MainActor
    enum HabitStageEvaluator {
        struct Transition { let task: HabitTask; let from: HabitStage; let to: HabitStage; var isAdvance: Bool { to > from } }
        static func evaluate(tasks: [HabitTask], context: ModelContext, cache: HabitStrengthCache, weekStartDay: Int, now: Date = .now) -> [Transition]
    }

Behaviour:
- Idempotent per day: skip a task whose strengthEvaluatedAt is already within today (calendar.isDateInToday), UNLESS a `force` flag is passed for the post-completion path, where the same day must be re-evaluated.
- For each task compute the current strength, compare stage against lastObservedStage:
  - nil baseline: seed it, emit no transition (defensive — backfill should have set it).
  - to > from: emit an advance Transition.
  - to < from: emit a reversion Transition.
  - equal: nothing.
- Always update lastObservedStage and strengthEvaluatedAt, then save once for the whole batch.
- Celebration suppression: an advance is only *celebratable* if to > (lastCelebratedStage ?? .starting) AND lastCelebratedAt is not within the last 12 hours. This prevents repeat pop-ups when a score oscillates across a boundary. Expose that as `var isCelebratable: Bool` on Transition (or a separate filter function) — the evaluator itself must NOT present UI.
- Never lower lastCelebratedStage on reversion; it is a high-water mark.

Call sites:
- App foreground (scenePhase .active in HabitTrackerApp or ContentView): cache.invalidateAll(), then evaluate all tasks.
- Immediately after a completion is recorded in TaskListViewModel: invalidate that task and evaluate it with force = true, so the celebration appears in the same session as the completion that earned it.

Return transitions only. Presentation is Phase 6; notification scheduling is Phase 7; analytics is Phase 8.
```

**Existing tests that must pass:** All existing unit and UI tests; particularly the tap-and-hold completion UI tests, which now run the evaluator inline.

**New tests to implement:**
- Advance detected when the stage rises; `isAdvance == true`.
- Reversion detected when the stage falls; `isAdvance == false`.
- No transition when the stage is unchanged.
- Idempotency: a second same-day `evaluate` without `force` returns an empty array.
- `force: true` re-evaluates the same day.
- Oscillation: advance to `.developing`, revert to `.starting`, advance to `.developing` again → the second advance is **not** celebratable.
- Cooldown: two advances within 12 hours → only the first is celebratable.
- `lastCelebratedStage` never decreases across a reversion.
- `lastObservedStage` and `strengthEvaluatedAt` are persisted after evaluation.

---

## Phase 4 — Dashboard ring & stage badge

### Step 4.1 — Inner strength ring in `TaskCircleView`

**Objective:** Add a third ring layer reflecting habit strength.

**Inputs / dependencies:** Phase 2; PRD §8 "Task ring in dashboard", §10.10; `docs/ux-ui-principles.md`.

**Deliverable:** Updated `HabitTracker/Views/TaskCircleView.swift`.

**Agent prompt:**
```
Update HabitTracker/Views/TaskCircleView.swift in habit-tracker to add an inner habit-strength ring.

Read the file first. Its ZStack currently has: (1) a background Circle fill, (2) a border Circle().strokeBorder with lineWidth 2/5/3 by completion state, (3) centerContent. The only overlay it uses is .bottomTrailing for the C/N counter badge. Do not disturb any of that.

Add a NEW inner Circle inset from the border ring:
- Trim from 0 to CGFloat(strength.score) / 100, rotated -90 degrees so it starts at 12 o'clock (match how CompletionRingView draws its arc — read it and reuse the same rotation and lineCap conventions).
- Stroke colour: the habit's accent colour (same source the border ring uses), at a lower opacity than the border so the three rings stay visually distinguishable.
- Thin lineWidth (about 2), inset far enough inside the border ring that it never overlaps at circleSize 80 or the 100 used by OnboardingView.
- Hidden entirely when strength.isEligible is false. Do NOT draw a 0% arc for ineligible habits — an empty ring reads as failure, whereas the PRD wants "not yet available".

Signature: add `strength: HabitStrength?` with a default of nil so existing call sites and previews compile unchanged; nil means draw no inner ring.

Then in TapAndHoldTaskView (which owns the .topTrailing lock and .top hold-ring overlays), pass the strength down from the resolved value at the TaskListView level, reading it from the HabitStrengthCache environment object rather than computing it inside the view body.

Accessibility: extend the existing accessibility label so it appends "Habit strength, {n}" when eligible. Keep the existing accessibility identifiers (taskCircle_*) unchanged — UI tests depend on them.
Respect Reduce Motion: no animated ring fill on appear if it is enabled.
```

**Existing tests that must pass:** All of `HabitTrackerUITests/HabitTrackerUITests.swift` and `FreemiumUITests.swift` — the lock badge, counter badge, and `taskCircle_*` identifiers must all still resolve.

**New tests to implement:**
- UI test: eligible habit renders the strength ring; the accessibility label contains "Habit strength".
- UI test: habit with fewer than 3 completions renders **no** strength ring.
- UI test: strength ring coexists with the counter badge on a weekly multi-completion habit and with the lock badge on a locked free-tier habit.
- Snapshot or preview check at `circleSize` 80 and 100 confirming no ring overlap.

---

### Step 4.2 — Stage badge on the dashboard ring

**Objective:** Show the stage glyph from Developing upward.

**Inputs / dependencies:** Step 4.1; PRD §8 iconography table and display rules.

**Deliverable:** `HabitTracker/Views/StageBadgeView.swift` plus a `.topLeading` overlay in `TapAndHoldTaskView`.

**Agent prompt:**
```
Add HabitTracker/Views/StageBadgeView.swift to habit-tracker and wire it into the dashboard.

StageBadgeView(stage: HabitStage, accentColor: Color, isProminent: Bool):
- Renders Image(systemName: stage.sfSymbolName) in a small circular chip, styled like the existing freemium lock badge in TapAndHoldTaskView (read lines around the .topTrailing overlay and match its size, background, and shadow treatment so the two badges look like siblings).
- isProminent (stage.isProminentBadge — Strong and above): larger glyph and filled tint in the habit's accent colour. Starting through Building use a quieter secondary tint.
- .accessibilityHidden(true) — PRD §8 says the icon is decorative and VoiceOver announces the stage label only. On the dashboard, where there is no adjacent label, fold the stage name into the parent circle's accessibility label instead.

Wire-up in TapAndHoldTaskView:
- Add a `.overlay(alignment: .topLeading)` — verify it is unused there; the lock is .topTrailing and the hold ring is .top.
- Show it only when stage.showsDashboardBadge is true (i.e. never for Starting), per PRD §8 display rules.
- Add accessibility identifier "stageBadge_<task title slug>" following the existing taskCircle_* naming convention so UI tests can target it.
```

**Existing tests that must pass:** All UI tests; specifically the freemium lock test (`testPaywall_*` / locked-habit scenarios) to confirm the two corner badges do not collide or shift hit targets.

**New tests to implement:**
- UI test: a Starting habit shows **no** stage badge.
- UI test: a Developing habit shows a stage badge.
- UI test: badge and lock badge render together on a locked habit without overlap.
- Unit test: `sfSymbolName` returns a symbol that resolves (`UIImage(systemName:) != nil`) for all six stages — catches typos in symbol names.

---

## Phase 5 — Habit summary bottom sheet

### Step 5.1 — Habit daily grid

**Objective:** Build the Habit-Kit-style consistency grid as a standalone, testable component.

**Inputs / dependencies:** Phase 2; PRD §8 "Habit daily grid", §10.8 performance notes.

**Deliverable:** `HabitTracker/Views/HabitDailyGridView.swift`.

**Agent prompt:**
```
Create HabitTracker/Views/HabitDailyGridView.swift in habit-tracker — a consistency grid inspired by Habit Kit.

Layout (PRD §8):
- 7 rows (weekdays) x 25 visible columns (weeks). Each cell is one day; each column is one week.
- Row order follows AppSettings.weekStartDay via PeriodService.weekStart — do NOT hardcode Monday-first.
- Today sits in the LAST column. The only future days rendered are those needed to complete today's current week; they render as empty placeholders, visually distinct from a missed day (lower opacity or no fill) so a user does not read "not yet arrived" as "failed".
- Horizontally scrollable: scroll left for history, and cannot scroll right past the current week in the initial state. Initial scroll position is pinned to the right edge.
- No day numbers or weekday letters — the grid is a feeling of consistency, not a calendar (PRD §8).
- Cell colours come from the habit's configured colorToken via ColorPalette: filled = completed, unfilled = not completed. Use the same tokens the rest of the app uses; do not introduce new colours.

Highlighting rule (locked decision): a day is filled if it has at least ONE raw TaskCompletion row that day — raw presence, NOT period credit. A weekly periodComplete habit must still show the individual days it was done on.

Performance (PRD §10.8):
- Build a Set<Date> of startOfDay values ONCE when the view appears; never filter task.completions per cell.
- For long histories prefer a FetchDescriptor<TaskCompletion> predicated on a completedAt range over walking the whole relationship, which loads every row. Extend the set lazily as the user scrolls further back.

Interaction: tapping anywhere on the grid invokes an `onTap: () -> Void` closure (the parent opens ManageCompletionsView). The grid itself must not own that sheet.

Accessibility: expose the grid as a single element labelled with the completion count in the visible range rather than 175 individually focusable cells.
Add accessibility identifier "habitDailyGrid".
```

**Existing tests that must pass:** All existing unit and UI tests.

**New tests to implement:**
- Unit: day-set builder marks exactly the days that have at least one completion row.
- Unit: a weekly `periodComplete` habit completed on Tue and Thu fills **both** days (raw presence, not one credit).
- Unit: multiple completions on one day fill that day once.
- Unit: row ordering respects `weekStartDay` for both Monday-start and Sunday-start settings.
- Unit: future-day placeholder count equals the days remaining in the current week.
- UI test: grid renders, scrolls left, cannot scroll right past the current week, and a tap opens Manage Completions.
- Performance test: building the day set for a habit with about 2 years of daily completions stays under an agreed budget (see Step 11.2).

---

### Step 5.2 — Habit summary bottom sheet

**Objective:** Replace the tap confirmation dialog with the Version A hero-ring sheet.

**Inputs / dependencies:** Steps 1.1, 2.1, 2.2, 4.2, 5.1; PRD §8 and §9 (including the mock at `Vault/Product/Ring habit/assets/habit-summary-bottomsheet-hero-ring.png`); `docs/ux-ui-principles.md`.

**Deliverable:** `HabitTracker/Views/HabitSummarySheetView.swift`; updated `TaskListView.swift` and `TaskListViewModel.swift`.

**Agent prompt:**
```
Create HabitTracker/Views/HabitSummarySheetView.swift in habit-tracker and replace the current tap-to-menu confirmation dialog with it.

Read first: PRD - Habit strength.md §8 "Habit summary bottom sheet" and §9 "Version A: Hero ring" (with the mock in Vault/Product/Ring habit/assets/), HabitTracker/Views/TaskListView.swift (the confirmationDialog around the taskForMenu / showingTaskMenu flow, and the .sheet(item:) presentations for taskToEdit and taskForStats), and TaskListViewModel.swift.

Vertical order, top to bottom (PRD §9):
1. Drag handle (system)
2. HERO strength ring — large ring; filled arc = score 0...100. Centre: "Habit strength" label plus the score as a large integer, no decimals.
3. Habit identity row — habit icon plus habit name
4. Stage row — small stage icon immediately to the LEFT of the stage label (reuse StageBadgeView from Step 4.2). ALWAYS shown, including Starting.
5. HabitDailyGridView (Step 5.1)
6. Action menu — Stats / Edit / Remove as three equal-width pills

Ineligible state (fewer than 3 credited completions, PRD §8 and §9):
- Hero ring greyed out, no numeric score, centre text "Habit strength will be shown after 3 completions".
- The stage row still renders, showing Starting with its icon.

Wiring in TaskListView / TaskListViewModel:
- Single tap on an unlocked habit currently sets taskForMenu and showingTaskMenu = true, driving a confirmationDialog with Stats / Edit / Remove / Cancel. REMOVE that confirmationDialog and present this sheet instead. Keep the locked-habit path unchanged: a locked habit still calls presentPaywall(source: "locked_habit", ...).
- Reuse the existing plumbing rather than duplicating it. Stats sets viewModel.taskForStats; Edit sets viewModel.taskToEdit; Remove calls viewModel.confirmDelete(task) (a METHOD that sets taskToDelete and showDeleteConfirmation — there is no confirmDelete property).
- Dismiss this sheet before presenting the chained sheet or alert, so two sheets never contend.
- Grid tap opens ManageCompletionsView. Today it is only reachable from inside TaskStatsView via showingManageCompletions; expose it directly from the sheet, dismissing the summary first.
- Read strength from the HabitStrengthCache environment object, never by computing in the view body.
- This is the app's first genuinely medium-height sheet: set explicit .presentationDetents (medium, and large if the grid needs it). Only PaywallView sets detents today — match its style. Sheets here use plain .sheet plus NavigationStack.

Accessibility (PRD §9): score announced as "Habit strength, {n}"; stage announced as "{stage name}" with the icon decorative. Add accessibility identifiers habitSummarySheet, habitSummary_strengthRing, habitSummary_stageLabel, habitSummary_statsButton, habitSummary_editButton, habitSummary_removeButton.

Use English source strings inline for now; Phase 9 adds the localization keys.
```

**Existing tests that must pass:** `HabitTrackerUITests/HabitTrackerUITests.swift` — **`testTaskMenu_ContextMenuOptions` will fail by design** because the confirmation dialog is gone. Update it in this step to drive the new sheet rather than deleting it. Every other UI test, including all of `FreemiumUITests.swift`, must pass untouched.

**New tests to implement:**
- UI: single tap opens `habitSummarySheet` and no confirmation dialog appears.
- UI: all six elements present (ring, icon, name, stage row, grid, three action pills).
- UI: Stats opens `TaskStatsView`; Edit opens `TaskConfigurationView`; Remove shows the delete alert — each after the sheet dismisses.
- UI: locked free-tier habit still opens the paywall on tap, not the sheet.
- UI: habit with 2 completions shows the greyed ring and the "after 3 completions" copy, and no number.
- UI: grid tap reaches Manage Completions.
- Unit: the sheet's view model exposes the same `HabitStrength` the service returns for the same task.

---

## Phase 6 — Stage celebration

### Step 6.1 — Stage advance celebration with notification opt-in

**Objective:** Celebrate advances with the PRD's five copy blocks, and offer notification enablement when the habit has none.

**Inputs / dependencies:** Steps 1.1, 3.2; PRD §8 "Stage completion celebratory pop up"; `FirstCompletionCelebrationView.swift`, `RewardCelebrationView.swift`.

**Deliverable:** `HabitTracker/Views/StageCelebrationView.swift`; celebration state on `TaskListViewModel`; overlay in `TaskListView`.

**Agent prompt:**
```
Create HabitTracker/Views/StageCelebrationView.swift in habit-tracker.

Read FirstCompletionCelebrationView.swift and RewardCelebrationView.swift first and MATCH their pattern exactly — these are full-screen .overlay modals presented from TaskListView, not sheets: dimmed Color.black.opacity(0.6).ignoresSafeArea() backdrop that dismisses on tap, a ConfettiParticleView layer (60 pieces, skipped under Reduce Motion), a centre VStack with a spring scale/opacity entrance (.spring(response: 0.5, dampingFraction: 0.7) driven by a showContent flag), and .accessibilityAddTraits(.isModal). Reuse the confetti types at the bottom of RewardCelebrationView.swift rather than duplicating them.

Parameters: (from: HabitStage, to: HabitStage, stage icon via to.sfSymbolName, offersNotificationOptIn: Bool, onEnableNotifications: (Date) -> Void, onDismiss: () -> Void)

Copy — use these five transitions VERBATIM from PRD §8:
- Starting -> Developing: "Your brain is wiring the cue" / "Repetition is linking this action to its context. The first neural pathway is forming — keep showing up and the association will deepen."
- Developing -> Building: "Automaticity is taking root" / "Your mind needs less deliberate effort to start. Context cues are beginning to trigger the behavior on their own — consistency locks this in."
- Building -> Strong: "Habit control is shifting" / "Goal-directed effort is giving way to habitual control. The behavior is settling into a reliable loop — protect this streak and it will stick."
- Strong -> Established: "The loop is becoming stable" / "Cue, routine, and reward are aligning with growing automaticity. Missing a day won't erase progress — returning promptly keeps the pathway strong."
- Established -> Mastering: "Near-automatic mastery" / "This habit is approaching high automaticity. Your brain retrieves it with little conscious push — continue the rhythm and make it part of who you are."
Put the mapping in a pure function keyed on the destination stage. For a multi-stage jump (score leaping two boundaries at once), show ONLY the copy for the highest stage reached and fire one celebration, not two.

Notification opt-in (PRD §8): when the habit has notificationEnabled == false, include the reminder opt-in in the same pop-up. Reuse the DatePicker plus "Turn on reminders" / "Not now" affordance from FirstCompletionCelebrationView so the two prompts feel identical, and route acceptance through the existing enable-reminder path in TaskListViewModel (which checks authorizationStatus() == .notDetermined before prompting). When notificationEnabled is already true, omit the opt-in entirely.

Wiring in TaskListViewModel / TaskListView:
- Add pendingStageCelebration and showingStageCelebration state, following the showingRewardCelebration and showingFirstCompletionPrompt precedent.
- Present with a .zIndex above the existing celebrations (they use 100 and 101) and .transition(.opacity).
- Trigger from HabitStageEvaluator transitions where isAdvance && isCelebratable. NEVER celebrate a reversion.
- On dismiss or accept, set task.lastCelebratedStage = transition.to and task.lastCelebratedAt = .now, then save.
- If several habits advance at once, queue them and show one at a time; never stack overlays.

Use English source strings inline; Phase 9 adds localization keys. No analytics yet — that is Phase 8.
```

**Existing tests that must pass:** All existing unit tests; UI tests covering `RewardCelebrationView` and `FirstCompletionCelebrationView` (the new overlay must not steal their z-order or intercept their dismiss taps).

**New tests to implement:**
- Unit: copy mapping returns the correct title and body for all five transitions.
- Unit: a two-boundary jump yields exactly one celebration, for the highest stage.
- Unit: reversion produces no celebration.
- Unit: after dismissal, `lastCelebratedStage` and `lastCelebratedAt` are persisted.
- Unit: queueing — three simultaneous advances present sequentially.
- UI: completing a habit that crosses a boundary shows the celebration; dismiss returns to the list.
- UI: opt-in shown when `notificationEnabled == false`, hidden when true.
- UI: accepting the opt-in sets `notificationEnabled == true` and schedules reminders.

---

## Phase 7 — Proximity notifications

### Step 7.1 — Actionable notification infrastructure

**Objective:** Add the `UNNotificationCategory` / `UNNotificationAction` capability the app does not have today, including a Mark-done handler that writes outside the view hierarchy.

**Inputs / dependencies:** Step 2.1 (projections); PRD §8 notification templates, §10.9; `NotificationService.swift`.

**Deliverable:** Updated `NotificationService.swift` plus a `UNUserNotificationCenterDelegate`.

**Agent prompt:**
```
Extend HabitTracker/Services/NotificationService.swift in habit-tracker with actionable notifications.

Read the file first. It is a @MainActor final class with a `shared` singleton. Identifiers are built by a private helper as "task-\(task.id.uuidString)-day-\(weekday)" with ISO weekday 1...7, and cancelNotifications(for:) removes all seven of those IDs. The project has NO UNNotificationCategory, NO UNNotificationAction, and NO UNUserNotificationCenterDelegate anywhere — this is new capability.

1. Separate identifier namespace so rescheduleNotifications cannot clobber the new pushes (PRD §10.9):
     "strength-\(task.id.uuidString)-proximity"
     "strength-\(task.id.uuidString)-reversion"
   Add cancelStrengthNotifications(for task: HabitTask) covering both. Verify cancelNotifications(for:) still only touches the seven reminder IDs.

2. Register one UNNotificationCategory (identifier "HABIT_STRENGTH") with two UNNotificationActions:
     "MARK_DONE" — title "Mark done", no .foreground option (complete without launching the app)
     "SNOOZE"    — title "Later", .destructive is wrong here; use no options
   Register categories once at launch, before any notification can be delivered.

3. Add a UNUserNotificationCenterDelegate (new file HabitTracker/Services/NotificationActionHandler.swift is fine) and set it during app launch in HabitTrackerApp.
   - MARK_DONE must insert a TaskCompletion for the task parsed from the identifier. This runs OUTSIDE the normal view hierarchy, so it needs its own ModelContext from the shared ModelContainer — refactor HabitTrackerApp so the container is reachable (e.g. a static/shared accessor) rather than duplicating makeModelContainer, which would create a second store.
   - Respect PeriodService.canAcceptCompletion before inserting, so the action cannot exceed the period quota where the task list would not allow it.
   - Invalidate HabitStrengthCache for that task afterwards.
   - SNOOZE: cancel today's pending strength notification for that habit and take no other action.
   - Unknown or deleted task ID: fail silently, no crash.

4. Fix the pre-existing gap flagged in PRD §10.9: habit deletion does not cancel notifications. Call cancelNotifications and cancelStrengthNotifications on delete so no push can reference a deleted habit.

Do not add the scheduling logic in this step — that is Step 7.2.
```

**Existing tests that must pass:** All existing unit tests; UI tests covering the notification opt-in flow (`testFirstCompletion_*` / reminder scenarios) to confirm category registration does not disturb existing reminders.

**New tests to implement:**
- Unit: strength identifiers match the documented format and are distinct from reminder identifiers.
- Unit: `cancelNotifications(for:)` removes only the seven reminder IDs, leaving strength IDs pending.
- Unit: `cancelStrengthNotifications` removes both strength IDs.
- Unit: identifier round-trip — a task UUID parsed back out of a strength identifier.
- Unit: Mark-done handler inserts exactly one `TaskCompletion` and respects `canAcceptCompletion`.
- Unit: Mark-done for an unknown UUID is a no-op without crashing.
- Unit: deleting a habit cancels both reminder and strength notifications.

---

### Step 7.2 — Proximity and reversion scheduling

**Objective:** Schedule the two 09:00 pushes based on projected stage crossings.

**Inputs / dependencies:** Steps 2.1, 3.2, 7.1; PRD §8 templates, §10.9.

**Deliverable:** `HabitTracker/Services/StrengthNotificationScheduler.swift`.

**Agent prompt:**
```
Create HabitTracker/Services/StrengthNotificationScheduler.swift in habit-tracker.

Constraints (PRD §10.9): iOS will not reliably run code at 09:00 and there is no BGAppRefreshTask in this project. So evaluation is opportunistic — schedule TOMORROW's 09:00 notification ahead of time, and re-validate or cancel it on the next foreground. It is accepted that a user who never opens the app receives a push computed from slightly stale data; note that in a code comment.

API:
    @MainActor
    enum StrengthNotificationScheduler {
        static func refresh(tasks: [HabitTask], weekStartDay: Int, now: Date = .now) async
    }

Per task:
1. Skip entirely unless the notification authorization status is .authorized (check via NotificationService.authorizationStatus()). Never trigger a permission prompt from here.
2. Cancel existing strength notifications for the task first, so stale pushes cannot survive a change in the underlying data.
3. Advance case: if HabitStrengthService.projectedStrength(for:assumingCompletionOn: tomorrow).stage > current stage, schedule "strength-{uuid}-proximity" for 09:00 local tomorrow.
   Body per PRD §8: title "{habit name} · {stage}", body "One check-in today makes you leap to the next stage".
   The {stage} in the title is the CURRENT stage, matching the PRD example "Meditation · Strong".
4. Reversion case: if projectedStrengthAssumingMiss(for:on: tomorrow).stage < current stage, schedule "strength-{uuid}-reversion" for 09:00 local tomorrow.
   Body per PRD §8: title "{habit name} · {stage}", body "One check-in today keeps your habit formation on track."
5. If both fire, prefer the REVERSION notification (loss aversion is the more urgent message) and schedule only one push per habit per day, so a user with many habits is not flooded.
6. Attach categoryIdentifier "HABIT_STRENGTH" from Step 7.1 so Mark done / Later appear.
7. Use UNCalendarNotificationTrigger with hour 9, minute 0, repeats false, in the user's current calendar and time zone.
8. Skip tasks not scheduled tomorrow (PeriodService knows this for specificDays) — a Mon/Wed/Fri habit must not be nudged on a Tuesday.

Habit names are user-typed. They may appear in the notification body (it is local, on-device) but must NEVER be sent to analytics — see AnalyticsProperties.swift, which explicitly never sends habit titles.

Call refresh from the same app-foreground hook as HabitStageEvaluator (Step 3.2) and after each completion.
```

**Existing tests that must pass:** All existing unit tests; the reminder-notification UI tests.

**New tests to implement:**
- Unit: a habit one completion away from an advance schedules the proximity push; a habit far from a boundary schedules nothing.
- Unit: a habit whose miss would drop a stage schedules the reversion push.
- Unit: when both conditions hold, only the reversion push is scheduled.
- Unit: at most one strength push per habit per day.
- Unit: nothing scheduled when authorization is not `.authorized`.
- Unit: `specificDays` habit not scheduled tomorrow gets no push.
- Unit: trigger resolves to 09:00 local; verify across two time zones.
- Unit: stale push is cancelled on refresh when the projection no longer crosses a boundary.
- Unit: notification body matches the PRD template exactly, including the middle dot separator.

---

## Phase 8 — Analytics

### Step 8.1 — Widen the analytics protocol

**Objective:** Allow numeric properties so `strength_score` aggregates in PostHog instead of landing as a string.

**Inputs / dependencies:** PRD §11 analytics notes (option 1 preferred); `AnalyticsService.swift`, `PostHogAnalyticsService.swift`, `FirebaseAnalyticsBridge.swift`, `AnalyticsProperties.swift`.

**Deliverable:** Widened protocol plus updated implementations.

**Agent prompt:**
```
In habit-tracker, widen the analytics protocol from [String: String] to [String: Any].

Current state: `protocol AnalyticsService: AnyObject { func track(_ event: AnalyticsEvent, properties: [String: String]) }` with a convenience overload, implemented by PostHogAnalyticsService and NoOpAnalyticsService, bridged by FirebaseAnalyticsBridge, injected via an EnvironmentKey in HabitTrackerApp.swift, and consumed as @Environment(\.analyticsService).

Why: sending strength_score as a string would break numeric aggregation such as averages and percentiles, which is the point of the metric (PRD §11).

1. Change the protocol to `func track(_ event: AnalyticsEvent, properties: [String: Any])`.
2. Update every conformance and the Firebase bridge. PostHog accepts Any natively. Firebase only accepts a restricted set of value types, so coerce there: pass Int/Double/Bool through and String(describing:) anything else, rather than dropping the property silently.
3. Update ALL existing call sites. Dictionary literals of strings still type-check as [String: Any], so most should compile unchanged — verify by building, and fix any inference errors at the call site rather than by adding casts inside the service.
4. Keep the no-properties convenience overload.
5. Do not change any existing event name or property key. This step must be behaviour-preserving for existing analytics.
```

**Existing tests that must pass:** All existing unit tests, especially any analytics assertions in `FreemiumTests.swift`; all UI tests (which run with `NoOpAnalyticsService` via `AnalyticsServiceFactory`).

**New tests to implement:**
- Unit: a spy `AnalyticsService` receives an `Int` property as an `Int`, not a `String`.
- Unit: existing string-only events still emit identical names and property keys.
- Unit: the Firebase bridge coerces unsupported value types rather than dropping the key.

---

### Step 8.2 — Habit strength events and properties

**Objective:** Add the four new events and attach score and stage to existing habit events.

**Inputs / dependencies:** Step 8.1, Phases 3–6; PRD §11 event table.

**Deliverable:** New `AnalyticsEvent` cases; updated `AnalyticsProperties.swift`; emission at the four call sites.

**Agent prompt:**
```
Add habit-strength analytics to habit-tracker.

New AnalyticsEvent cases (follow the existing snake_case raw-value convention):
| Case | Raw value | Properties |
| stageAdvanceCelebrationShown | stage_advance_celebration_shown | from_stage, to_stage, notification_prompt_shown |
| stageAdvanceCelebrationAction | stage_advance_celebration_action | action = "dismissed" or "enabled_notifications" |
| habitSummaryOpened | habit_summary_opened | is_eligible |
| stageReverted | stage_reverted | from_stage, to_stage |

Emission points:
- stageAdvanceCelebrationShown — when StageCelebrationView appears (Phase 6)
- stageAdvanceCelebrationAction — on dismiss or opt-in accept
- habitSummaryOpened — when HabitSummarySheetView is presented (Phase 5)
- stageReverted — fired by HabitStageEvaluator (Phase 3), NOT by the UI

Structural properties in AnalyticsProperties.swift:
- Extend HabitTask.analyticsStructuralProperties (today: frequency, tracking, goal_type, times_per_period, has_notification, has_reward, is_preset) with:
    "strength_score": Int   (numeric, enabled by Step 8.1)
    "strength_stage": String (stage rawValue — low cardinality)
- This makes habit_completed, habit_created, and habit_edited all carry them consistently.
- analyticsStructuralProperties is currently a property with no access to a Calendar, weekStartDay, or the strength cache. Refactor it to a function taking the strength (or the cache) as a parameter and update all call sites, rather than computing strength inside a model extension.
- For habit_completed, the score must be the value AFTER the completion is recorded, or the funnel reads one step behind (PRD §11). Invalidate the cache before reading.
- Keep the existing stats_opened event with ["scope": "habit"] for the Stats entry inside the new sheet, so historical insights stay comparable.

PRIVACY — non-negotiable: AnalyticsProperties.swift explicitly never sends habit titles, category names, or any user-typed string. Stage and score are structural and safe. The celebration copy must NOT be sent as a property.
```

**Existing tests that must pass:** All existing unit tests; all UI tests.

**New tests to implement:**
- Unit: each new event emits its documented property keys.
- Unit: `strength_score` arrives as an `Int`; `strength_stage` as the stage raw value.
- Unit: `habit_completed` carries the score computed **after** the completion (assert it differs from the pre-completion value in a boundary-crossing case).
- Unit: no habit title, category name, or celebration copy appears in any emitted property, for every new and modified event.
- Unit: `habit_summary_opened` reports `is_eligible == false` for a habit with 2 completions.
- Unit: `stage_reverted` is emitted by the evaluator, not the UI (assert with the UI absent).

---

## Phase 9 — Localization

### Step 9.1 — Localize all new copy across seven languages

**Objective:** Add every new string to all seven `Localizable.strings` files.

**Inputs / dependencies:** Phases 4–7 complete (all copy known); PRD §9 localization note, §10.10; `HabitTracker/Resources/*/Localizable.strings`; `docs/ux-ui-principles.md` localization section.

**Deliverable:** Seven updated `Localizable.strings` files.

**Agent prompt:**
```
Localize all new Habit Strength copy in habit-tracker across all seven languages: en, es, fr, de, it, nl, pt-PT (HabitTracker/Resources/<lang>.lproj/Localizable.strings).

IMPORTANT — this project does NOT use String Catalogs. It uses legacy .strings files where the KEY IS THE ENGLISH SOURCE STRING, for example:
    "Congratulations!" = "Congratulations!";
All seven files currently have exactly 223 lines and parallel ordering. Preserve that: insert new keys at the SAME position in every file, keep the count identical, and match the existing comment/grouping style.

Strings to add:
1. Six stage names: Starting, Developing, Building, Strong, Established, Mastering
2. "Habit strength"
3. "Habit strength will be shown after 3 completions"
4. Five celebration titles and five descriptions (PRD §8) — verbatim English as keys
5. Two notification bodies: "One check-in today makes you leap to the next stage" and "One check-in today keeps your habit formation on track."
6. Notification action titles: "Mark done", "Later"
7. Bottom sheet action pills: reuse existing Stats / Edit / Remove keys if present — check before adding duplicates
8. PRD §11 copy: "Tap and hold to complete, single tap for details", "Your plan"

Translation quality: these are behavioural-science motivational messages. Keep the register consistent with the existing app voice in each language — read nearby entries first. Do not translate SF Symbol names. Preserve the middle dot separator and any format specifiers exactly.

Verify: run a check that every key present in en.lproj exists in the other six, and that no file has a duplicate key or a missing semicolon.
```

**Existing tests that must pass:** All existing unit and UI tests. UI tests assert on English strings, so a broken `en.lproj` will surface there.

**New tests to implement:**
- Unit: every key in `en.lproj` exists in all six other files (parity test — valuable beyond this feature).
- Unit: no duplicate keys in any file.
- Unit: `HabitStage.displayName` resolves to a non-key-echoing value for all six stages.
- UI: launch in a non-English locale and assert the summary sheet renders translated stage labels.

---

## Phase 10 — PRD §11 minor changes

### Step 10.1 — Four standalone improvements

**Objective:** Deliver the unrelated §11 items. They are independent of the strength engine and can ship in parallel with Phases 4–9.

**Inputs / dependencies:** Step 1.2 (`hasRequestedAppReview`); PRD §11; the ruling on the review-prompt trigger.

**Deliverable:** Edits to `TaskListView.swift`, `TapAndHoldTaskView.swift`, `AppSettingsView.swift`, plus a review-prompt helper.

**Agent prompt:**
```
Implement the four PRD §11 minor changes in habit-tracker. Each is independent — keep them as separate, reviewable commits.

1. App Store review prompt.
   When total credited completions ACROSS ALL HABITS reaches 3, request an iOS review via StoreKit's requestReview (the SwiftUI @Environment(\.requestReview) action). Guard with AppSettings.hasRequestedAppReview so it is never requested twice, setting the flag before or immediately after the call. Do not request it in the same moment as a celebration overlay — defer until no overlay is showing, or iOS will suppress it and the one-shot flag will be wasted. Never request during UI tests (check the existing --uitesting launch argument handling).

2. Dashboard subtitle.
   In TaskListView, add a subtitle at the top of the task list: "Tap and hold to complete, single tap for details". Style it as a secondary caption consistent with docs/ux-ui-principles.md. It must not push content in a way that breaks the existing UI tests' element positions.

3. Faster tap and hold — 30% faster.
   In HabitTracker/Views/TapAndHoldTaskView.swift change `holdDuration` from 2.0 to 1.4. Leave tickInterval (1/60) and LongPressGesture(minimumDuration: 0.15) unchanged.
   Note: OnboardingView calls TapAndHoldTaskView WITHOUT overriding holdDuration, so it inherits the new value automatically and satisfies the PRD's "make the onboarding example the same time". Verify this — do not add a second constant.

4. Settings plan section.
   In HabitTracker/Views/AppSettingsView.swift rename the section title from "Premium" to "Your plan" (the PRD's "You plan" is a typo). Make the currently non-tappable free-plan HStack a Button that opens the paywall — reuse the same paywall presentation the rest of the app uses, with an analytics source label such as "settings_plan_row". Only the FREE state is tappable; when entitlementManager.isPremium is true the row stays informational. Leave the Restore Purchases and Manage Subscription rows untouched.

Add the new strings to en.lproj now; Phase 9 covers the other six languages.
```

**Existing tests that must pass:** All of `HabitTrackerUITests` — the subtitle changes layout and the hold duration changes timing, so any UI test with a hardcoded 2-second hold wait must be updated in this step. `FreemiumUITests` paywall tests must still pass with the new settings entry point.

**New tests to implement:**
- Unit: review prompt requested exactly once; `hasRequestedAppReview` blocks a second request.
- Unit: review prompt not requested at 2 total credited completions; requested at 3.
- UI: subtitle visible on the dashboard.
- UI: hold completes in about 1.4s (assert completion before a 1.6s timeout and not before 1.2s).
- UI: onboarding demo hold uses the same duration.
- UI: settings section titled "Your plan"; tapping the free-plan row opens the paywall.
- UI: premium user's plan row is not tappable.

---

## Phase 11 — QA, performance, release

### Step 11.1 — Full acceptance pass

**Objective:** Verify the feature against Step 0.1's acceptance criteria and close gaps.

**Inputs / dependencies:** Phases 1–10; `docs/acceptance-criteria-habit-strength.md`.

**Deliverable:** A pass/fail matrix appended to the acceptance criteria doc; fixes for any failure.

**Agent prompt:**
```
You are a QA engineer for habit-tracker. Using docs/acceptance-criteria-habit-strength.md:
1. Run the full unit suite (Swift Testing, HabitTrackerTests) and the full UI suite (XCTest, HabitTrackerUITests) on an iPhone simulator.
2. Map every acceptance criterion to a passing automated test. Where none exists, either add it or record it as a documented manual check with exact reproduction steps.
3. Exercise these high-risk paths explicitly:
   - Upgrade path: launch with a pre-feature store containing long-standing habits; assert ZERO celebrations and correctly seeded stages.
   - Fresh install: onboarding, first habit, first three completions (ring unlock plus review prompt).
   - Editing past completions in ManageCompletionsView and confirming the score updates in both directions.
   - Changing weekStartDay and confirming the grid rows and the consistency window both follow.
   - Deleting a habit with pending strength notifications.
   - Time zone change and a day rollover with the app backgrounded.
   - All four frequency types plus both tracking modes.
   - VoiceOver on the summary sheet: strength, stage, and grid all announce per PRD §9.
   - Dynamic Type at the largest accessibility size on the summary sheet.
   - Dark mode and the seven languages on the summary sheet and the celebration.
4. Append a results matrix to the acceptance criteria doc and fix every failure.
```

**Existing tests that must pass:** Everything — the full `HabitTrackerTests` and `HabitTrackerUITests` suites, green.

**New tests to implement:** Any automated test filling a gap found in the mapping, plus regression tests for each bug fixed.

---

### Step 11.2 — Performance validation

**Objective:** Confirm the dashboard and the grid stay smooth on realistic long histories, which is the main technical risk in this feature.

**Inputs / dependencies:** Steps 2.2, 4.1, 5.1; PRD §10.8.

**Deliverable:** Performance tests plus a short findings note.

**Agent prompt:**
```
Validate Habit Strength performance in habit-tracker (PRD §10.8 identifies this as the main risk: computing N walks every period since createdAt, and the dashboard renders every habit).

1. Build a test fixture: 20 habits across all four frequency types, each with about 2 years of completions (roughly 700 rows for the daily ones).
2. Add performance tests:
   - Cold dashboard render time with the cache empty versus warm.
   - HabitStrengthService.strength for a 2-year daily habit — single call.
   - HabitStrengthCache: 20 habits, first pass versus subsequent passes.
   - HabitDailyGridView day-set construction, including scroll-back extension.
   - MigrationService backfill across 20 long-history habits (this runs synchronously at launch — it must not visibly delay the first frame).
3. Verify the claims made in the plan: strength is computed at most once per habit per day; the grid builds its Set<Date> once rather than filtering per cell; long histories use a range-predicated FetchDescriptor<TaskCompletion> rather than walking the whole relationship.
4. Profile with Instruments (Time Profiler and SwiftUI) and confirm the dashboard holds 60fps while scrolling.
5. Set explicit budgets, record measured numbers, and if any budget is missed, fix the hot path — do not relax the budget.
```

**Existing tests that must pass:** Full unit and UI suites.

**New tests to implement:** The five performance tests above, each with an asserted budget.

---

### Step 11.3 — Release preparation

**Objective:** Version bump, release notes, and submission material.

**Inputs / dependencies:** Steps 11.1, 11.2 green; `docs/app-store-submission-2.2.0.md` (format reference); the `submit-appstore-review` skill.

**Deliverable:** `docs/app-store-submission-<next version>.md` and updated store metadata.

**Agent prompt:**
```
Prepare the Habit Strength release for habit-tracker.
1. Read docs/app-store-submission-2.2.0.md as the format reference and project.yml for the current version and build number.
2. Determine the next version (this is a feature release, so a minor bump) and document the Xcode version and build bump steps.
3. Write docs/app-store-submission-<version>.md covering: what's new copy (localized for all seven App Store languages), reviewer notes explaining the Habit Strength score so a reviewer is not confused by an empty ring on a fresh install, screenshot plan including the new bottom sheet, and the full App Store Connect field checklist.
4. Update docs/app-store-connect-metadata.md if the feature set description changes.
5. Flag any App Store risk: the new notification actions and the review prompt both touch guideline-sensitive areas. Note that the Lally-inspired framing is motivational and must not read as a medical or clinical claim (PRD §3 non-goals) — check the store copy and in-app celebration copy for wording that could read as a health claim.
```

**Existing tests that must pass:** Full unit and UI suites on the release build configuration.

**New tests to implement:** None.

---

## Risk register

| Risk | Impact | Mitigation |
|---|---|---|
| Backfill fires celebrations on upgrade | High — every existing user sees a barrage on first launch | Step 3.1 seeds both stage fields with no side effects; explicit zero-celebration test; `hasSeededHabitStrength` one-shot flag |
| New enum stored property crashes on legacy rows | High — launch crash for existing users | Step 1.2 mandates the documented `trackingRaw` optional pattern; round-trip decode tests; this trap was already hit once in this codebase |
| Dashboard frame drops from recomputing N | Medium — the core screen feels slow | Step 2.2 cache keyed by `(habitID, startOfDay)`; Step 11.2 budgets and Instruments profiling |
| Score oscillating across a boundary spams celebrations | Medium — user annoyance, uninstall risk | `lastCelebratedStage` high-water mark plus a 12-hour cooldown in Step 3.2 |
| Analytics protocol widening breaks existing events | Medium — silent analytics loss | Step 8.1 is behaviour-preserving with parity tests before any new event lands |
| Removing the confirmation dialog breaks a known UI test | Low — caught at build time | Step 5.2 explicitly updates `testTaskMenu_ContextMenuOptions` rather than deleting it |
| Notifications computed from stale data for dormant users | Low — accepted trade-off | Documented in Step 7.2; re-validated on every foreground; no `BGAppRefreshTask` available |
| Monthly habits produce a jumpy score | Low | `max(28 days, 3 periods)` window with a dedicated test |
| Localization drift across seven files | Low — key-echo strings visible in UI | Step 9.1 parity test, reusable beyond this feature |

---

## Deliverable file summary

**New files**

| Path | Phase |
|---|---|
| `docs/acceptance-criteria-habit-strength.md` | 0 |
| `HabitTracker/Models/HabitStrength.swift` | 2 |
| `HabitTracker/Services/HabitStrengthService.swift` | 2 |
| `HabitTracker/Services/HabitStrengthCache.swift` | 2 |
| `HabitTracker/Services/HabitStageEvaluator.swift` | 3 |
| `HabitTracker/Views/StageBadgeView.swift` | 4 |
| `HabitTracker/Views/HabitDailyGridView.swift` | 5 |
| `HabitTracker/Views/HabitSummarySheetView.swift` | 5 |
| `HabitTracker/Views/StageCelebrationView.swift` | 6 |
| `HabitTracker/Services/NotificationActionHandler.swift` | 7 |
| `HabitTracker/Services/StrengthNotificationScheduler.swift` | 7 |
| `HabitTrackerTests/HabitStrengthTests.swift` | 1–3 |
| `HabitTrackerUITests/HabitStrengthUITests.swift` | 4–6 |
| `docs/app-store-submission-<version>.md` | 11 |

**Modified files**

| Path | Phases |
|---|---|
| `docs/data-model.md` | 0 |
| `HabitTracker/Models/Enums.swift` | 1 |
| `HabitTracker/Models/HabitTask.swift` | 1 |
| `HabitTracker/Models/AppSettings.swift` | 1 |
| `HabitTracker/Services/MigrationService.swift` | 3 |
| `HabitTracker/HabitTrackerApp.swift` | 2, 3, 7 |
| `HabitTracker/Views/ContentView.swift` | 3 |
| `HabitTracker/Views/TaskCircleView.swift` | 4 |
| `HabitTracker/Views/TapAndHoldTaskView.swift` | 4, 10 |
| `HabitTracker/Views/TaskListView.swift` | 5, 6, 10 |
| `HabitTracker/ViewModels/TaskListViewModel.swift` | 5, 6 |
| `HabitTracker/Views/ManageCompletionsView.swift` | 2, 5 |
| `HabitTracker/ViewModels/TaskConfigurationViewModel.swift` | 2 |
| `HabitTracker/Services/NotificationService.swift` | 7 |
| `HabitTracker/Services/AnalyticsService.swift` | 8 |
| `HabitTracker/Services/PostHogAnalyticsService.swift` | 8 |
| `HabitTracker/Services/FirebaseAnalyticsBridge.swift` | 8 |
| `HabitTracker/Services/AnalyticsProperties.swift` | 8 |
| `HabitTracker/Views/AppSettingsView.swift` | 10 |
| `HabitTracker/Resources/*/Localizable.strings` (7 files) | 9, 10 |
| `HabitTrackerUITests/HabitTrackerUITests.swift` | 5, 10 |
| `project.yml` | 11 |

**Explicitly unchanged:** `StatisticsService.swift` and `PeriodService.swift`. The strength engine composes them; it must not modify or duplicate them.
