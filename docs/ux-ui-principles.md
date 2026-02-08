# UX & UI Principles

> Guidelines, not designs. This document defines the visual and interaction principles for the Habit Tracker app. All implementation decisions should align with these guidelines.

---

## 1. Design Philosophy

- **Minimal and focused** -- one primary action per screen; no clutter. Every element on screen must earn its place.
- **Delight through motion** -- the tap-and-hold ring fill, completion animation, and haptic feedback are core to the brand. Every interaction should feel tactile and rewarding.
- **Streak-inspired visual language** -- large circular task icons in a 2-column grid, bold color accents per task, generous whitespace.
- **Progressive disclosure** -- show only what the user needs at each step: task list → task menu → task configuration → stats. Never overwhelm the user with options up front.

---

## 2. Layout & Spacing

- **Task grid**: 2-column grid for the task list with a consistent 16pt gutter and 16pt outer padding.
- **Safe areas**: all layouts must respect safe areas (Dynamic Island, home indicator, status bar). Never place interactive elements in unsafe regions.
- **Modals and sheets**: use card/sheet-based modals for task configuration, stats, and the date picker. Prefer `.sheet` and `.fullScreenCover` over navigation pushes for focused workflows.
- **Navigation chrome**: category tab bar sits at the top of selector views. The task list features a floating "+" button (top-right) for adding new tasks.
- **Consistency**: maintain uniform padding, corner radii, and spacing tokens across all screens. Define spacing as multiples of 4pt (4, 8, 12, 16, 24, 32).

---

## 3. Typography

- **System font**: use Apple San Francisco (SF Pro) exclusively. Do not bundle custom fonts.
- **Type scale**:
  - **Large Title / Title 1** -- screen headers (e.g., "My Habits")
  - **Headline** -- task names rendered inside circles
  - **Subheadline** -- secondary information (streak counts, category labels)
  - **Caption** -- tertiary details (percentages, dates on charts)
- **Dynamic Type**: all text must scale with the user's preferred text size. Use SwiftUI built-in text styles (`.font(.headline)`) rather than fixed point sizes.
- **Line length**: keep body text under 70 characters per line for readability.

---

## 4. Color System

- **Task accent colors**: each task carries a user-selected accent color. This color is used for the ring fill animation, icon tint, chart trend line, and category badge.
- **Background**: use `Color(.systemBackground)` and `Color(.secondarySystemBackground)` so the app adapts to light and dark mode automatically.
- **Semantic tokens**: use SwiftUI semantic colors (`.primary`, `.secondary`, `.accentColor`) throughout. Never hardcode hex values in views.
- **Contrast requirements**: all text and icon combinations must meet WCAG AA contrast ratios -- 4.5:1 for body text, 3:1 for large text and UI components.
- **High-contrast mode**: support the iOS Increase Contrast accessibility setting by providing alternative color values where needed.
- **Palette**: offer a curated set of 12-16 task accent colors that are vibrant in both light and dark modes. Avoid pure white or pure black as accent choices.

---

## 5. Iconography

- **SF Symbols only**: use Apple's SF Symbols as the sole icon set (5,000+ glyphs). They scale with Dynamic Type, support variable rendering, and require no additional assets.
- **Rendering modes**: prefer **hierarchical** or **palette** rendering to align icons with the task's accent color. Use **monochrome** for toolbar/navigation icons.
- **Icon sizing**: match the text style they accompany (e.g., a `.headline`-sized icon next to a `.headline`-sized label).
- **Custom task fallback**: when no icon is selected for a custom task, display the first 2 initials of the task name inside the circle, rendered in the task's accent color on a tinted background.

---

## 6. Motion & Haptics

- **Tap-and-hold completion ring**:
  - Duration: 2 seconds.
  - A circular progress stroke fills around the task circle over the hold duration.
  - If the user releases early, the ring reverses smoothly with an ease-out curve back to zero.
  - On completion, the ring fully closes and transitions into the completion state.

- **Completion burst**:
  - A subtle scale-up + opacity "pop" on the circle when the task completes.
  - Paired with a `.success` haptic feedback (`UINotificationFeedbackGenerator`).
  - The circle background transitions to its completed state (filled/white).

- **Sheet transitions**: use SwiftUI's default `.sheet` spring animation. Avoid custom springs to keep the app feeling native.

- **Chart animations**: animate data points on appear with a staggered fade-in (50ms delay between points).

- **Animation budget**: keep non-completion interactions under 300ms total to maintain a snappy, responsive feel.

- **Reduce Motion**: when the user has enabled Reduce Motion (`UIAccessibility.isReduceMotionEnabled`), replace all animated transitions with instant state changes. The ring-fill animation should become an immediate fill + checkmark appearance.

---

## 7. Accessibility

- **VoiceOver**:
  - Every interactive element must have an `accessibilityLabel` (what it is) and an `accessibilityHint` (what it does).
  - Task circles: label = "{task name}, {completion status}"; hint = "Double tap to open task menu" or "Double tap and hold to complete".
  - Group related elements (icon + label) into single accessibility elements where appropriate.

- **Tap-and-hold alternative**:
  - The long-press gesture is not accessible via VoiceOver by default.
  - Provide an `.accessibilityAction(.default)` that completes the task with a single activation when VoiceOver is on.
  - Announce completion via `UIAccessibility.post(notification: .announcement)`.

