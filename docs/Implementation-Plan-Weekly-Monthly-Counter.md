# Implementation Plan — Weekly & Monthly Habits Counter

> Multi-agent delivery plan derived from [PRD - Weekly and monthly habits counter.md](/Users/maurizio.bellini/Documents/Vault/Product/Ring%20habit/PRD%20-%20Weekly%20and%20monthly%20habits%20counter.md) and supporting project docs.

**Feature:** Replace the confusing "measurement period + frequency" setup with a single frequency model (daily / weekly / monthly / specific days) plus a per-period quota, an in-list progress counter (`C/N`), partial-highlight UI, a `tracking` mode for weekly/monthly/specific days, and a data migration for existing users.

**Target repo:** `habit-tracker` (bundle ID `co.fooshi.habitring`)

**Status:** Draft
**Date:** 2026-06-26

---

## Input document validation

| Document | Path | Status |
|----------|------|--------|
| PRD (Weekly & monthly counter) | `Vault/Product/Ring habit/PRD - Weekly and monthly habits counter.md` | ✅ Provided (incl. Completion state machine + Migration appendices) |
| UX principles | `docs/ux-ui-principles.md` + PRD §10 | ✅ Available |
| Tech stack | `docs/tech-stack.md` + PRD §11 | ✅ Available (SwiftUI, SwiftData, MVVM `@Observable`, Swift Testing + XCUITest) |
| Data model | `docs/data-model.md` | ✅ Available (note: predates `monthly`/`weekly` `FrequencyType` and `tracking`) |
| Acceptance criteria (feature-specific) | — | ⚠️ **Missing** — create in Phase 0 |
| Dedicated UX/Figma spec for counter badge | — | ⚠️ **Missing** — PRD §10 is sufficient for v1 |

**Open product decisions that must be locked in Phase 0** (from PRD §12 "Open decisions" + Migration §5). These gate later phases and are called out per-step:

1. Weekly/monthly **N=1** behavior (visible every day? one tap per period?).
2. **Over-completion** rule — confirmed intent: task list caps via disabled tap-and-hold at `COMPLETE`; manage-completions calendar may exceed N. Confirm stats-credit handling for `eachCompletion` when `C > N`.
3. **Undo / decrement** mechanism on the task list.
4. **Specific days + all 7 selected** → daily or weekly profile?
5. **Specific days quota** — is N the count of selected days, or an independent times/week?
6. **Streaks/rewards** — confirm new period-based rules (PRD now defines them) supersede the old non-goal.
7. **Manage completions** editing model for `MULTI_DAILY`.
8. **Timezone/calendar** — confirm `Calendar.current` / device locale for all period math.
9. **Migration:** legacy `measurementDuration == monthly` → `monthly` vs `daily`.

---

## Domain model summary (target state)

New/updated SwiftData shape (see Phase 1 for migration):

- `FrequencyType`: `daily` | `weekly` | `monthly` | `specificDays` (adds `weekly`, `monthly`; replaces `everyWeek`).
- Quota `N`: per-period target. Either a single `timesPerPeriod: Int` (recommended) or per-frequency fields. Plan assumes a **single `timesPerPeriod`** field for simplicity.
- `TrackingMode`: `eachCompletion` | `periodComplete` (weekly/monthly/specificDays only; daily multi-task forced `periodComplete`).
- Remove `measurementDuration` after migration.
- `TaskCompletion` rows unchanged (append-only, timestamped).

Shared completion engine (PRD §13 pseudo-API):

```text
struct PeriodProgress { periodStart; periodEnd; current(C); target(N); listState }
func periodProgress(for:on:calendar:weekStartDay:) -> PeriodProgress
func canAcceptCompletion(for:on:...) -> Bool
func statCredits(for:in:tracking:) -> Int
```

`listState` ∈ `HIDDEN | INCOMPLETE | PARTIAL | COMPLETE`. Every UI surface (task list, manage completions, stats, streak) calls the engine — never re-implements counting.

---

## Delivery phases overview

| Phase | Focus | Agent role |
|-------|--------|-----------|
| 0 | Decisions, acceptance criteria, doc sync | Product |
| 1 | Data model + SwiftData versioned schema & migration | iOS / SwiftData |
| 2 | Completion engine (period math, state machine) | iOS / Domain logic |
| 3 | Task configuration UI (frequency, times/period, tracking) | iOS / SwiftUI |
| 4 | Task list UI (counter badge, partial highlight, gating) | iOS / SwiftUI |
| 5 | Stats + streak accounting | iOS / Domain logic |
| 6 | Manage completions | iOS / SwiftUI |
| 7 | Notifications alignment | iOS |
| 8 | Localization | iOS / Localization |
| 9 | QA, performance, regression, release | QA / Release |

