# Acceptance Criteria

Derived from the functional requirements and user journeys in [prd.md](prd.md).

---

### Onboarding (ref: 4.2)

- **Given** the user opens the app for the first time,
  **When** the onboarding flow starts,
  **Then** the app shows an example task (e.g. "Walk the dog") and teaches the tap-and-hold gesture to complete it.

- **Given** the user is in the onboarding flow,
  **When** the tap-and-hold tutorial is completed,
  **Then** the app communicates the goal message: "Your goal is to build a streak of consecutive days."

- **Given** the user has seen the goal message,
  **When** the onboarding continues,
  **Then** the user is prompted to create their first task before reaching the task list.

---

### FR-1: Tap and hold to complete a task

- **Given** a task is visible in the task list and is not yet completed for the current period,
  **When** the user taps and holds the task circle for at least 2 seconds,
  **Then** a progress line gradually fills around the circle, the circle turns white, a haptic feedback is triggered, and the task is marked as completed.

- **Given** the user is pressing and holding a task circle,
  **When** the user releases their finger before 2 seconds have elapsed,
  **Then** the progress line retracts and disappears, and the task remains incomplete.

---

### FR-2: Task list

- **Given** the user has created one or more tasks,
  **When** the task list is displayed,
  **Then** tasks are shown in a 2-column grid, each represented by a circle with its icon and title underneath.

- **Given** the task list is displayed,
  **When** the user taps the category dropdown at the top,
  **Then** a list of task categories is shown including an "All" option.

- **Given** the user selects a specific category from the dropdown,
  **When** the filter is applied,
  **Then** only tasks belonging to that category are displayed in the grid.

- **Given** the user selects "All" from the category dropdown,
  **When** the filter is applied,
  **Then** all tasks are displayed regardless of category.

- **Given** the task list is displayed,
  **When** the user taps the plus button in the top right,
  **Then** the new task selector view is opened.

---

### New task selector (ref: FR-x)

- **Given** the user is on the new task selector view,
  **When** the view loads,
  **Then** a custom task name input field with a button is shown at the top, followed by a category tab bar (Health, Fitness, Learning, Social) and a vertical list of preset tasks.

- **Given** the custom task name field is empty,
  **When** the user views the button next to the field,
  **Then** the button is disabled/inactive.

- **Given** the user has typed a custom task name,
  **When** the text field is non-empty,
  **Then** the button becomes active, and tapping it navigates to the task configuration view.

- **Given** the preset category tab bar is displayed,
  **When** the user taps a category tab (e.g. "Fitness"),
  **Then** the vertical list below filters to show only preset tasks in that category.

- **Given** the preset task list is displayed,
  **When** the user taps a preset task (e.g. "Meditate"),
  **Then** the app navigates to the task configuration view with the preset values (icon, title, goal type) pre-filled.

---

### FR-3: Task configuration

- **Given** the user opens the task configuration for a preset task,
  **When** the configuration view loads,
  **Then** the icon, title, category, and goal type are pre-filled based on the preset definition, and all fields remain editable.

- **Given** the user opens the task configuration for a custom task,
  **When** no icon has been selected,
  **Then** the first two initials of the task name are displayed in place of an icon.

- **Given** the user is configuring a task,
  **When** the user sets the measurement duration,
  **Then** the available options are: daily, weekly, and monthly.

- **Given** the user is configuring a task,
  **When** the user sets the goal,
  **Then** the available goal types are: no goal, number of times/repetitions, time (hours, minutes, seconds), number of cups, calories, distance (km, meters, etc.), weight (kg, g, etc.), capacity (liters, millilitres, etc.).

- **Given** the user is configuring a task,
  **When** the user sets frequency and planning,
  **Then** the user can choose daily (one or multiple times a day) or specific days of the week.

- **Given** the user is configuring a task,
  **When** the user enables push notifications and sets a reminder time,
  **Then** a local push notification is scheduled according to the chosen frequency and time.

- **Given** a push notification is scheduled for a task,
  **When** the task is completed before the scheduled notification time,
  **Then** the notification is not sent.