- **Dynamic Type**:
  - All UI must remain functional and usable up to Accessibility Extra Extra Extra Large (AX5/xxxLarge).
  - At very large sizes, the 2-column grid may collapse to 1 column to prevent clipping.

- **Touch targets**: minimum 44x44pt for all interactive elements per Apple Human Interface Guidelines.

- **Color independence**: never rely on color alone to convey task state (complete vs. incomplete). Always pair color with an icon change, checkmark, or text label.

- **Smart Invert**: ensure custom colors are marked with `accessibilityIgnoresInvertColors` where appropriate (e.g., task accent colors should not be inverted).

---

## 8. Dark Mode

- **Full support**: the app must look complete and intentional in both light and dark appearances. Dark mode is not an afterthought.
- **Semantic colors**: by using SwiftUI semantic color tokens, most views adapt automatically. Avoid any appearance-conditional logic in views.
- **Task accent vibrancy**: accent colors should remain vibrant in dark mode. If a color appears washed out on dark backgrounds, provide a darker-mode variant with increased saturation or brightness.
- **Charts**: axis lines, grid lines, and text labels must be clearly visible on dark backgrounds. Use `.secondary` label color for axes.
- **Testing**: always preview every screen in both light and dark mode during development (Xcode preview or simulator toggle).

---

## 9. Onboarding UX

- **Screen count**: maximum 3 onboarding screens. Keep it short; the app should be self-explanatory.
- **Screen 1 -- Welcome**: communicate the app's purpose: "Build streaks. Form habits." Show the app icon and a brief tagline.
- **Screen 2 -- Interactive tutorial**: demonstrate the tap-and-hold mechanic with a sample task (e.g., "Walk the dog"). The user must successfully complete the demo task to proceed. This ensures they learn the core interaction before seeing the real app.
- **Screen 3 -- First task creation**: funnel directly into the task selector so the user creates their first real task. The app is useless without at least one task, so this step reduces time-to-value.
- **Skip option**: a skip/dismiss option must be visible on every onboarding screen. Never trap the user.
- **No sign-up wall**: the app is local-only; there is no account to create. Onboarding leads straight into the task list.
- **Re-discoverability**: the tap-and-hold tutorial should be accessible from a "Help" or "Tips" section in settings for users who skipped onboarding.

---

## 10. Localization / i18n Strategy

### 10.1 Technical Principles

- All user-facing strings must be externalized into `.xcstrings` (Xcode 15+ String Catalogs). No hardcoded strings in SwiftUI views.
- Use the `String(localized:)` API for all localizable text.
- Handle pluralization via String Catalog plural rules (zero, one, few, many, other) -- do not construct plural forms via string concatenation.
- Use `Foundation` formatters for numbers, dates, distances, and durations. These automatically respect the user's locale.
- Preset task names and category names must also be localized.
- Layout must accommodate approximately 30% text expansion (common in German and Portuguese) without truncation or overlapping.

### 10.2 Recommended Languages

12 locales selected for maximum global reach while avoiding RTL layouts and complex script rendering.

| Priority | Language            | Locale | Script         | Est. Speakers | Rationale                                                       |
| -------- | ------------------- | ------ | -------------- | ------------- | --------------------------------------------------------------- |
| P0       | English             | en     | Latin          | 1.5B          | Default / base language                                         |
| P1       | Spanish             | es     | Latin          | 560M          | Largest L2 after English; huge App Store market (LATAM + Spain) |
| P1       | Portuguese (Brazil) | pt-BR  | Latin          | 220M          | Brazil is a top-5 iOS market                                    |
| P1       | French              | fr     | Latin          | 280M          | Strong in Europe + Africa App Store                             |
| P2       | German              | de     | Latin          | 130M          | High-revenue iOS market in DACH region                          |
| P2       | Italian             | it     | Latin          | 85M           | Aligns with developer locale; strong EU market                  |
| P2       | Dutch               | nl     | Latin          | 25M           | High smartphone penetration, wealthy market                     |
| P2       | Indonesian          | id     | Latin          | 200M          | Massive user base, Latin script, growing iOS share              |
| P3       | Turkish             | tr     | Latin          | 80M           | Large market, Latin script                                      |
| P3       | Vietnamese          | vi     | Latin          | 85M           | Fast-growing mobile market, Latin script with diacritics        |
| P3       | Polish              | pl     | Latin          | 45M           | Largest Central European market                                 |
| P3       | Russian             | ru     | Cyrillic (LTR) | 260M          | Large market; Cyrillic is LTR so no layout changes needed       |

### 10.3 Explicitly Excluded

- **RTL languages** (Arabic, Hebrew, Urdu, Persian) -- would require fully mirrored layouts, flipped animations, and bidirectional text handling. Adds significant engineering and QA complexity.
- **CJK languages** (Chinese, Japanese, Korean) -- require CJK font bundles, segmented line-breaking rules, and potentially different grid sizing. Deferred to a future phase if download metrics warrant the investment.
- **Indic scripts** (Hindi, Bengali, Tamil) -- complex ligature rendering and variable glyph widths. Deferred.
- **Thai** -- no inherent word boundaries; requires ICU segmentation for proper line-breaking. Deferred.

### 10.4 Rollout Approach

- **Phase 1 (MVP)**: English only.
- **Phase 1.1**: P1 languages -- Spanish, Portuguese (Brazil), French.
- **Phase 1.2**: P2 languages -- German, Italian, Dutch, Indonesian.
- **Phase 2**: P3 languages -- Turkish, Vietnamese, Polish, Russian.