---

## Phase 0 — Decisions & acceptance criteria

### Step 0.1 — Lock open decisions

**Objective:** Resolve the 9 open decisions above so downstream phases have no ambiguity.

**Inputs/dependencies:** PRD §12, Migration §5, over-completion clarification.

**Deliverable:** A short "Resolved decisions" subsection appended to the PRD (or a `docs/decisions-weekly-monthly.md`) recording the chosen rule for each item.

**Agent prompt:**
```
Read "PRD - Weekly and monthly habits counter.md" §12 (Open decisions), the Completion state machine, and the Migration section.
Produce a decisions log answering each open item with a single concrete rule (no options).
Default recommendations: N=1 weekly/monthly = visible every day, one tap completes the period, no counter;
over-completion = list disables tap-and-hold at COMPLETE, manage-completions may exceed N;
eachCompletion stats count raw completions even when C>N;
specific days + all 7 = weekly profile; specific-days N = count of selected days;
streaks/rewards = use new period-based rules; timezone = Calendar.current;
legacy measurementDuration==monthly = map to daily (preserve perceived behavior) unless product overrides.
Do not write code.
```

**Existing tests that must pass:** N/A (docs only).

**New tests to implement:** None.

---

### Step 0.2 — Feature acceptance criteria

**Objective:** Convert PRD §9 + state machine into Given/When/Then scenarios.

**Inputs/dependencies:** Step 0.1, PRD §9, state machine, `docs/acceptance-criteria.md` (format reference).

**Deliverable:** `docs/acceptance-criteria-weekly-monthly.md` (Gherkin, mirrors existing style).

**Agent prompt:**
```
Read "PRD - Weekly and monthly habits counter.md" (esp. §9 Task list counter, Streak logic, Task list logic,
Manage completions, and the Completion state machine appendix) plus the Step 0.1 decisions log and docs/acceptance-criteria.md for format.
Write docs/acceptance-criteria-weekly-monthly.md covering: configuration per frequency; counter 0/N→N/N for daily/weekly/monthly/specific days;
partial vs full highlight; period reset (day/week/month, respecting weekStartDay); tracking modes (eachCompletion vs periodComplete; daily forced periodComplete);
over-completion (list blocked, manage-completions exceeds N); streaks per frequency/tracking; specific-days visibility; migration mappings.
Documentation only — no code.
```

**Existing tests that must pass:** All `HabitTrackerTests/` + `HabitTrackerUITests/` (no regressions).

**New tests to implement:** None (criteria feed Phases 1–6).

---

### Step 0.3 — Sync data-model doc

**Objective:** Update `docs/data-model.md` to the target shape so it stops contradicting the new model.

**Inputs/dependencies:** Step 0.1.

**Deliverable:** Updated `docs/data-model.md` (FrequencyType adds `weekly`/`monthly`, new `timesPerPeriod`, `TrackingMode`, `measurementDuration` deprecation note, streak definition updated to period-based per tracking).

**Agent prompt:**
```
Update docs/data-model.md to match the new model: FrequencyType = daily|weekly|monthly|specificDays;
add timesPerPeriod (Int) and TrackingMode (eachCompletion|periodComplete); mark measurementDuration as removed (migrated);
update §3.3 and §5.1 (Streak) to the period-based definitions from the PRD. Keep the existing doc style and tables.
Do not change code.
```

**Existing tests that must pass:** N/A.

**New tests to implement:** None.

---

## Phase 1 — Data model & migration

### Step 1.1 — Update model types

**Objective:** Extend the SwiftData model and enums to the target shape.

**Inputs/dependencies:** Phase 0.

**Deliverable:**
- `HabitTracker/Models/Enums.swift`: extend `FrequencyType` (`daily`, `weekly`, `monthly`, `specificDays`); add `TrackingMode`.
- `HabitTracker/Models/HabitTask.swift`: add `timesPerPeriod` (or rename/repurpose `timesPerDay`), add `tracking: TrackingMode`, plan removal of `measurementDuration`.

