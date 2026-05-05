# Uplift — Viva Preparation Guide
## Member 3: LSR Vidanaarachchi (TG/2020/1010)
**Role: Database & Data Layer | ICT4153 — Group 13 Descenders**

> **Viva Format:** 10 min (whole group) + 5 min (your individual segment)

---

## Part 1 — Full Architecture Flow Narrative

> *How to tell the complete story of what the app does technically — for the group 10-min slot.*

### The One-Line Pitch
> *"Uplift is an offline-first health monitor. Every piece of data is saved to a local SQLite database instantly, and a background sync engine mirrors it to Firebase Firestore so users never lose data across devices."*

---

### Architecture Flow: How Data Moves Through the App

```
[User Action]
     │
     ▼
[Flutter UI Screen]          ← lib/screens/ — pure display, zero business logic
     │  context.read<Provider>()
     ▼
[Provider / AuthService]     ← lib/providers/ & lib/services/auth_service.dart
     │  calls Repository method
     ▼
[Repository Layer]           ← lib/repositories/ — YOUR primary territory
     │  goal.toMap() → db.insert()
     ▼
[DatabaseHelper — SQLite]    ← lib/database/database_helper.dart (Schema v11)
     │  sync_status = 0 set on insert
     │
     ├─── Immediate: returns to UI (user sees data NOW)
     │
     └─── Async Background: SyncService.syncData() triggered
                │  queries sync_status = 0 records
                ▼
          [Firestore]        ← users/{uid}/goals, /activities, /health_logs
                │  .set(goal.toMap())
                ▼
          SQLite sync_status → 1  (record marked synced)
```

This is the **Write Path**. On next login on any device, `AuthService` calls `SyncService.rehydrateData()` — that pulls everything back from Firestore into SQLite (the **Read Path / Rehydration**).

---

### What Each Key File Does (Code-Level)

#### `lib/database/database_helper.dart`
- **What it is:** A Dart singleton — only one instance ever exists in the app's lifecycle.
- **What it does:** Creates and owns the physical SQLite file `health_monitor.db`. Runs `_onCreate()` to define all 9 tables. Runs `_onUpgrade()` as a sequential migration chain from v1 → v11 — each version adds new columns without breaking old data.
- **Key design:** Uses `ConflictAlgorithm.replace` on upserts, making every write operation **idempotent** — safe to run multiple times with the same result.
- **How to describe it:** *"This is the schema engine. It defines the physical structure of all 9 tables and handles version migrations. Any time we added a new column — like `category` on `goals` or `waist` on `health_logs` — we incremented the version and added the `ALTER TABLE` command here."*

#### `lib/models/*.dart` — The Translation Layer
- **What they are:** Dart classes representing real-world entities: `User`, `Goal`, `Activity`, `HealthLog`, `StepRecord`, `WorkoutRecord`, `Reminder`.
- **The crucial method — `.toMap()`:** Every model has a `toMap()` that returns `Map<String, dynamic>`. This single map is passed to BOTH `db.insert()` (SQLite) AND Firestore's `.set()`. **One method, two databases.**
- **`fromMap()` / `fromFirestore()`:** Used by Repositories and SyncService when reading data back.
- **`Goal.baseType` getter:** A computed property that classifies a goal as either `daily` or `cumulative`. This drives the entire charting and prediction logic.
- **How to describe it:** *"The model's `.toMap()` is the universal translator. SQLite needs a strict column map, and Firestore accepts any `Map<String, dynamic>`. By designing them to share the same map, adding a new field to the model automatically extends both databases — zero extra Firebase code."*

#### `lib/repositories/goal_repository.dart` — Your Most Complex File
- **What it does:** Full CRUD interface for the `goals` table. Contains your most advanced implementations.
- **Key methods:**
  - `insertGoal(Goal)` → writes to SQLite with `sync_status=0`, then calls `_syncService.syncGoal()` async
  - `getGoalsByUser(userId)` → queries SQLite and returns typed `List<Goal>`
  - `markCompleted(goalId)` → sets `is_completed=1` AND triggers a push notification via `NotificationService`
  - `getPredictiveInsight(goalId)` → **your linear regression engine** (see below)
  - `getUnsyncedGoals(userId)` → used by SyncService to find `sync_status=0` records
  - `updateSyncStatus(id, status)` → called after Firestore write confirms success
- **Auto-Merge behaviour:** When user manually updates goal progress via `updateGoalProgress()`, the repo calculates `delta = newValue - oldValue` and **invisibly inserts a timestamped `Activity` record** — anchoring that progress to the exact date permanently.

