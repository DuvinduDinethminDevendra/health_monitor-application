# 🏃 Activity Tracking Feature — Production Implementation Plan
**ICT4153 | Health Monitor App | Member Responsibility: Activity Tracking (Steps + Workouts)**

---

> [!IMPORTANT]
> This plan is scoped **only to your responsibility** — Activity Tracking. It slots cleanly into the existing codebase without breaking any of your teammates' work.

---

## 1. Current State Analysis

After reviewing the full project, here is exactly what already exists and what is missing for your feature.

### ✅ What Already Exists (Don't Rebuild These)

| File | Status | Notes |
|------|--------|-------|
| `lib/models/activity.dart` | ✅ Exists | Generic model — covers both steps & workouts via `type` field |
| `lib/repositories/activity_repository.dart` | ✅ Exists | Full CRUD + date range queries — solid foundation |
| `lib/database/database_helper.dart` | ✅ Exists | `activities` table already created with correct schema |
| `lib/screens/activity_screen.dart` | ⚠️ Exists (basic) | Currently uses `setState` directly — needs ViewModel upgrade |
| `lib/screens/charts_screen.dart` | ⚠️ Exists (basic) | Has activity bar chart — needs weekly steps chart added |
| `lib/screens/dashboard_screen.dart` | ⚠️ Exists (basic) | Has stat cards — needs step progress ring added |
| `pubspec.yaml` | ⚠️ Missing packages | `pedometer`, `flutter_background_service` need to be added |

### ❌ What You Need to Build (Your Deliverables)

| Deliverable | Type | Priority |
|-------------|------|----------|
| `StepRecord` model | New model | 🔴 High |
| `WorkoutRecord` model | New model | 🔴 High |
| `step_record_repository.dart` | New repository | 🔴 High |
| `workout_record_repository.dart` | New repository | 🔴 High |
| `activity_provider.dart` (ViewModel) | State management | 🔴 High |
| **Catch-Up Mechanism** (`_runCatchUpCheck`) | **Edge-case handler** | 🔴 High |
| `pedometer_service.dart` | Device feature | 🔴 High |
| Background midnight reset task | Background service | 🔴 High |
| Rebuilt `activity_screen.dart` | UI (Your screen) | 🔴 High |
| Step progress ring on Dashboard | UI widget | 🟡 Medium |
| Weekly steps bar chart widget | UI (fl_chart) | 🟡 Medium |
| SQLite schema migration (new tables) | DB | 🔴 High |

---

## 2. Architecture Diagram (Your Feature Layer)

```
┌──────────────────────────────────────────────────────┐
│                  PRESENTATION LAYER                  │
│  activity_screen.dart   │   dashboard_screen.dart    │
│  (Workout log form)     │   (Step ring widget)       │
└─────────────┬───────────┴──────────┬─────────────────┘
              │ Consumer<>           │ Consumer<>
              ▼                      ▼
┌──────────────────────────────────────────────────────┐
│              BUSINESS LOGIC LAYER (Provider)         │
│              lib/providers/activity_provider.dart    │
│  - liveStepCount (int)                               │
│  - dailyStepGoal (int, default 10000)                │
│  - todaysWorkouts (List<WorkoutRecord>)               │
│  - weeklySteps (List<StepRecord>)                    │
│  - addWorkout(), loadData(), resetSteps()            │
└────┬──────────────────────────┬───────────────────────┘
     │                          │
     ▼                          ▼
┌─────────────────┐   ┌──────────────────────────────┐
│ SERVICES LAYER  │   │        DATA LAYER            │
│                 │   │                              │
│ pedometer_      │   │  step_record_repository.dart │
│ service.dart    │   │  workout_record_repository   │
│ (live steps     │   │  .dart                       │
│  stream)        │   │                              │
│                 │   │  StepRecord model            │
│ background_     │   │  WorkoutRecord model         │
│ step_service    │   │                              │
│ .dart           │   │  DatabaseHelper (new tables) │
│ (midnight save) │   │                              │
└─────────────────┘   └──────────────────────────────┘
```

---