**Agent prompt:**
```
In the habit-tracker repo, update HabitTracker/Models/Enums.swift and HabitTracker/Models/HabitTask.swift to the target model:
FrequencyType cases daily|weekly|monthly|specificDays; add TrackingMode enum (eachCompletion default, periodComplete);
add `timesPerPeriod: Int` (default 1) and `tracking: TrackingMode` (default .eachCompletion) to HabitTask;
keep measurementDuration for now (removed in migration step) but stop using it in logic.
Follow existing MVVM/@Model conventions. Keep changes compilable. Do not yet wire UI.
```

**Existing tests that must pass:** `HabitTrackerTests/HabitTrackerTests.swift` (enum round-trip, HabitTask defaults) — update only where the model genuinely changed.

**New tests to implement:** Unit — `TrackingMode` raw-value round-trip; new `FrequencyType` cases round-trip; `HabitTask` default `timesPerPeriod`/`tracking`.

---

### Step 1.2 — Versioned schema + migration plan

**Objective:** Implement V1→V2 SwiftData migration per PRD Migration §2–§5.

**Inputs/dependencies:** Step 1.1, decision 0.1#9.

**Deliverable:**
- `VersionedSchema` V1 (old shape) and V2 (new shape).
- `SchemaMigrationPlan` with a custom stage performing the field mapping table.
- Wire into `HabitTracker/HabitTrackerApp.swift` `.modelContainer`.

**Agent prompt:**
```
Implement a SwiftData VersionedSchema (V1 = current HabitTask incl. measurementDuration, frequencyType daily|specificDays|everyWeek, timesPerDay;
V2 = new shape from Step 1.1) and a SchemaMigrationPlan with a custom migration stage that maps per the PRD Migration §3 table:
daily+timesPerDay=1 → daily N=1; daily+timesPerDay>1 → daily N=timesPerDay tracking=periodComplete;
everyWeek → weekly N=timesPerDay tracking=eachCompletion; specificDays → specificDays N=count(scheduledDays) tracking=eachCompletion;
legacy measurementDuration==monthly → per decision 0.1#9. Never modify TaskCompletion rows. Make it idempotent and guarded with logging.
Update HabitTrackerApp.swift to use the migration plan. Then drop measurementDuration from the V2 model.
```

**Existing tests that must pass:** Full suite (no regressions); app launches with an existing store.

**New tests to implement:** Unit/integration — seed a V1 store for each mapping row, run migration, assert resulting V2 config and unchanged `TaskCompletion` count; fresh-install no-op; guarded crash-safety on partial legacy data.

---

## Phase 2 — Completion engine

### Step 2.1 — Period math & PeriodProgress

**Objective:** Implement the shared engine (period boundaries, C, N, list state) per state machine §1–§5.

**Inputs/dependencies:** Phase 1, `AppSettings.weekStartDay`.

**Deliverable:** New `HabitTracker/Services/PeriodService.swift` (or extend `StatisticsService`) exposing `periodProgress(...)`, `canAcceptCompletion(...)`, period boundary helpers for day/week(weekStartDay)/month.

**Agent prompt:**
```
Create HabitTracker/Services/PeriodService.swift implementing the PRD §13 pseudo-API.
periodStart/periodEnd for daily (midnight), weekly (weekStartDay from AppSettings), monthly (calendar month) using Calendar.current.
C = count of TaskCompletion in current period; N = task.timesPerPeriod.
listState: HIDDEN (specificDays + today not scheduled), INCOMPLETE, PARTIAL (0<C<N), COMPLETE (C>=N).
canAcceptCompletion: false when COMPLETE or HIDDEN (list rule). Pure functions, fully unit-testable, no UI.
```

**Existing tests that must pass:** `StatisticsService` tests (`weeklyBuckets`, `expectedDaily`, etc.) — keep green; refactor if shared helpers move.

**New tests to implement:** Unit — period boundaries per frequency incl. `weekStartDay` variations and month edges; C/N and `listState` transitions (0/N→PARTIAL→COMPLETE); reset across day/week/month; specificDays visibility; N=1 profiles; over-completion `canAcceptCompletion` returns false at COMPLETE.

---

### Step 2.2 — Completion recording via engine

**Objective:** Route completion creation through the engine so all surfaces share one rule.

**Inputs/dependencies:** Step 2.1.

**Deliverable:** Refactor `recordCompletion` in `HabitTracker/Views/TaskListView.swift` and any completion insertion to consult `canAcceptCompletion` and recompute progress.

