# Project Requirements – <Habit Tracker>

## 1. Overview
**The to-do list that helps you form good habits:**  
The best way to improve yourself is to create small habits. The app allows you to track tasks you want to complete each day in order to form a habit. This app should be a copy/cut of the most famous app streak

**Context:**  
We want to demonstrate that we can build clones of existing apps via AI code generation. Habit trackers are very popular apps and relatively easy to create. We can create a personal habit tracker with no need to create api services, authentication, cloud to store user data.

**Goals:**
- Create an iOS habit tracker with a very nice catching and smooth ui
- It needs to be similar to the popular habit tracker called Streak
- It needs to be easy to sell on app store


---

## 2. Success Criteria
How do we know this project is successful?

**Business Metrics:**
- App Store downloads	Total new installs (organic + search)	
- Day-7 retention >= 20%	
- Conversion rate (impression to download) % of App Store page visitors who install	>= 30%	
App Store rating Average star rating on the App Store	

**User Metrics:**
- Activation rate	% of installers who complete onboarding and create their first task	>= 70%	
- Time to first task	Elapsed time from first app open to first task creation	 < 2 minutes	
- Average tasks per user	Mean number of active tasks per user	3-5 tasks	


**Technical / Quality Metrics:**
- Cold launch to task list	< 1 second
- Tap-and-hold ring animation frame rate	Sustained 60 fps Sustained 60 fps (zero dropped frames)
- App binary size < 15 MB (download), < 30 MB (install)
 -Crash-free sessions	>= 99.5%	
 - Unit test coverage (business logic) >= 80% line coverage		
- UI test coverage All acceptance criteria in acceptance-criteria.md have at least one XCUITest	
- App Store review pass rate: First-time approval	
- Energy impact: "Low" energy impact rating	
- Disk usag: < 10 MB on-device data for typical user (50 tasks, 1 year of completions)	

---

## 3. Target Users
Describe the primary users and their needs.

**Primary User:**
- Self improvement oriented people
- Users who wants to create habits
- Keep track on paper, spreadsheets or similar apps


---

## 4. User Journeys
High-level flows (not UI yet).

### 4.1 Add tasks
- Click on Add task button
- A task category tab on top allow  you to navigate across multiple pre determined tasks. 
- You can create your own custome task
- Inside the single task configurator you can set up: measurement duration (day long task, week long task, month long task), Goal (how many minutes), frequency (1 time a day, 2 times a day, etc.), task days (every day, every second second day, x times a day, specific days of the week), notification (no reminder, automatic, custom, set sound), task color, category (in this case user category), set action button, save task button
- When taks is saved is then visible in the task list
- Once the configuration is completed user is on task list and task icon and title are visible


### 4.2 Onboarding flow
- Teaches the tap and hold to complete a task
- Show you one example of task (ex: walk the dog) and how to tap and hold to complete
- Communicate app goal: "Your goal is to build a streak of consecutive days"
- Make you create your first task

---

## 5. Functional Requirements
What the system must do.

### 5.1 Core Features
- **FR-1: Tap and hold to complete a task**
Tasks are represented by a round with the icon and task name underneath. When user wants to complete a task they can tap on it holding their finger for about 2 seconds. When tap and hold a lline around the round shape load filling gradually all around till the end of 2 seconds. If user releases the tap before 2 seconds then the line return back and disappears. After 2 seconds the line fully fills the entire circle then the round becomes white and an haptic is felt by user. The task is completed.


- **FR-2: Task list**  
Task list show in a grid of 2 columns each task created by the user. Each task is represented by a circle with icon and title underneath. On top of the task list a drop down list shows the task categories. When user taps on it can quickly filter the categories in the task list. The drop down list also has a “all” element to show all items

On the top right a prominent plus button is shown. When user taps on the plus button then they can add a new task accessing to new task selector

A single click on the task opens up the task menu

**FR-3:  New task selector**
Tasks selector view is shown when user adds a new task. Task selector shows the following functionalities from top:
Create custom task: a form fields accept task name as first custom task field. The field has a button next to it. After task name is field, button is active. If user clicks goes to task configuration 
A pre set task category tab: this filter the preset tasks below. The categories are: health, fitness, learning, social, 
This is the list of preset tasks (preset goal in brakets)
Category: fitness
- Walk (distance)
- Run (distance)
- Bike (distance)
- Push ups (repetition number)
- Pull ups (repetition number)
- Gym (time)
- Swim (time)
Category: health
- Meditate (time)
- Eat a healthy meal (task completion)
- Write journal (time)
- Walk the dog (time)
- Take vitamins (task completion)
- Drink water (cups)
- Decrease caffeine (cups)
- Decrease calories intake (calories)
- Dont smoke (no goal)
- Dont bite nails (no goal)
- Time in daylight (time)
- Bed time early (no goal)
- Wash hands (no goal)
- Floss your tiith (no goal)
Category: social
- Call parents (time)
- Call a friend (time)
- Ask a friend out (no goal)
- Kiss partner (no goal)
- Talk to a stranger (no goal)
Category: learning:
- Learn a language (time)
- Read a book (time)
- Play instrument (time)

