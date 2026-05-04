# Uplift — Integrated Digital Health Monitoring Platform
## Final Project Report | ICT4153 Mobile Application Development

| Field | Details |
|---|---|
| **Module** | ICT4153 — Mobile Application Development |
| **Group No.** | 13 — Descenders |
| **Institution** | Department of ICT, Faculty of Technology, University of Ruhuna |
| **Submission** | April 2026 |

### Group Members

| Reg. No. | Name | Responsible Layer |
|---|---|---|
| TG/2020/XXXX | MASV Karunathilak | UI Architecture & Navigation |
| TG/2020/XXXX | MMND Senivirathne | API Integration & Device Features |
| TG/2020/1010 | LSR Vidanaarachchi | Database & Data Layer |
| TG/2020/XXXX | BDD Devendra | State Management & Business Logic |

---

## Table of Contents

1. Abstract
2. Introduction & Project Context
3. System Architecture
4. Implementation Details
5. Core Features & Optimizations
6. Challenges & Solutions
7. Conclusion & Future Enhancements
8. Individual Contribution Declaration
9. References
10. Appendices

---

## 1. Abstract

This report documents the design, architecture, and implementation of **Uplift**, a production-grade personal health monitoring application built with Flutter for Android. The application addresses fragmentation in the personal health technology space by consolidating step tracking, body measurement logging, goal management, and health education into a single, culturally relevant platform with bilingual support for English and Sinhala.

The core architectural decision is an **Offline-First, Dual-Storage** strategy: all data is written to a local SQLite database immediately, ensuring availability regardless of network state, while a background synchronisation engine mirrors data to Firebase Cloud Firestore for multi-device continuity. The technical stack comprises Flutter/Dart, Provider, Sqflite (schema v11), Firebase Auth, Cloud Firestore, fl_chart, syncfusion_flutter_gauges, and the Pedometer hardware API.

---

## 2. Introduction & Project Context

Existing health monitoring applications are largely designed for English-speaking, consistently connected users. This project addresses those gaps by providing a premium, offline-capable health monitor that generates predictive insights from user data rather than simply displaying raw numbers.

Uplift was developed as a group assignment simulating a commercial health-tech product for ICT4153 at the University of Ruhuna.

### 2.1 Functional Requirements

| ID | Requirement |
|---|---|
| FR-01 | Secure registration/login via Email/Password |
| FR-02 | Google OAuth social authentication |
| FR-03 | Persistent session management across restarts |
| FR-04 | Automated step counting via device hardware sensor |
| FR-05 | Manual activity and workout logging |
| FR-06 | BMI auto-calculation from weight and height |
| FR-07 | Extended body metrics (waist, hip, chest, body fat) |
| FR-08 | Daily and cumulative goal tracking |
| FR-09 | Goal-completion push notifications |
| FR-10 | 30-day interactive charts (activity, BMI, weight) |
| FR-11 | Predictive goal deadline via linear regression |
| FR-12 | Health Tips from external REST API with disk caching |
| FR-13 | Favourites and Recently Viewed for Health Tips |
| FR-14 | Profile photo via device Camera/Gallery |
| FR-15 | Configurable reminders (banner and alarm modes) |
| FR-16 | Light/Dark theme with database persistence |
| FR-17 | Bilingual UI (English / Sinhala) |

### 2.2 Non-Functional Requirements

| Category | Requirement |
|---|---|
| Data Integrity | Bidirectional sync (SQLite ↔ Firestore) with `sync_status` flags |
| Availability | Full functionality without internet connectivity |
| Multi-Device | Data rehydrated from Firestore on login on any device |
| Performance | Lazy repository initialisation for zero-latency startup |
| Aesthetics | Dual-theme design system (Matte Alabaster / Solid Sapphire) |
| Usability | Locale-aware font scaling for Sinhala script |
| Background | Step tracking and sync continue while app is backgrounded |

---

## 3. System Architecture

### 3.1 Layered Repository Pattern

The application enforces a strict three-layer architecture with a single-direction dependency flow. No layer communicates with a layer above it.

> **[ACTION: INSERT SYSTEM ARCHITECTURE DIAGRAM HERE]**
> *Flow: User → Flutter UI → ViewModels/Providers → Repository Layer → SQLite (Primary) / Firebase (Secondary)*

**Presentation Layer** — All visual components in `lib/screens/` and `lib/widgets/`. Widgets consume Provider state and dispatch user events. They contain no database or network logic.

**Domain Layer** — `AuthService`, `ActivityProvider`, and `HealthTipsProvider` implement `ChangeNotifier`. This layer owns all business logic: authentication lifecycle, step delta calculation, predictive insight generation, and cache invalidation.

**Data Layer** — Repository classes (`GoalRepository`, `ActivityRepository`, `HealthLogRepository`, `StepRecordRepository`) provide an abstract CRUD interface. `SyncService` bridges SQLite and Firestore. `DatabaseHelper` owns the physical schema and all migration logic.

### 3.2 Offline-First Dual-Storage Strategy

**Write Path (Local → Cloud):** Every insert operation targets SQLite first with `sync_status = 0`. `SyncService` is called asynchronously — if online, the record is pushed to Firestore and `sync_status` is set to `1`; if offline, the flag remains `0` and the record is picked up during the next `syncData()` cycle.

**Read Path (Cloud → Local):** On every login, `AuthService` calls `SyncService.rehydrateData(userId)`, which fetches all Firestore subcollections and upserts them into SQLite using `ConflictAlgorithm.replace`. A fresh device instantly receives the user's complete history.

**Zero-Configuration Scaling:** Each model's `.toMap()` method is the shared translation layer consumed by both `db.insert()` (SQLite) and `.set()` (Firestore). Adding a new model field automatically extends both databases with zero additional configuration code.

