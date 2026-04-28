# Project Setup vs. Requirements Report

## 1. Advanced Navigation
*   **What we have:** Multiple screens set up (`login_screen.dart`, `dashboard_screen.dart`, etc.), which implies basic routing.
*   **What is missing:** It is unclear if robust **Named Routes**, **Nested Navigation** (e.g., a persistent BottomNavigationBar), or **Route Guards** (e.g., redirecting users to the login screen if they aren't authenticated) are fully implemented. These need to be explicitly set up in `main.dart`.

## 2. State Management (Advanced)
*   **What we have:** The `provider` package is included in `pubspec.yaml`.
*   **What is missing:** A dedicated `providers/` or `view_models/` folder. Currently, business logic might be entangled with the UI (using `setState`). This logic needs to be extracted into Provider classes to achieve a true separation of UI and business logic.

## 3. Clean Architecture Structure
*   **What we have:** Great progress! The app is separated into logical layers:
    *   **Data Layer:** `database_helper.dart` and `models/`
    *   **Repository Pattern:** Implemented via the `repositories/` folder.
    *   **Presentation Layer:** Implemented via the `screens/` folder.
*   **What is missing:** The **Business Logic Layer**. As mentioned in the State Management section, distinct Provider classes are needed to link the Repositories to the Screens.

## 4. Local & Remote Data Integration
*   **What we have:** 
    *   **Local (SQLite):** Well established. `sqflite` is in the dependencies, `database_helper.dart` is created, and a relational setup is likely ready given the multiple entities (`activity`, `goal`, `health_log`, `user`).
    *   The `http` package is added, which is the first step for REST APIs.
*   **What is missing:** 
    *   **Remote (REST API):** The `lib/services/` folder is currently empty. An API communication service (e.g., `lib/services/api_service.dart`) needs to be created using the `http` package to fetch or send external data.
    *   Structured error and exception handling tailored for API timeouts or failures.

## 5. Authentication Simulation
*   **What we have:** `login_screen.dart`, `register_screen.dart`, and a `user.dart` model are present. The `crypto` package is in `pubspec.yaml`, suggesting local password hashing setup.
*   **What is missing:** Ensuring that the authentication state actually dictates the app flow (e.g., locking out users who aren't logged in, tying back to **Advanced Navigation router guards**). 

## 6. Device Feature Integration
*   **What we have:** Complete! `flutter_local_notifications` is in the dependencies and build folders, plus a `reminders_screen.dart` which aligns perfectly with pushing local notifications or background tasks.
*   **What is missing:** Just ensure the notification permission prompts and native setup (updating Android `AndroidManifest.xml` and iOS `AppDelegate.swift`) have been fully configured.

## 7. Performance & UX Optimization
*   **What we have:** Flutter SDK `^3.7.2` is used, which natively enforces **Null Safety**.
*   **What is missing:** Verification that the UI utilizes:
    *   **Form Validation:** Crucial for the Login/Register screens.
    *   **Loading Indicators:** Showing `CircularProgressIndicator` during database queries or (future) API calls.
    *   **Lazy Loading / Pagination:** If `health_log` or `activity` tables get large, ensuring the use of `ListView.builder` optimally, potentially adding pagination.

## 8. Member 3 Feature Enhancements (Completed)
*   **Step 1: Advanced Profile Management (Data Layer Upgrade):**
    *   **Completed:** Expanded the SQLite Database `users` table (v4 -> v5) and `User` model to support `age`, `gender`, `height`, `weight`, and local `profile_picture` storage (Base64). Added `updateUserProfile` into `AuthService` to persist local changes securely.
*   **Step 2: Advanced Goals & Time-Based Reminders:**
    *   **Completed:** Migrated the `goals` table to Schema V6 to natively store `category` and `reminder_time`. Upgraded the notification system in `GoalRepository` to dynamically pull category specific congratulations. 
*   **Step 3: The "Predictive Insights" Engine:**
    *   **Completed:** Re-engineered the Linear Regression function locally within SQLite's Dart abstraction. Added a `getPredictiveInsight` function that transforms mathematical velocity into human-readable analysis strings native to the database layer.
*   **Step 4: UI Data Binding & Smart Profile Screen:**
    *   **Completed:** Designed `lib/screens/profile_screen.dart` strictly to visualize the Data Layer's offline SQLite attributes, mapping the newly structured `age`, `height`, and `weight` into interactive text forms that trigger real-time SQL `UPDATE` operations without needing complex Cloud commands. Added the Predictive Insights to the main `charts_screen.dart`.
*   **Step 5: True Adaptive Charts UI & Auto-Merge Logic:**
    *   **Completed:** Split visualizations in `charts_screen.dart` to support both Cumulative (Percentage Bar Chart) and Daily Reset (Historical Line Chart) goals.
    *   **Completed:** Engineered an "Auto-Merge" architecture that dynamically links the `activities` table with the `goals` table across a 30-day trailing window. Implemented industry-standard conflict resolution (`math.max(daySum, goal.currentValue)`) for the current day to intelligently combine manual progress updates with automated activity tracking, ensuring accurate visualization without double-counting data.
    *   **Completed:** Enhanced UI clarity by injecting dashed, horizontal Goal Target lines across the Line Charts, allowing users to visually track their daily achievements against their explicitly defined goals.

## 9. Architectural Milestone: The Zero-Code Auto-Sync
**Core Architecture Validation:** The application now successfully demonstrates "Map-Translation" driven Async Synchronization between SQLite and Firestore. By centralizing the schema into the Dart Model's `.toMap()` translation method, Firebase Firestore inherits any local SQLite modifications dynamically. When a new column like `category` or `reminder_time` was added, Firebase simply observed the new dictionary key being pushed by the Background Worker (`SyncService`) and auto-generated cloud tables with absolutely **zero extra mapping code** required. This is a true testament to the power of decoupled `Repository Patterns`.

---

## 🚀 Action Items (Next Steps)
1.  **Create a `lib/providers/` directory** and move logic out of UI screens into Provider classes.
2.  **Add an API Service** inside `lib/services/api_service.dart` to consume remote data.
3.  **Implement Route Guards** in the navigator to protect internal screens from unauthenticated users.