Each preset task is shown in a vertical list with icon and name
Category tab filters the vertical list
When user clicks on a preset task then goes to task configuration
User can always change the preset goal of the preset task in task configurator

**FR-3: Task configuration**
When user creates or edit an existing task they access to its configuration. The configuration allows user to define the following task properties:

Select icon: if tasks is predefined then icon is prefilled. Even if prefilled user can still change it. If task is custom then user can select an icon from a multitude of available icons. If no icon is selected for a custom task then the first 2 initials of the task name are used to be displayed instead of the icon.
- Title: if task is predefined then it’s prefilled and can be editable
- Goal: user can select the goal of the task. If it is a preset task the goal is pre defined by the task. If it’s a time based task for example user can selct how much is the duration of the task. Ex 5 min. Or 2 hours. These are the possible goal types: no goal (just completion is the goal), number of times/repetitions (default: one, ex used for push ups), time(hours and min and seconds), number of cups (to drink), calories, distance (km, meters, etc), weight (kg, g, etc.), capacity (liters, millilitres, etc.)
- Frequency and planning: user can select if the task needs to be done daily ( 1 time a day, multiple times a day) or specific days of the week. 
- User can selct if this task can send a push notification or not. If allowed to send a push notification then a push will be sent according to frequency. User can specify the time of the day to receive the push notification. If the task is completed before the scheduled push time then is not sent
- User can select the task color 
- User can select the task category. If the task is predefined then category is prefilled and can be changed. Otherwise user can pick from a category list. User can also create a new custom category from here
- Reward: at the end of the configuration, user can enable a reward. When enabled, two fields appear:
  - Number of streak days to earn the reward (minimum default is 2, configurable via stepper)
  - A free-text field where the user can describe the reward
User can click on save task button to save the configured task



- **FR-4: Task stats**
User can access to task stats from the task menu. Task stats section shows in order from the top to bottom:
task name and icon on the top centered
Time window selector centered
Number of task completions and Percentage of task completion aligned next to each other
Trend line chart that shows time on the x axes and task completions counts on the y axes. Trend line frequency is 7 days if time window is < 60 days, else frequency turns to monthly.
Number of task completions, percentage task completions and chart of filtered by defaults on last 30 days.
At the bottom of the view there's a button called manage task completions. This opens the manage task completion view (FR-5) that allow user to edit previous days task completions.

**FR-4.1: time window selector:
When time window selector is tapped then a full page date picker is open
This date picker is very similar to what flights websites use, like for example skycanner, in their search box
No selection is visible initially and current month is visible
User can scroll up to go back in time and scroll down to go forward in time
When user tap on a day the. That day is highlighted
When user tap on a second day then that day and all the days in between are highlighted
The tap on 2 days define the new time window
A third tap on a day, when a window is already selected, is a new start of a window selection






**FR-5: Manage tasks completions**
When user access manage tasks completions then a full screen calendar is shown. The calendar shows month on the top. Month can be changed with arrows to go back one month or forward one month. Underneath the day number of the months are shown in circles. Highlighted circles are the ones where the task was marked as completed. Non highlighted circles are the one where the task was marked as not completed. If user taps on a task completed day then it gets marked as not completed for that day. 


**FR-6: task menu**
In the task list when user click (single fast tap) on task round, then a small menu opens up showing the following list:
stats: access to Task stats
Edit: access to task configuration
Remove: remove the task
If user clicks outside from the menu then the task menu closes

**FR-7: App settings**
In task list, in the bottom left there is a small wheel icon to access app settings.
In app settings user can configure the following:
- Language selector
- Week start day
- Measurments units: international system of units, US customary system or imperial system (ex: km vs miles, etc.)
- Category section: Add, remove or edit task categories


**FR-8: General Stats Section**
In the task list, in the bottom left next to the settings icon, a stats icon appears. When user taps the icon a general stats section appears. The general stats section is similar to the task stats section (FR-4): it includes a time window selector, completion count, average completion percentage, and a trend line chart. The difference is that stats are aggregated across all tasks by default. On top of the view, a task category dropdown list is available (defaulting to "All"). User can filter by task category. When a specific category is selected, all stats refer only to tasks in that category.


