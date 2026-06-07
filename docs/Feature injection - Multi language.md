---
tags:
  - ringhabit
---

# Introduction of multi language
Enable user to consume the app in multiple languages

## Problem
Currently Ring Habits is in English only. However been the target market eu, this is preventing the app to be adopted. When advertising on app store on key english keywords impressions are extremely low
## Target User
- Ring habit target user located in multiple eu countries
## Proposed Solution
- introduce multi language for main eu languages
## Success Metric
- **Primary:** increase installs
- 0 bugs introduced with this feature injection
- App adoption increases drastically (supporting signal)
## Scope (In / Out)
In:
- Expand language to the list below

| Language   | Locale |
| ---------- | ------ |
| Spanish    | es-ES  |
| Portuguese | pt-PT  |
| French     | fr-FR  |
| German     | de-DE  |
| German     | de-AT  |
| Italian    | it-IT  |
| Dutch      | nl-NL  |
| Dutch      | nl-BE  |
- on app install the user has language configured based on their device configuration (ex: if user device configuration is Dutch then when user install app the language of the app is set to Dutch)
- If the device locale is not one of the supported locales above, the app defaults to **English**
- User can change language from the settings section; the setting label is **Language**
- Use `Foundation` formatters for numbers, dates, distances, and durations. These automatically respect the user's locale.
- Preset task names and category names must also be localized.

Out:
- Localized Terms of Service / Privacy Policy (legal pages remain as currently shipped; not translated for this release)
## Key Risks
- In some languages text might be too long and compromize ui. If this happens try to find abbreviations to solve it
## Rollout Plan
- Full roll out in new app release