#### `lib/services/sync_service.dart` — The Bridge
- **What it is:** A singleton service. Not a Provider. No UI. Pure data plumbing.
- **`syncData(userId)`** — outbound sync:
  1. Queries each repo for `sync_status = 0` records
  2. Calls `.set(record.toMap())` on Firestore subcollection
  3. Calls `updateSyncStatus(id, 1)` on success
  4. If Firestore throws, the `try/catch` swallows it — record stays at `sync_status=0`, picked up on next cycle
- **`rehydrateData(userId)`** — inbound sync (login event):
  1. Calls `.get()` on Firestore subcollections for goals, activities, health_logs
  2. For each document: calls the repo's `upsert` method with `ConflictAlgorithm.replace`
  3. A brand-new device gets the user's complete history in seconds
- **`syncUserProfile(user)`** — profile-only push using `.set({...}, SetOptions(merge: true))`
- **How to describe it:** *"SyncService is completely decoupled from the UI. It has no ChangeNotifier, no setState. It's just a data pipeline. When a repository saves to SQLite, it fires the sync as an async call — the UI doesn't wait, so there's no jank."*

#### `lib/services/auth_service.dart` — The Orchestrator
- **What it does:** Wraps `FirebaseAuth` as a `ChangeNotifier`. This is the root-level state manager.
- **Authentication flow:** Listens to `_auth.authStateChanges()`. On sign-in → calls `_syncLocalUser()` (checks SQLite first, then Firestore) → calls `SyncService.rehydrateData()` → calls `SyncService.syncData()` → notifies listeners → UI renders `MainScaffold`.
- **Theme persistence:** `toggleTheme()` creates a new `User` via `copyWith(isDarkMode: !current)` → calls `updateUserProfile()` → writes to SQLite AND Firestore. On next boot, `_loadTheme()` reads from SQLite before first frame — zero theme flash.
- **Your contribution here:** The `_syncLocalUser()` logic, `updateUserProfile()` CRUD flow, and the startup data rehydration chain.

---

## Part 2 — Your Individual 5-Min Segment

> *What YOU built, how to describe it, in what order.*

### Opening Statement (30 sec)
> *"My responsibility was the entire Data Layer — the SQLite schema, the repository pattern, the bidirectional sync engine, and the predictive analytics. Essentially, everything between the UI and the database."*

---

### Point 1: SQLite Schema Design — `database_helper.dart`

**What you say:**
> *"I designed a 9-table relational schema at version 11. The core design decision was using Firebase's UID as the primary key of the `users` table — a TEXT primary key — so that the local SQLite identity and the cloud identity are always the same string. Every user-owned table (`goals`, `activities`, `health_logs`, `step_records`, `workout_records`) has a `user_id` foreign key with `ON DELETE CASCADE`, so when a user logs out and their local record is cleared, all related data cleans up automatically."*

**Key schema decisions to mention:**
| Decision | Why |
|---|---|
| `users.id = Firebase UID (TEXT PK)` | Unifies local and cloud identity — no ID translation needed |
| `sync_status INTEGER DEFAULT 0` | The flag that drives the entire sync engine |
| `profile_picture TEXT (Base64)` | Zero file-system permission needed — stored as text |
| `interests TEXT (JSON array)` | Flexible tagging for Health Tips personalisation |
| `reminders` — no `user_id` FK | Device-local only, intentionally not cloud-synced |

---

### Point 2: Repository Pattern — The Gatekeepers

**What you say:**
> *"I implemented the Repository Pattern to create a clean abstraction between the UI and the database. No screen ever writes SQL directly. Every screen calls a typed Dart method — like `goalRepo.insertGoal(goal)` — and the repository handles the SQL, the error catching, and the sync trigger. This keeps the UI completely ignorant of whether data is stored locally or in the cloud."*

**Your repositories:**
- `user_repository.dart` — profile CRUD
- `goal_repository.dart` — goals + predictive insight + auto-merge (your biggest file, 10KB)
- `activity_repository.dart` — activity logs + upsert logic
- `health_log_repository.dart` — health logs + BMI data
- `step_record_repository.dart` — daily step history (`getLast7DaysSteps()`)

---

### Point 3: The `.toMap()` Shared Translation Architecture

**What you say:**
> *"The most elegant design decision in the data layer is that every model's `.toMap()` method is the single source of truth for both SQLite and Firestore. When I call `db.insert('goals', goal.toMap())`, SQLite maps those keys to its column names. When SyncService calls `firestoreDoc.set(goal.toMap())`, Firestore accepts the exact same map and auto-generates the fields. When I added a new column like `category` to the goals table, I updated `.toMap()` once — and both databases received it automatically. Zero extra Firebase schema code."*

