# Acceptance Criteria — Objectives (on-device Apple Intelligence)

Derived from [PRD - objectives.md](/Users/maurizio.bellini/Documents/Vault/Product/Ring%20habit/PRD%20-%20objectives.md) and the rulings in [Implementation-Plan-Objectives.md](/Users/maurizio.bellini/Documents/Vault/Product/Ring%20habit/Implementation-Plan-Objectives.md). Where they conflict, the plan's "Corrections" and "Rulings" sections win.

---

### Availability gate (ref: PRD §8.1)

- **Given** the device runs iOS 26+, Apple Intelligence is available and the model supports the app's in-app language,
  **When** the user taps +,
  **Then** the "Add habit / Add from objective" bottom sheet opens.

- **Given** the device is not eligible, Apple Intelligence is turned off, the model is not ready, or the app language is not supported,
  **When** the user taps +,
  **Then** today's new task selector opens directly, with no bottom sheet.

- **Given** the user turns Apple Intelligence on (or the model finishes downloading) while the app is running,
  **When** the user taps + again,
  **Then** the bottom sheet appears without restarting the app.

- **Given** the user turns Apple Intelligence off while the app is running,
  **When** the user taps + again,
  **Then** today's selector opens directly.

- **Given** the device language is supported but the in-app language set in Settings is not,
  **When** the user taps +,
  **Then** the feature is off.

- **Given** objectives are unavailable,
  **When** the user browses any screen of the app,
  **Then** there is no mention of objectives or Apple Intelligence anywhere.

- **Given** the objectives configurator is open,
  **When** the model becomes unavailable during a search,
  **Then** the generic error is shown, habits already added stay, and the gate applies again on the next + tap.

---

### Bottom sheet (ref: PRD §8.2)

- **Given** the bottom sheet is open,
  **When** it renders,
  **Then** it shows "Add habit" with "Create a single custom habit" and a ring icon, and "Add from objective" with "Get habit suggestions to reach an objective" and a sparkles icon (not the Apple Intelligence logo).

- **Given** the bottom sheet is open,
  **When** the user picks "Add habit",
  **Then** the existing new task selector opens.

- **Given** the bottom sheet is open,
  **When** the user picks "Add from objective",
  **Then** the objectives configurator opens.

---

### Configurator initial state (ref: PRD §8.3)

- **Given** the configurator opens,
  **When** it renders,
  **Then** it shows the auto-scrolling preset carousel, the title "Describe what you want to achieve", a one-line text area with placeholder "I want to...", a disabled "Get habits" button and the footnote "Suggestions are generated on your iPhone".

- **Given** the text area is empty,
  **When** the user types any non-blank text,
  **Then** "Get habits" becomes enabled; clearing the text disables it again.

- **Given** the user types beyond one line,
  **When** text no longer fits,
  **Then** the text area grows to show it.

- **Given** the user types,
  **When** the text reaches 200 characters,
  **Then** no further characters are accepted.

- **Given** the preset carousel is visible,
  **When** the user taps a preset pill,
  **Then** generation starts immediately for that objective.

---

### Generation and results (ref: PRD §8.3, §8.6)

- **Given** the user submits an objective,
  **When** the model is generating,
  **Then** pulsing skeleton cards are shown, the objective moves to the top, and the criteria sentence appears under it.

- **Given** generation is in progress,
  **When** each habit finishes and passes the evaluator,
  **Then** its card replaces a skeleton straight away without waiting for the others.

- **Given** a card is shown,
  **When** the user reads it,
  **Then** it shows a title, a short description, and the frequency and goal (e.g. "Weekly · 3 times · 30 min").

- **Given** results are shown,
  **When** the user taps "Generate more",
  **Then** 3–5 new cards are appended and none repeats an already proposed title.

- **Given** results are shown,
  **When** the user types a refinement and taps "Refine",
  **Then** new cards are appended using the initial objective, all refinements and the proposed titles; earlier cards and their added state stay.

- **Given** results are shown,
  **When** the user taps "New search",
  **Then** cards, criteria and refinements are cleared, the model session is discarded, and the configurator returns to its initial state.

- **Given** the request is inappropriate or not about self-improvement,
  **When** the policing step or Apple's guardrails reject it,
  **Then** "We cannot suggest anything for that request" is shown and no cards appear.

- **Given** generation fails, the model is unavailable or the system rate-limits,
  **When** the pipeline ends,
  **Then** "Something went wrong. Try again." is shown with a "Try again" button that re-runs the same request.

- **Given** fewer than 3 habits pass the evaluator,
  **When** the single retry still yields 1–2,
  **Then** those cards are shown with no error; if none pass, the generic error is shown.

- **Given** generation is running,
  **When** the user closes the configurator or taps "New search",
  **Then** generation stops and no late cards appear.

---

### Adding proposals (ref: PRD §7.1, §8.3)

- **Given** a proposal card that is not yet added,
  **When** the user taps it,
  **Then** the task configurator opens prefilled with the title, icon, frequency, times per period and goal.

- **Given** the prefilled configurator,
  **When** the user goes back without saving,
  **Then** nothing is saved and the card is unchanged.

- **Given** the prefilled configurator,
  **When** the user edits any value and saves,
  **Then** the habit is created with the edited values, the user is back on the proposal list, and the card shows "Added".

- **Given** the user added one proposal,
  **When** they tap another card,
  **Then** they can add it too; all added habits appear on the task list after closing the configurator.

---

### Free plan (ref: PRD §8.3 "Searches and free plan")

- **Given** a free user at the habit limit,
  **When** they tap +,
  **Then** the paywall opens, exactly as today, before any bottom sheet.

- **Given** a free user at the habit limit inside the configurator,
  **When** they tap a proposal card,
  **Then** the paywall opens with source `objective_proposal` instead of the task configurator.

- **Given** that paywall,
  **When** the user upgrades,
  **Then** the task configurator opens prefilled with the tapped proposal.

- **Given** that paywall,
  **When** the user dismisses it,
  **Then** they are back on the proposal list with all proposals intact.

- **Given** a free user with 1 habit,
  **When** they add one proposal and tap a second card,
  **Then** the paywall opens.

- **Given** a free user at the limit,
  **When** they search, refine, generate more or start a new search,
  **Then** none of these are gated.

---

### Accessibility and localization (ref: PRD §9)

- **Given** Reduce Motion or VoiceOver is on,
  **When** the configurator is open,
  **Then** the preset carousel does not auto-scroll and skeletons do not pulse.

- **Given** VoiceOver is on,
  **When** the user focuses a card,
  **Then** it reads the title, frequency and goal, and "Added" when added.

- **Given** the largest accessibility text size,
  **When** the bottom sheet and configurator render,
  **Then** all text is readable without clipping.

- **Given** the in-app language is any of the 7 app languages,
  **When** the user uses the feature,
  **Then** all UI, preset titles and generated suggestions are in that language.

---

### Privacy and analytics (ref: PRD §10.7, §10.8)

- **Given** any objectives session,
  **When** analytics events are sent,
  **Then** no event contains objective text, refinement text, criteria, generated titles or summaries.

- **Given** the device is offline,
  **When** the user submits an objective,
  **Then** suggestions are still generated (fully on device).

- **Given** the user taps +,
  **When** `add_habit_tapped` is sent,
  **Then** it carries `objectives_available` as `true` or `false`.

- **Given** a habit is saved from a proposal,
  **When** `habit_created` is sent,
  **Then** its `source` is `objective`.