---

## 4. Implementation Details

### 4.1 UI Architecture & Navigation

**IndexedStack Navigation:** The main scaffold uses `IndexedStack` with `BottomNavigationBar`. Unlike `PageView`, `IndexedStack` keeps all child widgets alive simultaneously — switching tabs preserves scroll positions and loaded state, delivering a native app experience.

**Route Guards:** The `main.dart` root widget wraps the app in a `Consumer<AuthService>`. When `AuthService.isLoggedIn` is false, the `LoginScreen` is rendered; when true, the `MainScaffold` is shown. Because `AuthService` calls `notifyListeners()` on every `authStateChanges()` event, this guard is fully reactive — logout from any screen immediately redirects the user.

**Design System:** The UI follows the "Matte Alabaster & Solid Sapphire" dual-theme documented in `DESIGN.md`. All colour values are defined in a central `AppTheme` class. Direct use of `Colors.*` Flutter primitives is prohibited — all colour references flow through `AppTheme`. Primary accent: Scooter (`#2F9D94`). Dark background: Sapphire (`#0F172A`).

### 4.2 State Management & Business Logic

All state is managed via **Provider** with `ChangeNotifier`. A `MultiProvider` at the widget tree root registers all providers for dependency injection. The strict rule is: widgets render, providers think.

**ActivityProvider Catch-Up Mechanism:** On every app launch, `_runCatchUpCheck()` reads `last_active_date` from `SharedPreferences`. If it predates today, the cached `current_steps` value is inserted as a historical record for the missed date — ensuring no day is lost even if the background service failed due to a device power-off.

**Background Isolate User ID:** `ActivityProvider.loadData()` writes the authenticated UID to `SharedPreferences` under `active_user_id`. The `BackgroundStepService` runs in a separate isolate where Firebase Auth is inaccessible; it reads this key to identify the current user for `step_records` writes.

### 4.3 Database & Data Layer

The SQLite database is at **schema version 11**, upgraded incrementally via `DatabaseHelper._onUpgrade()`.

> **[ACTION: INSERT ER DIAGRAM HERE]**
> *Tables: USERS, GOALS, ACTIVITIES, HEALTH_LOGS, STEP_RECORDS, WORKOUT_RECORDS, REMINDERS, FAVORITE_TIPS, RECENT_TIPS*

**Key Schema Decisions:**

- `users.id` uses Firebase UID (`TEXT PRIMARY KEY`) as the unifying identity across local and cloud stores.
- `users.profile_picture` stores images as Base64 TEXT — no file-system permissions required.
- `users.interests` stores a JSON-encoded array for Health Tips personalisation.
- `users.is_dark_mode` persists theme preference as INTEGER 0/1, loaded at startup before the first frame renders.
- `goals`, `activities`, `health_logs` all carry `sync_status INTEGER DEFAULT 0` — the flag that drives the sync engine.
- `reminders` is intentionally not user-scoped (no `user_id` FK) and not cloud-synced — it holds device-local notification schedules.
- `step_records` stores one row per user per day; background writes use `ConflictAlgorithm.replace` for idempotency.

**Predictive Insights (GoalRepository):** `getPredictiveInsight()` applies a linear regression to `createdAt` and `currentValue` to project the estimated completion date. For daily goals, it queries `activities` for today's actual sum rather than reading the static `currentValue`, preventing midnight carry-over inaccuracies. Output is a natural-language string passed to the UI.

**Auto-Merge Architecture:** When a user manually updates goal progress, `GoalRepository` calculates the delta and inserts a timestamped `Activity` record for the current date. This anchors all progress to its correct date in the `activities` table, producing accurate 30-day trend charts.

### 4.4 API Integration & Device Features

**Firebase Authentication:** `AuthService` listens to `_auth.authStateChanges()`. On sign-in, it calls `_syncLocalUser()`, which checks whether the user profile exists locally or in Firestore, then inserts or restores accordingly. Both Email/Password and Google OAuth flows are supported, with explicit error code handling for `email-already-in-use`, `weak-password`, and `invalid-credential`.

**Health Tips REST API:** The `HealthTipsService` integrates with the MyHealthFinder API (`health.gov`) using `Dio` with a `DioCacheInterceptor` backed by a `HiveCacheStore`. The caching policy is **Instant-First**: the UI renders from disk cache immediately; fresh data is only fetched on explicit pull-to-refresh. HTML content is rendered natively using `flutter_widget_from_html`.

**Pedometer / Background Step Tracking:** `PedometerService` interfaces with the Android hardware step sensor. Because the sensor returns a monotonically increasing total-since-reboot value, a `_stepOffset` is maintained in `SharedPreferences` to compute the accurate daily delta. `BackgroundStepService` runs via `flutter_background_service`, persisting daily totals to `step_records` with `INSERT OR REPLACE`.

**Image Picker:** Profile photos are captured via `image_picker`, encoded to Base64, stored in `users.profile_picture`, and decoded by the UI using `MemoryImage(base64Decode(...))` — requiring no additional storage permissions.

**Notification System:** `NotificationService` implements two channels:
- **Banner** (`health_reminders_banner`): High-priority, auto-dismissing standard reminders.
- **Alarm** (`health_reminders_alarm_v5`): `fullScreenIntent`, `FLAG_INSISTENT` looping sound, custom vibration pattern, "Stop" action button, 120-second auto-timeout.

Notifications are scheduled via `zonedSchedule()` with daily repetition. A self-contained timezone detection utility maps device UTC offset to IANA timezone strings, with `Asia/Colombo (+05:30)` as the primary entry.