## 3. Packages to Add

### `pubspec.yaml` Changes

```yaml
dependencies:
  flutter:
    sdk: flutter
  sqflite: any
  path: any
  fl_chart: any
  http: any
  flutter_local_notifications: any
  provider: any
  intl: any
  crypto: any
  # ── YOUR NEW ADDITIONS ──────────────────────────────
  pedometer: ^4.0.2                   # Live step count from hardware sensor
  flutter_background_service: ^5.0.9  # Background task for midnight reset
  shared_preferences: ^2.3.2          # Store live step baseline across app restarts
```

> [!WARNING]
> **Android Emulator Limitation (Development Only):** The pedometer sensor is hardware-based. On the Android emulator, `pedometerStatus` will be `stopped` and step stream will not fire. Use the **"Manual Steps" fallback UI** (included in this plan) to demo step counting during development on the emulator.
>
> **For the final submission:** Build a release APK (`flutter build apk --release`) and install it on a real Android phone. The pedometer, background reset, and live step counter will all work fully on physical hardware. The Manual Steps button can remain as a debug utility or be hidden behind a `kDebugMode` flag.

---

## 4. Android Native Setup

### `android/app/src/main/AndroidManifest.xml` — Add These Permissions

```xml
<!-- Activity Recognition (required for pedometer on Android 10+) -->
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION"/>

<!-- Background service (for midnight reset) -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

### `android/app/build.gradle.kts` — minSdk Change

Change `minSdk = flutter.minSdkVersion` to `minSdk = 21` (pedometer requires API 21+):

```kotlin
defaultConfig {
    applicationId = "com.example.health_monitor"
    minSdk = 21  // Changed from flutter.minSdkVersion
    targetSdk = flutter.targetSdkVersion
    versionCode = flutter.versionCode
    versionName = flutter.versionName
}
```

---

## 5. New SQLite Tables (Schema Migration)

The current `database_helper.dart` has `version: 1`. You will add a **version 2 migration** that creates two new tables.

**New Table: `step_records`**
```sql
CREATE TABLE step_records (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id     INTEGER NOT NULL,
    date        TEXT NOT NULL UNIQUE,   -- 'yyyy-MM-dd', one record per day per user
    step_count  INTEGER NOT NULL DEFAULT 0,
    goal        INTEGER NOT NULL DEFAULT 10000,
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);
```

**New Table: `workout_records`**
```sql
CREATE TABLE workout_records (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id         INTEGER NOT NULL,
    workout_type    TEXT NOT NULL,     -- 'Running', 'Cycling', 'Yoga', etc.
    duration_mins   INTEGER NOT NULL,  -- Validated: 1–300 mins
    calories_burned INTEGER,           -- Optional estimated calories
    logged_at       TEXT NOT NULL,     -- ISO datetime string
    notes           TEXT,              -- Optional user note
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);
```

> [!NOTE]
> These are **separate tables** from the existing `activities` table. Your new models (`StepRecord`, `WorkoutRecord`) are purpose-built, relational, and properly typed. This shows the examiner a richer schema vs. the generic `activities` table.

---

## 6. New Files to Create

### File Structure (Your Additions)

```
lib/
├── models/
│   ├── activity.dart          (EXISTING — don't touch)
│   ├── step_record.dart       ← NEW (you create this)
│   └── workout_record.dart    ← NEW (you create this)
│
├── repositories/
│   ├── activity_repository.dart      (EXISTING — don't touch)
│   ├── step_record_repository.dart   ← NEW
│   └── workout_record_repository.dart ← NEW
│
├── providers/                 ← NEW DIRECTORY (create this)
│   └── activity_provider.dart ← NEW (your ViewModel)
│
├── services/
│   ├── auth_service.dart              (EXISTING)
│   ├── notification_service.dart      (EXISTING)
│   ├── health_tips_service.dart       (EXISTING)
│   ├── pedometer_service.dart         ← NEW
│   └── background_step_service.dart   ← NEW
│
├── widgets/                   ← NEW DIRECTORY
│   ├── step_progress_ring.dart     ← NEW (dashboard widget)
│   └── weekly_steps_chart.dart     ← NEW (fl_chart widget)
│
├── screens/
│   ├── activity_screen.dart   ← REBUILD (yours to overhaul)
│   └── dashboard_screen.dart  ← MINOR EDIT (add step ring)
│
└── database/
    └── database_helper.dart   ← EDIT (add v2 migration)
```

---

## 7. Model Specifications

### `lib/models/step_record.dart`
```dart
class StepRecord {
  final int? id;
  final int userId;
  final String date;       // 'yyyy-MM-dd'
  final int stepCount;
  final int goal;          // default 10000

  // toMap(), fromMap(), copyWith() methods required
}
```

### `lib/models/workout_record.dart`
```dart
class WorkoutRecord {
  final int? id;
  final int userId;
  final String workoutType;    // 'Running', 'Cycling', 'Swimming', 'Yoga', 'Gym', 'Walking', 'Other'
  final int durationMins;      // 1–300 validated
  final int? caloriesBurned;   // optional
  final String loggedAt;       // ISO datetime
  final String? notes;         // optional

  // toMap(), fromMap(), copyWith() methods required
}
```

---

## 8. Repository Specifications

### `step_record_repository.dart` — Key Methods

| Method | Purpose |
|--------|---------|
| `upsertTodaySteps(StepRecord)` | Insert or update today's step count (UNIQUE date constraint) |
| `getStepRecordByDate(userId, date)` | Get a single day's record |
| `getLast7DaysSteps(userId)` | Returns `List<StepRecord>` for weekly chart |
| `getLast30DaysSteps(userId)` | For monthly chart |
| `deleteStepRecord(id)` | Admin use |

### `workout_record_repository.dart` — Key Methods

| Method | Purpose |
|--------|---------|
| `insertWorkout(WorkoutRecord)` | Save a new workout |
| `getWorkoutsByUser(userId)` | All workouts for list view |
| `getTodaysWorkouts(userId, date)` | Today's workout list |
| `getWorkoutsByDateRange(userId, start, end)` | For charts |
| `deleteWorkout(id)` | Swipe-to-delete |
| `updateWorkout(WorkoutRecord)` | Edit existing entry |

---

## 9. ActivityProvider (State Management)

### `lib/providers/activity_provider.dart`

This is the **brain** of your feature. All UI reads from this, all business logic lives here.

```dart
class ActivityProvider extends ChangeNotifier {
  // ── State ─────────────────────────────────────────
  int liveStepCount = 0;           // From pedometer stream
  int dailyStepGoal = 10000;       // User-configurable
  StepRecord? todayStepRecord;
  List<StepRecord> weeklySteps = [];
  List<WorkoutRecord> todaysWorkouts = [];
  List<WorkoutRecord> allWorkouts = [];
  bool isLoading = false;
  String? errorMessage;

  // ── Repositories ──────────────────────────────────
  final StepRecordRepository _stepRepo = StepRecordRepository();
  final WorkoutRecordRepository _workoutRepo = WorkoutRecordRepository();

  // ── Key Methods ───────────────────────────────────
  Future<void> loadData(int userId) async { ... }
  void updateLiveSteps(int steps) { ... }  // Called by PedometerService
  Future<void> addWorkout(WorkoutRecord workout) async { ... }
  Future<void> deleteWorkout(int id) async { ... }
  Future<void> saveTodaySteps(int userId, int steps) async { ... }
  Future<void> setGoal(int newGoal) async { ... }

  // ── Computed Properties ────────────────────────────
  double get stepProgress => liveStepCount / dailyStepGoal; // 0.0 to 1.0+
  int get remainingSteps => (dailyStepGoal - liveStepCount).clamp(0, dailyStepGoal);
  int get totalWorkoutMinutesToday => todaysWorkouts.fold(0, (s, w) => s + w.durationMins);
}
```

---

## 9.5. Catch-Up Mechanism (Power-Off Edge Case)

**Problem:** If the Android device is powered off at midnight, the background service never runs and yesterday's step data is permanently lost.

**Solution:** A two-part safety net built into `ActivityProvider`.

### How It Works

```
App running → pedometer fires
        ↓
  updateLiveSteps() called
        ↓
  SharedPreferences updated:
    ├── activity_step_cache_date  = 'yyyy-MM-dd'
    └── activity_step_cache_count = 7432

  ──── device powers off at midnight ────
  ──── background service NEVER runs ────

  ──── next day, user opens app ─────────
        ↓
  loadData() calls _runCatchUpCheck()
        ↓
  Read SharedPreferences:
    ├── cachedDate  = '2026-04-26'  (yesterday)
    └── cachedSteps = 7432
        ↓
  Compare: cachedDate ≠ today ('2026-04-27')
        ↓
  ⚠️ MISSED SAVE DETECTED
        ↓
  StepRecordRepository.upsertStepRecord(
    date: '2026-04-26',   ← yesterday's date
    steps: 7432
  )
        ↓
  Reset cache → date = today, count = 0
  liveStepCount = 0  (fresh start)
```

### Key Design Decisions

| Decision | Reason |
|----------|--------|
| `upsertStepRecord` (INSERT OR REPLACE) | If background DID run but also catch-up runs, no duplicate is created |
| Catch-up runs BEFORE reading today's record | Ensures `loadData()` always sees the latest correct state |
| `notifyListeners()` NOT called inside `_runCatchUpCheck` | The parent `loadData()` calls it at the end — avoids double rebuild |
| Cache updated on EVERY pedometer event | Minimises data loss window to the last sensor tick (~1 second) |

---

## 10. PedometerService Specification

### `lib/services/pedometer_service.dart`

```dart
// Purpose: Subscribe to the hardware step sensor stream
// and push live counts to ActivityProvider

class PedometerService {
  StreamSubscription<StepCount>? _stepSub;
  StreamSubscription<PedestrianStatus>? _statusSub;

  void startListening(ActivityProvider provider) {
    _stepSub = Pedometer.stepCountStream.listen(
      (event) => provider.updateLiveSteps(event.steps),
      onError: (e) => provider.setError('Pedometer unavailable'),
    );
    _statusSub = Pedometer.pedestrianStatusStream.listen(
      (event) { /* walking / stopped status */ },
    );
  }

  void stop() {
    _stepSub?.cancel();
    _statusSub?.cancel();
  }
}
```

---

## 11. Background Service (Midnight Reset)

### `lib/services/background_step_service.dart`

**Strategy:** Use `flutter_background_service` with a periodic check.

```dart
// Initialization (called once at app start):
Future<void> initBackgroundService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onServiceStart,
      autoStart: true,
      isForegroundMode: false,
    ),
    iosConfiguration: IosConfiguration(autoStart: false),
  );
}