```dart
// One map → two databases
Map<String, dynamic> toMap() => {
  'id': id, 'user_id': userId, 'title': title,
  'category': category,          // added once, works in both
  'sync_status': syncStatus,     // drives the sync engine
  // ...
};
```

---

### Point 4: Predictive Insights Engine — `GoalRepository.getPredictiveInsight()`

**What you say:**
> *"Rather than just showing a static progress percentage, I built a predictive analytics engine inside the repository. For cumulative goals, it applies a linear regression across the goal's creation date and current value to calculate daily velocity — then projects whether the user will meet their deadline. The output is a natural-language string like 'At your current pace, you'll hit your target 3 days early.' For daily goals specifically, the engine bypasses the static `currentValue` column entirely and queries the `activities` table directly for today's actual sum — this solves the midnight carry-over bug where yesterday's progress would bleed into today's prediction."*

**Two-path logic:**
```
getPredictiveInsight(goalId)
    │
    ├── IF goal.baseType == 'daily'
    │       → SELECT SUM(value) FROM activities WHERE date = today AND type = goal.category
    │       → Compare to goal.targetValue → generate encouragement string
    │
    └── IF goal.baseType == 'cumulative'
            → Calculate velocity = currentValue / daysSinceCreation
            → Project daysToTarget = (targetValue - currentValue) / velocity
            → Compare to deadline → generate natural-language output
```

---

### Point 5: Auto-Merge Goal & Activity Architecture

**What you say:**
> *"There was a fundamental conflict in the data model: activities are timestamped by date, but goals only store a single `currentValue` with no date. If a user manually updates goal progress, that progress has no date anchor — it would appear as if it all happened today. My solution was an auto-merge: when `GoalRepository.updateGoalProgress()` is called, it calculates the delta — the difference between the new and old value — and silently inserts a timestamped `Activity` record for today's date. Now manual goal updates are permanently linked to the correct date and appear accurately in the 30-day charts."*

---

### Point 6: The Sync Engine — `sync_service.dart`

**What you say:**
> *"SyncService is a singleton with two primary methods. `syncData()` handles the outbound push: it queries for all records where `sync_status = 0`, calls Firestore's `.set()` with the model's `.toMap()`, and on success marks them `sync_status = 1`. If Firestore is unreachable, the record stays at `0` and gets picked up on the next sync cycle — the app works fully offline. `rehydrateData()` handles the inbound pull: on every login, AuthService triggers this, which fetches all Firestore subcollections and upserts them into SQLite using `ConflictAlgorithm.replace` — idempotent, safe to run multiple times."*

**Three sync trigger points:**
| Trigger | When | Direction |
|---|---|---|
| Login event (`authStateChanges`) | Every sign-in | Cloud → Local (rehydrate) |
| Dashboard pull-to-refresh | User action | Local → Cloud (push) |
| After every `insert*()` in repos | Immediate, async | Local → Cloud (push) |

---

### Point 7: Lazy Initialisation — Performance Architecture

**What you say:**
> *"To achieve zero-latency startup, I implemented lazy getters across the entire data layer. Instead of creating all repository instances when the app boots — which would initialise SQLite, connect to Firebase, and allocate memory for everything — each repository is created only when it's first accessed. A normal app initialising all services can add 1-2 seconds to the splash screen. Our app renders the first screen immediately, and the database only opens when the user first triggers a read or write."*

```dart
// Lazy getter — object created only on first call
SyncService get _syncService => SyncService();
GoalRepository get _goalRepo => GoalRepository();
```

---

### Point 8: Firebase Auth Integration — Your Contribution to `auth_service.dart`

**What you say:**
> *"Although Authentication is shared work, my specific contribution was the `_syncLocalUser()` method and the `updateUserProfile()` CRUD flow. When a user logs in, the service checks if their Firebase UID exists in the local SQLite `users` table. If not, it checks Firestore. If not there either, it creates a new local record. This three-way check ensures that whether it's a first-time registration, a returning user on the same device, or a user on a new device, the local profile is always populated correctly before the UI renders."*

---

### Point 9: Goal Classification — `Goal.baseType` getter

**What you say:**
> *"Every piece of charting and prediction logic in the app branches on whether a goal is 'daily' or 'cumulative'. I centralised this classification in a computed `baseType` getter on the `Goal` model. This means the charting screen, the prediction engine, and the sync layer all use one consistent definition — no magic strings scattered through the codebase. Daily goals render as per-day line charts. Cumulative goals render as a single progress bar from 0% to 100%."*

---

## Part 3 — Likely Examiner Questions & Answers