**Agent prompt:**
```
Refactor completion recording (TaskListView.recordCompletion and related) to use PeriodService: only insert a TaskCompletion when canAcceptCompletion is true;
after insert, recompute PeriodProgress for UI. Preserve existing reward-trigger and notification-suppression behavior.
Keep MVVM separation; no business logic in views beyond calling the engine/view model.
```

**Existing tests that must pass:** Full suite; reward celebration + notification suppression behavior unchanged.

**New tests to implement:** Unit — recording stops at N on the list; recording updates progress correctly for each frequency.

---

## Phase 3 — Task configuration UI

### Step 3.1 — Schedule section rework

**Objective:** Implement PRD §9 "Task configuration": frequency picker, times-per-period stepper with correct ranges, tracking picker (weekly/monthly/specificDays only), remove measurement period.

**Inputs/dependencies:** Phases 1–2.

**Deliverable:** Updated `HabitTracker/Views/TaskConfigurationView.swift` + `HabitTracker/ViewModels/TaskConfigurationViewModel.swift`:
- Frequency: daily | weekly | monthly | specific days.
- Ranges: daily 1–48; weekly 1–7; monthly 1–30; specific days via weekday selector.
- Tracking picker shown only for weekly/monthly/specificDays when N is in the "partial" range (and not all 7 days); hidden for daily multi-task.
- Remove the "Measurement period" picker.

**Agent prompt:**
```
Update TaskConfigurationView.swift and TaskConfigurationViewModel.swift per PRD §9 Task configuration:
remove the Measurement period picker; frequency = daily|weekly|monthly|specificDays;
show times-per-period stepper with ranges daily 1...48, weekly 1...7, monthly 1...30; specificDays uses the existing weekday selector;
show a Tracking picker (eachCompletion default / periodComplete) ONLY for weekly/monthly and specificDays (and only when not all 7 days), never for daily multi-task.
Bind to timesPerPeriod and tracking. Keep existing styling and localization patterns (NSLocalizedString).
```

**Existing tests that must pass:** Configuration-related tests in `HabitTrackerTests`; app builds.

**New tests to implement:** Unit (view model) — picker visibility logic per frequency/N; range clamping; tracking hidden for daily multi-task. UI (XCUITest) — selecting each frequency shows the right controls.

---

## Phase 4 — Task list UI

### Step 4.1 — Counter badge & partial highlight

**Objective:** Implement PRD §10 counter and partial-highlight visuals.

**Inputs/dependencies:** Phase 2.

**Deliverable:** Updated `HabitTracker/Views/TaskCircleView.swift` (+ a new counter subview) and `HabitTracker/Views/TapAndHoldTaskView.swift`:
- Small `C/N` badge bottom-right of the circle (rounded background, dark/light mode), shown only for multi-task profiles.
- PARTIAL state: outer ring highlighted + check icon + haptic on each completion.
- COMPLETE: existing full-highlight UI; single-task UI unchanged.

**Agent prompt:**
```
Update TaskCircleView.swift and TapAndHoldTaskView.swift to render PeriodProgress.listState:
add a small C/N counter badge (bottom-right, rounded, adapts to dark/light) shown only when N>1 (multi profiles);
PARTIAL = outer ring + check icon + success haptic on completion; COMPLETE = existing full highlight; keep single-task UI identical.
Pull state from PeriodService via the view/view model; respect Reduce Motion. Add accessibility label like "2 of 3 completed this week".
```

**Existing tests that must pass:** Existing UI tests for tap-and-hold/onboarding.

**New tests to implement:** UI (XCUITest) — daily/weekly/monthly multi-task shows 0/3→3/3 and partial→full; single-task unchanged; badge present only for N>1. Snapshot/accessibility checks for dark/light if available.

---

### Step 4.2 — List gating & visibility

**Objective:** Disable tap-and-hold at COMPLETE; apply specificDays visibility; mark completed habit for the whole period.

**Inputs/dependencies:** Steps 2.1, 4.1, decisions 0.1#2/#4/#5.

**Deliverable:** Updated `TaskListView`/`TapAndHoldTaskView` so COMPLETE habits block further completion (over-completion rule), specificDays habits hidden on non-scheduled days, and weekly/monthly habits render completed across the full period.

