# Dynamic Data Localization Report

When localizing an application, hardcoded UI strings are easily replaced by static translations. However, user-entered data and dynamic phrases originating from the database or backend logic present unique challenges.

Here is an analysis of the dynamic data in the Health Monitor application and how it intersects with localization:

## 1. User-Entered Content (Should NOT be translated)
Data explicitly entered by the user should generally remain exactly as they typed it, regardless of the app's locale.

- **Reminder Titles & Messages:** Users type these when creating a reminder. If a user writes "Take Vitamin C", it should stay "Take Vitamin C" even if the app switches to Sinhala.
- **Custom Health Log Tags:** If a user adds a custom tag (e.g., "Drank Alcohol"), it remains in the language they used to create it.
- **User Names:** Profile names should be rendered as provided.

**Strategy:** Render these strings directly. No localization changes required.

## 2. Pre-defined Database Enums & Categories (Must be mapped)
Data stored in the database as specific English string constants (enums) need to be localized when presented to the user.

- **Activity Types:** Stored as `'walking'`, `'running'`, `'yoga'`, etc.
  - **Strategy:** When displaying an activity type, use a switch statement or a mapping function to fetch the localized string: `AppLocalizations.of(context)!.activityTypes[activity.type] ?? activity.type`.
- **Goal Categories:** Stored as `'Steps (Daily)'`, `'Water (Daily)'`, etc.
  - **Strategy:** Map these constant strings to localized equivalents before displaying them in charts or lists.
- **Default Health Log Tags:** `'🏋️ Post-Workout'`, `'🛋️ Rest Day'`, etc.
  - **Strategy:** Identify if the tag is one of the default system tags. If so, translate it; if not, treat it as a custom user tag and display it raw.

## 3. Dynamic Generated Text (Complex)
Text constructed programmatically or returned by 'AI' components.

- **Predictive Insights:** (`GoalRepository.getPredictiveInsight()`) 
  - Currently, this method returns dynamically constructed English sentences based on the user's progress (e.g., *"You are 20% away from your goal!"*).
  - **Strategy:** To fully localize this, the repository method itself needs to be aware of the current locale, or it needs to return an enum/data object that the UI translates. For Phase 2, we can either pass the `BuildContext` into the repository (not ideal for architecture) or refactor the repository to return an Insight Code that the UI translates. Given the scope, we will provide translations for the static parts of these insights where possible, or document them for a backend/architecture update.

## Conclusion for Phase 2
During Phase 2 execution, we will:
1. Ensure user-generated data (Reminder text, Names) is left untouched.
2. Add localization maps in `AppLocalizations` for predefined database strings (Activity Types, Goal Categories).
3. Update the UI to translate these predefined strings on the fly while leaving custom strings untouched.
