# Chart Integration Guide (For UI/Activity Members)

This document explains the architecture of the **Goal Progress Charts** and how other team members can pull from the SQLite database to build accurate `fl_chart` representations for different metrics.

## 1. The Core Philosophy: "Goal Completion Percentage"

In the `charts_screen.dart`, you will see the **"Goal Completion (%)" Bar Chart**.
This chart is designed to be the **Universal Balanced Solution** for ALL goals.

### Why is this the Universal Solution?
Because users can create *any* custom goal (e.g., "Read 5 books", "Sleep 8 hours", "Walk 10,000 steps"). Plotting "5 books" and "10,000 steps" on the same Y-Axis would completely break the graph (the book bar would be microscopic compared to the steps bar).

To solve this, the Data Layer normalizes ALL goals into a **Percentage (0 to 100%)**:
```dart
double percent = (goal.currentValue / goal.targetValue) * 100;
```
This guarantees that **every** goal, whether static (sleep, steps) or fully custom, displays perfectly and evenly on the exact same Bar Chart. 

---

## 2. Metric-Specific Charts: Cumulative vs. Daily Reset

While the Percentage Bar Chart is great for an "Overview", specific metrics require specific chart types. If you are building the **Activities** tab, you must differentiate between two types of metrics:

### A. Cumulative Metrics (e.g., Steps, Weight Loss, Running Distance)
- **Nature:** These build up over time. You start at 0, and you accumulate value until you hit your target.
- **Best Chart:** **Bar Chart** or **Line Chart (Upward Trend)**.
- **Implementation:** You can plot the actual `currentValue` directly on the Y-Axis. 

### B. Daily Reset Metrics (e.g., Sleep, Water Intake)
- **Nature:** These reset to 0 every single day. If your goal is 8 hours of sleep, you don't accumulate 56 hours a week—you just try to hit 8 hours each night.
- **Best Chart:** **Line Chart** (where the X-Axis is the Date/Days of the week, and the Y-Axis is the hours slept).

### C. Auto-Merge: Linking Goals with Real Activities
**CRITICAL ARCHITECTURE UPDATE:** The `charts_screen.dart` has now been explicitly programmed to automatically scan the `_activities` table (last 30 days) and merge it with the `goals` table. 
- If a user sets a Custom Goal named "Meditation", the chart will mathematically hunt for any activity typed "meditation" and seamlessly plot the real 30-day Line Chart!
- **Note for Team Members:** To improve this auto-tracking in the future, you should connect the Activity Data Layer to native **Auto-Tracking Hardware Sensors** (like Android's Health Connect API, pedometers, or smartwatch APIs). This will allow the `activities` table to populate automatically in the background, making the Goal Line Charts perfectly accurate without the user ever manually typing anything in!

---

## 3. The Predictive Insights Engine

The Data Science prediction engine (inside `GoalRepository.estimateCompletionDate`) uses a **Fully Adaptive 1-Day Linear Regression Algorithm**.

### How it Works:
1. It looks at the goal's `currentValue`.
2. It assumes that value was generated based on instantaneous daily velocity (`Velocity = currentValue / 1.0 day`).
3. It divides the `remainingValue` by this `velocity` to predict exactly how many days are left to hit the target.
4. It compares that predicted date to the `deadline` you set, and returns a dynamic English string (e.g., "You are moving fast!").

Because it uses a 1-day instantaneous velocity window, it adapts perfectly to brand-new custom goals the moment you add progress to them!