**Agent prompt:**
```
In TaskListView/TapAndHoldTaskView, gate completion using PeriodService.canAcceptCompletion:
when listState == COMPLETE, render the full-highlight ring and disable tap-and-hold until period reset;
hide specificDays habits when today is not in scheduledDays; keep weekly/monthly habits shown as completed for the entire period.
No changes to manage-completions behavior here.
```

**Existing tests that must pass:** Full UI suite.

**New tests to implement:** UI — completed weekly habit stays completed all week; specificDays hidden off-day; tap-and-hold blocked at COMPLETE.

---

## Phase 5 — Stats & streak accounting

### Step 5.1 — Stats credit per tracking mode

**Objective:** Implement PRD §9 stats accounting (`eachCompletion` vs `periodComplete`; daily forced `periodComplete`).

**Inputs/dependencies:** Phases 1–2, decision 0.1#2 (C>N credit).

**Deliverable:** `statCredits(...)` in `StatisticsService`/`PeriodService` and updated stats consumers (`TaskStatsViewModel`, `StatisticsService.completionCount/Percentage`).

**Agent prompt:**
```
Implement statCredits(for:in:tracking:) and update StatisticsService so completion stats honor tracking mode:
eachCompletion = each raw completion counts (including beyond N per decision 0.1#2); periodComplete = 1 per fully-completed period, 0 otherwise;
daily multi-task always periodComplete. Update TaskStatsViewModel/StatisticsService consumers and expectedCompletions to the new frequency/quota model.
Keep computations pure and tested.
```

**Existing tests that must pass:** `StatisticsService` tests (update expectations where semantics intentionally changed).

**New tests to implement:** Unit — eachCompletion vs periodComplete credit (incl. C>N); daily forced periodComplete (3/3 → 1, 2/3 → 0); weekly/monthly period bucketing.

---

### Step 5.2 — Streaks under new rules

**Objective:** Implement PRD "Streak logic" for daily/weekly/monthly × tracking.

**Inputs/dependencies:** Step 5.1, decision 0.1#6.

**Deliverable:** Rewritten `currentStreak` in `HabitTracker/Models/HabitTask.swift` (or moved into a service) computing consecutive completed periods (periodComplete) or consecutive completed tasks (eachCompletion) per the PRD examples; rewards consume the new streak.

**Agent prompt:**
```
Replace HabitTask.currentStreak with period-based streak logic per the PRD Streak logic section:
daily multi-task & periodComplete = consecutive completed periods; eachCompletion (weekly/monthly) = consecutive completed tasks across periods, with the worked examples (streak 5 vs 1).
Ensure reward triggering (rewardStreakCount) uses the new streak. Keep it pure/testable.
```

**Existing tests that must pass:** Existing streak tests (update to new semantics with documented expectations).

**New tests to implement:** Unit — each PRD streak example (daily N=3 across 2 days → 1; weekly eachCompletion 5 across 2 weeks → 5; weekly periodComplete → 1; monthly equivalents).

---

## Phase 6 — Manage completions

### Step 6.1 — Calendar editing under new model

**Objective:** Preserve retroactive editing; allow exceeding N; recompute period state per PRD Manage completions.

**Inputs/dependencies:** Phases 2 & 5, decisions 0.1#2/#7.

**Deliverable:** Updated `HabitTracker/Views/ManageCompletionsView.swift`: per-day add/remove still works; total completions may exceed N; when `completions >= timesPerPeriod` the habit is COMPLETE until period end; weekly/monthly status updates for the relevant period.

**Agent prompt:**
```
Update ManageCompletionsView to the new model: keep per-day add/remove; allow total completions to exceed timesPerPeriod (calendar is not capped, unlike the task list);
after any edit, recompute period state via PeriodService so a habit becomes COMPLETE for the period when completions>=N (weekly/monthly/specificDays included).
For MULTI_DAILY use the decided edit model (decision 0.1#7). Do not alter task-list gating.
```

**Existing tests that must pass:** Existing manage-completions tests.

**New tests to implement:** UI/unit — adding a day pushes weekly/monthly habit to COMPLETE; calendar may exceed N; removing drops below N and reverts state.

---

## Phase 7 — Notifications alignment

### Step 7.1 — Frequency-aware scheduling (scope check)

**Objective:** Ensure notifications behave sensibly for weekly/monthly (avoid daily nags) or explicitly defer.

**Inputs/dependencies:** Phase 1; product scope confirmation.