| Question | Answer |
|---|---|
| **"Why SQLite instead of just Firebase?"** | *"Offline capability. Firebase requires internet. SQLite works with zero connectivity. We use Firebase as an eventually consistent backup, not as the primary database."* |
| **"What is `sync_status`?"** | *"An integer column (0 or 1) on `goals`, `activities`, `health_logs`. `0` means the record hasn't reached Firestore yet. SyncService queries for `sync_status = 0` and pushes only those records, then marks them `1`. It's the flag that powers the entire offline-to-online transition."* |
| **"What is `ConflictAlgorithm.replace`?"** | *"It's SQLite's `INSERT OR REPLACE`. If a row with the same primary key already exists, it replaces it. If not, it inserts. This makes all our upsert operations idempotent — safe to run multiple times, which is critical for rehydration on login."* |
| **"How does profile picture work without file storage?"** | *"We convert the image bytes to a Base64 string using `dart:convert`. That string is stored in the `users.profile_picture` TEXT column. When the UI reads it, `MemoryImage(base64Decode(str))` converts it back to displayable bytes. No file path, no storage permission needed."* |
| **"What is the Repository Pattern?"** | *"An abstraction layer. The UI never writes raw SQL. It calls typed Dart methods like `goalRepo.insertGoal(goal)`. The repository translates that into SQL internally. This means we could swap SQLite for a different database without changing any UI code."* |
| **"What is lazy initialisation?"** | *"Instead of constructing all objects at app start, we use Dart `get` getters that create the object only on first access. Prevents startup delays and circular dependency crashes between SyncService and the Repositories."* |
| **"What is `rehydrateData()`?"** | *"On login, AuthService calls this. It fetches all Firestore subcollections (goals, activities, health_logs) for that user and upserts them into SQLite. A fresh device gets the complete data history in one shot, making the app multi-device ready."* |
| **"How does the predictive insight work?"** | *"For cumulative goals: linear regression — velocity = currentValue / daysSinceCreation, then project daysToTarget. For daily goals: query `activities` table for today's actual sum instead of using `goal.currentValue`, which prevents midnight carry-over inaccuracies."* |
| **"What is the midnight carry-over bug?"** | *"`goal.currentValue` is a static number with no date. If a daily goal was partially filled yesterday, that value persists into today — making today's prediction wrong. The fix: bypass `currentValue` entirely and query `SUM(activities.value) WHERE date = today` for the real current-day total."* |
| **"How does schema migration work?"** | *"`_onUpgrade()` in `DatabaseHelper` runs a chain of `if (oldVersion < N)` blocks. Each block adds columns via `ALTER TABLE`. Version 11 means 11 incremental upgrades, each backward-compatible. Users who haven't opened the app in months get all migrations applied sequentially without data loss."* |

---

## Part 4 — Quick Reference: Your Files & What They Own

| File | Your Role | Key Capability |
|---|---|---|
| `database/database_helper.dart` | **Schema Owner** | 9 tables, v11 migrations, singleton |
| `models/user.dart` | **Blueprint** | Base64 profile pic, theme persistence, `toMap()` |
| `models/goal.dart` | **Blueprint** | `baseType` getter (daily/cumulative classifier) |
| `models/activity.dart` | **Blueprint** | Date-anchored activity log |
| `models/health_log.dart` | **Blueprint** | BMI auto-calc, extended body metrics |
| `repositories/goal_repository.dart` | **Core Logic** | Predictive insight, auto-merge, push notification trigger |
| `repositories/activity_repository.dart` | **CRUD** | Activity insert + upsert for sync |
| `repositories/health_log_repository.dart` | **CRUD** | Health log insert + upsert |
| `repositories/user_repository.dart` | **CRUD** | Profile read/write |
| `repositories/step_record_repository.dart` | **CRUD** | `getLast7DaysSteps()` for charts |
| `services/sync_service.dart` | **Sync Engine** | `syncData()` outbound, `rehydrateData()` inbound |
| `services/auth_service.dart` | **Orchestrator** | `_syncLocalUser()`, `updateUserProfile()`, theme toggle |

---

## Part 5 — 30-Second Summary (Use as Closing Statement)

> *"My contribution is the complete data foundation of Uplift. I designed the 9-table SQLite schema and its 11-version migration chain. I built the repository layer that abstracts all database access from the UI. I engineered the bidirectional sync engine that mirrors SQLite to Firestore using `sync_status` flags, making the app truly offline-first. And I implemented the predictive insights engine — a linear regression model in the data layer that outputs human-readable goal forecasts. The architecture decision I'm most proud of is the `.toMap()` shared translation layer — one method that serves as the schema contract for both SQLite and Firestore, enabling zero-configuration cloud scaling."*