**FR-9: App Icon**
The app has a custom icon inspired by the circular shape of the task completion ring. The icon features a gradient blue-to-indigo background with a white progress ring and checkmark, reflecting the habit tracking concept.

**FR-10: Reward Celebration**
When a user has configured a reward for a task (see FR-3), and the user completes the task such that their current streak equals the reward streak threshold, a full-screen celebratory overlay is shown. The celebration screen features:
- An animated confetti/coriandoli particle effect with colorful shapes falling across the screen
- A congratulatory message: "Congratulations! You can now reward yourself with: {reward text}"
- A dismiss button to close the celebration and return to the task list
The celebration respects the Reduce Motion accessibility setting by skipping the confetti animation. The reward triggers every time the streak reaches a multiple of the configured streak count, encouraging continued engagement.

### 5.2 Optional / Nice-to-Have
- 

---

## 6. Non-Functional Requirements
Constraints and quality attributes.

### 6.1 Performance
- 

### 6.2 Security & Privacy
- Authentication:
- Authorization:
- Data storage:
- Compliance (GDPR, etc.):

### 6.3 Reliability & Availability
- 

### 6.4 Scalability
- 

---

## 7. Platform & Technical Constraints
### 7.1 Platforms
- iOS only (iPhone)
- Minimum supported OS version: iOS 17.0

### 7.2 Technical Stack
- Frontend: SwiftUI (iOS 17+)
- Backend: None (local-only, no API services)
- Database: SwiftData (on-device persistence)
- Hosting / Cloud: None (Apple App Store distribution via Xcode / App Store Connect)
- Charts: Swift Charts (Apple framework)
- Notifications: UserNotifications (local scheduled notifications)
- Icons: SF Symbols
- Architecture: MVVM with @Observable
- Test framework: Swift Testing (unit/integration) + XCUITest (UI automation)

### 7.3 Integrations
- External APIs: None
- Payments: App Store In-App Purchase (if premium features are added later)
- Analytics: None (can add Apple App Analytics via App Store Connect at no cost)
- Notifications: UserNotifications framework (local scheduled notifications, no server-side push)
- Icons: SF Symbols (Apple system icon library, 5,000+ icons)
- Charts: Swift Charts (Apple framework for trend line visualizations)

---

## 8. Data Model (High Level)

For the full entity definitions, field descriptions, ER diagram, and disk budget analysis, see [data-model.md](data-model.md).

**Entities:**

- **Category** -- Grouping label for tasks. Four preset categories (Health, Fitness, Learning, Social) are seeded on first launch; users can create custom categories.
- **HabitTask** -- Core entity representing a trackable habit. Stores configuration (title, icon, measurement duration, goal, frequency, notification preferences, color, category, reward settings) and serves as the parent for completion records.
- **TaskCompletion** -- One record per completion event (tap-and-hold). Stores a timestamp and an optional measured value for goal-based tasks. All statistics and streaks are computed from these records.
- **AppSettings** -- Singleton storing global app state (e.g., onboarding completion flag).

**Reference data (not persisted):**

- **PresetTaskCatalog** -- Static array of 25 preset tasks defined in code (see FR-x). When selected, a new HabitTask is created with pre-filled values.

**Key relationships:**

- Category 1 : N HabitTask (nullify on category delete)
- HabitTask 1 : N TaskCompletion (cascade on task delete)



---

## 10. UX & UI Principles
Guidelines, not designs.

For the full UX & UI guidelines, see [ux-ui-principles.md](ux-ui-principles.md).

**Summary:**
- Minimal, focused UI inspired by Streak; delight through motion and haptics
- SF Pro typography with Dynamic Type; SF Symbols for icons
- Per-task accent colors; full dark mode support via semantic SwiftUI colors
- Accessibility: VoiceOver, Reduce Motion alternatives, 44pt touch targets, WCAG AA contrast
- Localization: 12 Latin/Cyrillic-script languages across 3 priority tiers (no RTL, no CJK); strings externalized via Xcode String Catalogs

---

## 11. Edge Cases & Risks
Things that could break, fail, or confuse users.

- 
- 

---

## 12. Assumptions & Open Questions
### 12.1 Assumptions
- 

### 12.2 Open Questions
- 

---

## 13. Milestones & Phases
### Phase 1 – MVP
- 

### Phase 2 – Iteration
- 

---

## 14. Acceptance Criteria
How we validate requirements are met.

See [acceptance-criteria.md](acceptance-criteria.md) for the full Given/When/Then acceptance criteria.

---

## 15. Appendix
Links, references, diagrams, research, etc.