- **Given** the user is configuring a task,
  **When** the user selects a task color,
  **Then** the task circle and associated UI elements reflect the chosen color.

- **Given** the user is configuring a task,
  **When** the user assigns or changes the task category,
  **Then** the task appears under the selected category in the task list filter.

- **Given** the user is configuring a task,
  **When** the user creates a new custom category from the category picker,
  **Then** the new category is saved and available for future tasks and in the task list dropdown.

- **Given** the user has finished configuring a task,
  **When** the user taps the save button,
  **Then** the task is persisted locally, and the user is returned to the task list where the new task is visible.

---

### FR-4: Task stats

- **Given** the user opens task stats for a specific task,
  **When** the stats view loads,
  **Then** the task name and icon are shown centered at the top, followed by a time window selector, the number of completions, the completion percentage, and a trend line chart.

- **Given** the stats view is displayed with default settings,
  **When** no time window has been manually selected,
  **Then** the stats are filtered to the last 30 days.

- **Given** the selected time window is less than 60 days,
  **When** the trend line chart is rendered,
  **Then** the x-axis frequency is 7 days (weekly data points).

- **Given** the selected time window is 60 days or more,
  **When** the trend line chart is rendered,
  **Then** the x-axis frequency switches to monthly data points.

---

### FR-4.1: Time window selector

- **Given** the user is on the task stats view,
  **When** the user taps the time window selector,
  **Then** a full-page date picker opens showing the current month with no dates initially selected.

- **Given** the full-page date picker is open,
  **When** the user scrolls up,
  **Then** earlier months are shown (going back in time).

- **Given** the full-page date picker is open,
  **When** the user scrolls down,
  **Then** later months are shown (going forward in time).

- **Given** no date is currently selected in the picker,
  **When** the user taps a single day,
  **Then** that day is highlighted as the start of the window.

- **Given** one day is already selected (start of window),
  **When** the user taps a second day,
  **Then** the second day and all days in between are highlighted, defining the time window.

- **Given** a time window (two dates) is already selected,
  **When** the user taps a third day,
  **Then** the previous selection is cleared and the tapped day becomes the new start of a new window selection.

---

### FR-7: Task menu

- **Given** the user is on the task list,
  **When** the user performs a single fast tap on a task circle,
  **Then** a small context menu appears with three options: Stats, Edit, and Remove.

- **Given** the task menu is open,
  **When** the user taps "Stats,"
  **Then** the app navigates to the task stats view for that task.

- **Given** the task menu is open,
  **When** the user taps "Edit,"
  **Then** the app navigates to the task configuration view pre-filled with the task's current settings.

- **Given** the task menu is open,
  **When** the user taps "Remove,"
  **Then** the task is deleted and removed from the task list.

- **Given** the task menu is open,
  **When** the user taps outside the menu,
  **Then** the menu closes without any action.

---

### Bug Fixes – Completion Ring Alignment

- **Given** a task circle is shown in the task list,
  **When** the user taps and holds to complete a task,
  **Then** the progress ring is visually centered over the task circle, not offset by the title text below.

---

### Bug Fixes – Task Menu Single Tap

- **Given** the user is on the task list,
  **When** the user performs a single fast tap (not a long press) on a task circle,
  **Then** the task menu appears with Stats, Edit, and Remove options.

---

### Bug Fixes – First Completion Counted in Stats

- **Given** the user completes a task for the first time today,
  **When** the user opens the task stats,
  **Then** the completion is immediately reflected in the completion count and percentage for the current time window.

---

### Bug Fixes – Measurement Units in Task Config

- **Given** the user has set the measurement system to "US Customary" in Settings,
  **When** the user creates or edits a task and selects a distance goal,
  **Then** the available unit options are "ft" and "mi" (not "m" and "km").

- **Given** the user changes the measurement system in Settings,
  **When** the user opens any task configuration,
  **Then** all goal unit options (distance, weight, capacity) reflect the selected measurement system.

---

### Bug Fixes – Date Picker Defaults