// The background isolate function:
@pragma('vm:entry-point')
void onServiceStart(ServiceInstance service) {
  // Every 15 minutes, check if midnight has passed
  // If yes: save today's step count to SQLite, then reset counter
  Timer.periodic(Duration(minutes: 15), (_) async {
    final now = DateTime.now();
    if (now.hour == 0 && now.minute < 15) {
      // Save yesterday's count, reset SharedPreferences baseline
      service.invoke('reset_steps');
    }
  });
}
```

> [!TIP]
> For the assignment/viva demo, you can also add a **"Simulate Midnight Reset"** button in a debug panel of the Activity Screen. This lets you demonstrate the feature without waiting for actual midnight.

---

## 12. UI Plan — Activity Screen (Full Rebuild)

The current `activity_screen.dart` is a plain list. Your rebuilt version will be a **rich, tabbed activity hub**.

### Screen Structure

```
ActivityScreen
├── AppBar: "Activity Tracker" + Settings icon (goal setter)
└── TabBar (2 tabs)
    ├── Tab 1: "Steps" ─────────────────────────────────
    │   ├── StepProgressRing (big circular indicator)
    │   │   └── Center: "7,432 / 10,000 steps"
    │   ├── Stats Row: [Remaining] [Calories est.] [Km est.]
    │   ├── Pedometer Status Badge ("Walking" / "Stopped")
    │   ├── [+ Manual Steps] button (for emulator testing)
    │   └── WeeklyStepsChart (BarChart from fl_chart)
    │
    └── Tab 2: "Workouts" ──────────────────────────────
        ├── Today's Summary Banner
        │   └── "X workouts • Y total minutes today"
        ├── [+ Log Workout] FAB / Button
        │   └── Opens BottomSheet form:
        │       ├── Dropdown: Workout Type (7 options)
        │       ├── Slider: Duration (1–120 mins)
        │       ├── TextField: Notes (optional)
        │       └── [Save] with validation
        └── ListView: all workouts (swipe-to-delete)
            └── WorkoutCard:
                ├── Icon (type-specific)
                ├── Title: "Running • 35 min"
                ├── Subtitle: "~280 kcal • Apr 26"
                └── Delete button