**Deliverable:** Either updated `HabitTracker/Services/NotificationService.swift` to schedule per new frequency, or a documented decision to keep current behavior for v1.

**Agent prompt:**
```
Review NotificationService against the new FrequencyType. Either adapt scheduling for weekly/monthly (e.g., don't fire daily for a weekly habit once its period is complete)
or document in the plan that notifications remain unchanged for v1. Implement the chosen option; if implementing, suppress reminders once listState == COMPLETE for the period.
```

**Existing tests that must pass:** Notification-related tests.

**New tests to implement:** Unit — scheduling maps correctly to new frequencies (if implemented); suppression when period complete.

---

## Phase 8 — Localization

### Step 8.1 — Localize new strings

**Objective:** Localize all new UI text across the 12 supported languages.

**Inputs/dependencies:** Phases 3–6.

**Deliverable:** Updated `.strings`/string catalogs for: frequency labels (weekly/monthly), times-per-period steppers, tracking picker labels, counter accessibility strings.

**Agent prompt:**
```
Add and localize all new strings introduced in Phases 3–6 (frequency = Weekly/Monthly, "Times per week/month", tracking option labels,
counter accessibility "X of Y completed this period") across all supported languages, following docs/Feature injection - Multi language.md and existing localization patterns.
```

**Existing tests that must pass:** Localization/multi-language tests if present.

**New tests to implement:** Unit/UI — no missing keys; key screens render in a non-English locale.

---

## Phase 9 — QA, performance & release

### Step 9.1 — Full regression & acceptance pass

**Objective:** Validate the feature against acceptance criteria and guard against regressions.

**Inputs/dependencies:** All phases.

**Deliverable:** Green `HabitTrackerTests` + `HabitTrackerUITests`; acceptance scenarios from Step 0.2 verified; migration validated on a real pre-feature store.

**Agent prompt:**
```
Run the full test suite and execute the acceptance-criteria-weekly-monthly scenarios.
Verify migration on a snapshot of a previous-build store (habits + completions intact). File any gaps as fixes scoped to the relevant phase.
```

**Existing tests that must pass:** Entire `HabitTrackerTests/` + `HabitTrackerUITests/`.

**New tests to implement:** End-to-end — create each habit type, complete to N, verify list/stats/streak; migration e2e.

---

### Step 9.2 — Performance & disk budget

**Objective:** Confirm period/stat computations are efficient at scale and within the disk budget.

**Inputs/dependencies:** Phases 2 & 5.

**Deliverable:** Performance checks for `PeriodService`/stats over a large completion set (e.g., 50 tasks × 1 year), staying within the data-model §8 budget and smooth list scrolling.

**Agent prompt:**
```
Add performance tests for PeriodService/StatisticsService over ~18k TaskCompletion rows (50 tasks × 365 days):
period progress and stat computation must be fast enough for 60fps list rendering. Verify on-device data stays within the docs/data-model.md §8 budget.
```

**Existing tests that must pass:** Any existing performance tests.

**New tests to implement:** Performance — period progress for the full task grid; stats aggregation over 1-year window.

---

## Cross-phase test inventory

**Must stay green throughout:**
- `HabitTrackerTests/HabitTrackerTests.swift` (model round-trips, stats, streaks — updated where semantics intentionally change)
- `HabitTrackerTests/FreemiumTests.swift` (no regressions)
- `HabitTrackerUITests/` (tap-and-hold, onboarding, freemium flows)

**New test suites introduced:**
- Migration tests (Phase 1)
- `PeriodService` engine tests (Phase 2)
- Configuration view-model + UI tests (Phase 3)
- Counter/partial-highlight UI tests (Phase 4)
- Stats-credit + streak tests (Phase 5)
- Manage-completions tests (Phase 6)
- Notification scheduling tests (Phase 7, if implemented)
- Localization key coverage (Phase 8)
- End-to-end + performance (Phase 9)

---

## Sequencing notes

- **Phase 0 gates everything** — do not start Phase 1 until decisions are locked (esp. #2 over-completion, #5 specific-days quota, #9 migration target).
- **Phase 1 → Phase 2 are hard dependencies** for all UI work.
- Phases 3 and 4 can proceed in parallel once Phase 2 lands; Phase 5 depends on Phase 2; Phase 6 depends on Phases 2 & 5.
- Phase 8 (localization) should trail UI-complete phases to avoid re-translating churned strings.