- **Given** the user is on task stats,
  **When** the user opens the time window date picker,
  **Then** the picker displays the current month in view, with the last 30 days pre-selected.

---

### Bug Fixes – Date Picker Weekday Headers

- **Given** the user opens any date picker (stats time window or manage completions),
  **When** the weekday headers are displayed,
  **Then** all seven day abbreviations are visible (M, Tu, W, Th, F, Sa, Su) without duplicates being merged.

---

### Bug Fixes – Stats Trend Line Week Alignment

- **Given** the user has set the week start day to Monday in Settings,
  **When** the stats trend line is displayed with weekly buckets,
  **Then** each weekly data point aligns with Monday as the start of the week.

- **Given** the user has set the week start day to Sunday in Settings,
  **When** the stats trend line is displayed,
  **Then** each weekly data point aligns with Sunday as the start of the week.

---

### Bug Fixes – Category Management in Settings

- **Given** the user is on the Settings screen viewing categories,
  **When** the user swipes left on a custom (non-built-in) category,
  **Then** both "Delete" and "Rename" options appear.

- **Given** a custom category has tasks assigned to it,
  **When** the user deletes that category,
  **Then** a confirmation dialog warns that tasks will become uncategorized, and upon confirmation, linked tasks have no category.

- **Given** a category is a built-in preset,
  **When** the user views it in Settings,
  **Then** no delete or rename actions are available.

---

### Bug Fixes – Week Start in Task Config

- **Given** the user has set the week start day to Sunday in Settings,
  **When** the user opens the task configuration and selects "Specific Days",
  **Then** the weekday picker starts with Sunday on the left.

---

### Bug Fixes – Add Task Button Background

- **Given** the task list is displayed,
  **When** the user views the "+" add task button in the toolbar,
  **Then** there is no visible background halo different from the app background around the button.

---

### Bug Fixes – Empty Categories in Dropdown

- **Given** a category exists but has no tasks assigned,
  **When** the user opens the category dropdown on the task list,
  **Then** that empty category is not shown in the dropdown.

---

### Bug Fixes – Measurement Units Picker Label

- **Given** the user opens Settings and views the Measurement Units section,
  **When** the picker is displayed inline,
  **Then** the word "Units" does not appear as a non-selectable item in the list.

---

### FR-8: General Stats Section

- **Given** the user is on the task list,
  **When** the user taps the stats icon in the bottom bar,
  **Then** a general stats view opens showing aggregated completions, average completion percentage, and a trend chart for all tasks.

- **Given** the general stats view is open,
  **When** the user selects a specific category from the dropdown,
  **Then** all displayed stats (completions, percentage, trend chart) are filtered to only include tasks from that category.

- **Given** the general stats view is open with "All" selected,
  **When** the user opens the time window picker and selects a date range,
  **Then** the stats update to reflect the selected date range.

---

### FR-9: Goal Quantity Stepper

- **Given** the user is configuring a task with a non-"No Goal" goal type,
  **When** the goal value input is displayed,
  **Then** a stepper control is shown instead of a free-text field.

- **Given** the goal type is "Calories",
  **When** the stepper is displayed,
  **Then** the minimum value is 10 and each step increments by 10.

- **Given** the goal type is any other type (distance, times, cups, etc.),
  **When** the stepper is displayed,
  **Then** the minimum value is 1 and each step increments by 1.

---

### FR-10: "Every Week" Frequency

- **Given** the user is configuring a task's schedule,
  **When** the user selects "Every Week" as the frequency,
  **Then** a "Times per week" stepper appears (range 1–7) and no specific-day picker is shown.

---

### FR-11: Onboarding Text

- **Given** the user opens the app for the first time,
  **When** the onboarding welcome screen is displayed,
  **Then** the title reads "Small habits, massive change." and the subtitle reads "Track your daily habits and stay motivated."

---

### FR-13: App Icon

- **Given** the app is installed on a device,
  **When** the user views the home screen,
  **Then** the app icon shows a blue-to-indigo gradient with a white circular progress ring and checkmark.