```

### Color Palette for Your Feature

```dart
// Steps — use blue gradient
const stepColor = Color(0xFF1A73E8);
const stepGradient = [Color(0xFF1A73E8), Color(0xFF42A5F5)];

// Workouts — use energetic orange/red
const workoutColor = Color(0xFFE53935);

// Goal achieved — use green
const goalColor = Color(0xFF00BFA5);
```

---

## 13. UI Plan — Dashboard Integration

Add two new widgets to the existing `dashboard_screen.dart` home tab:

### 1. Step Progress Ring Card

```
┌─────────────────────────────────────────┐
│  TODAY'S STEPS                          │
│                                         │
│    ╭──────────────╮                     │
│    │   7,432      │  ████░░░░  74%      │
│    │  of 10,000   │                     │
│    ╰──────────────╯                     │
│                                         │
│  2,568 steps remaining to your goal     │
└─────────────────────────────────────────┘
```

### 2. Weekly Steps Mini-Chart (BarChart)

```
┌─────────────────────────────────────────┐
│  THIS WEEK'S ACTIVITY                   │
│  ▂▄▇▅▃▆█  (7-day bar chart)            │
│  Mon Tue Wed Thu Fri Sat Sun            │
└─────────────────────────────────────────┘
```

---

## 14. Workout Log Form — Validation Rules

| Field | Rule | Error Message |
|-------|------|---------------|
| Workout Type | Required, from predefined list | "Please select a workout type" |
| Duration | Required, 1–300 minutes | "Duration must be between 1 and 300 minutes" |
| Notes | Optional, max 200 chars | "Notes cannot exceed 200 characters" |

**Predefined Workout Types:**
`Running` | `Cycling` | `Swimming` | `Yoga` | `Gym / Weights` | `Walking` | `Other`

**Estimated Calorie Formula (for UI display):**
- Running: `duration × 10`
- Cycling: `duration × 8`
- Swimming: `duration × 9`
- Yoga: `duration × 4`
- Gym: `duration × 7`
- Walking: `duration × 5`

---

## 15. Weekly Steps Chart (fl_chart)

### `lib/widgets/weekly_steps_chart.dart`

```dart
// Uses BarChart from fl_chart
// Data: getLast7DaysSteps(userId) → List<StepRecord>
// X-axis: Day abbreviation (Mon, Tue, ...)
// Y-axis: Step count
// Color: gradient bar — blue to teal
// Goal line: HorizontalLine at y = dailyStepGoal (dashed)
// Touch tooltip: shows exact step count + date
```

---

## 16. Circular Step Progress Ring

### `lib/widgets/step_progress_ring.dart`

```dart
// Uses CustomPainter OR fl_chart's PieChart in ring mode
// Recommended: CustomPainter for full control
// 
// Parameters:
//   - progress: double (0.0 to 1.0)
//   - stepCount: int
//   - goal: int
//   - size: double (default 180)
//
// Animations: AnimationController with CurvedAnimation
// Color: blue arc on grey track; turns green when >= 1.0 (goal achieved)
// Center text: Large step count + small "steps" label
```

---

## 17. Phase-by-Phase Build Order

Follow this order to have a testable build at each phase:

### Phase 1 — Foundation (1–2 hours)
1. Add packages to `pubspec.yaml` → `flutter pub get`
2. Add Android permissions to `AndroidManifest.xml`
3. Change `minSdk = 21` in `build.gradle.kts`
4. Create `step_record.dart` and `workout_record.dart` models
5. Update `database_helper.dart` with v2 migration + new tables
6. Create `step_record_repository.dart` and `workout_record_repository.dart`

**Checkpoint:** Run `flutter analyze`. Zero errors.

### Phase 2 — State Management (1 hour)
7. Create `lib/providers/` directory
8. Build `activity_provider.dart` with mock data (no pedometer yet)
9. Register `ActivityProvider` in `main.dart` `MultiProvider`
10. Replace `setState` calls in `activity_screen.dart` with `Provider.of<ActivityProvider>`

**Checkpoint:** App runs, Activities tab shows provider-driven data.

### Phase 3 — Device Feature (1–2 hours)
11. Build `pedometer_service.dart`
12. Start pedometer in `activity_screen.dart` `initState`
13. Handle permission request for ACTIVITY_RECOGNITION
14. Add "Manual Steps" input for emulator fallback
15. Build `background_step_service.dart`
16. Initialize background service in `main()` before `runApp`

**Checkpoint:** On physical device, live steps update in real time.

### Phase 4 — UI Polish (2–3 hours)
17. Build `step_progress_ring.dart` with `CustomPainter`
18. Build `weekly_steps_chart.dart` with `fl_chart`
19. Fully rebuild `activity_screen.dart` (tabbed UI)
20. Add step ring + weekly chart to `dashboard_screen.dart`
21. Build the Workout Log `BottomSheet` with full validation

**Checkpoint:** Full feature complete. All charts render with data.

### Phase 5 — Integration & Testing (1 hour)
22. Test all validation cases (empty form, out-of-range duration)
23. Test SQLite CRUD for both tables (add, delete, view)
24. Test chart rendering with 7 days of seeded data
25. Verify pedometer service starts/stops correctly with app lifecycle
26. Add `Simulate Midnight Reset` debug button

**Checkpoint:** Your feature is complete. Hand off to the team for final merge.

> [!NOTE]
> **APK build is a team activity.** After all 4 members finish their parts and merge the code, the team runs `flutter build apk --release` together and installs on a real phone to verify everything works end-to-end. That is not your individual responsibility.

---

## 18. Viva Defense Points (What to Know Cold)

| Question | Answer |
|----------|--------|
| Why two separate models instead of using Activity? | `StepRecord` enforces one-per-day via UNIQUE constraint and stores a `goal`. `WorkoutRecord` has domain-specific fields (calories formula, notes). Generic `Activity` is too loosely typed. |
| Why `flutter_background_service` over `workmanager`? | `flutter_background_service` integrates natively with the foreground service model on Android, making it more reliable for continuous tasks. `workmanager` is better for one-shot deferred tasks. |
| How does the pedometer handle app restart? | `SharedPreferences` stores the "baseline" step count at last app open. The live count is `currentHardwareSteps - baseline`. On restart, a new baseline is set. |
| How is the Repository pattern implemented? | UI → Provider → Repository → DatabaseHelper → SQLite. No direct DB calls from screens. |
| What is the emulator fallback? | A "Manual Steps" text field that calls `provider.updateLiveSteps()` directly, bypassing the sensor stream. |

---

## 19. Key Integration Points with Teammates

| Teammate | Integration Point | What You Need From Them |
|----------|-------------------|------------------------|
| Member 1 (UI/Nav) | `dashboard_screen.dart` | Permission to add step ring widget inside `_buildDashboardHome()` |
| Member 2 (State) | `main.dart` MultiProvider | Add `ActivityProvider` to the provider list |
| Member 3 (DB) | `database_helper.dart` | Version 2 migration for your 2 new tables |
| Member 4 (API/Device) | Android manifest | Merge permissions (ACTIVITY_RECOGNITION + FOREGROUND_SERVICE) |

