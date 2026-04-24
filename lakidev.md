# Member 3: LakiDev (LSR Vidanaarachchi)
**Regno:** TG/2020/1010
**Role:** Database & Data Layer (SQLite Schema, Repository Pattern)

---

## 📋 Primary Tasks & Scope
1. **Secure User Authentication:** **Firebase Auth** integration for marks and security.
2. **Hybrid Data Layer (Cloud-Edge Sync):**
   - **Primary:** SQLite for offline-first local persistence (Viva Requirement).
   - **Secondary:** Firebase Firestore for cloud backup and multi-device sync.
3. **Smart Goal Management System:**
   - Full CRUD for health goals.
   - Smart tracking (Weight loss plans, target tracking).
   - "Nudge" triggers for Member 4's notification system.
4. **Architecture:** Maintain strict Repository Pattern to abstract SQLite/Firebase logic.

---

## 🏗 System Architecture (Member 3 Layer)
### 1. Hybrid Sync Strategy
- **SQLite-First Write:** Data is written to SQLite immediately for low latency.
- **Async Cloud Mirror:** A `SyncService` background-pushes SQLite changes to Firestore.
- **Cloud Restoration:** On login, if SQLite is empty, data is pulled from Firestore to "rehydrate" the local database.

### 2. Smart Goal Features
- **Weight Loss Logic:** Set target weight vs current weight.
- **Progress Milestones:** Automatic calculation of % completion.
- **Predictive Dates:** Calculate "Estimated Completion Date" based on recent activity logs.

---

## 👥 Cross-Member Dependencies (Coordination Notes)
| Affected Member | Integration Detail | Action Required |
| :--- | :--- | :--- |
| **Member 1 (UI)** | Sync UI & Goal Forms | Add "Syncing" status indicator & Advanced Goal input fields. |
| **Member 2 (Logic)** | State Management | Ensure Providers handle data restoration states from Cloud sync. |
| **Member 4 (Device)** | Notifications | I will provide `GoalProgressTrigger` events; Member 4 handles the notification display. |

---

## 🚦 Implementation Status

### 1. Database & Schema
- [x] Initial SQLite schema setup (`database_helper.dart`).
- [ ] **TODO:** Update Schema (Change IDs from `INTEGER` to `TEXT` for UID compatibility).
- [ ] **TODO:** Add `sync_status` flag to tables.

### 2. Repository Pattern
- [x] Basic Repositories created.
- [ ] **TODO:** Integrate `SyncService` into `GoalRepository` and `UserRepository`.
- [ ] **TODO:** Implement "Predictive Logic" in `GoalRepository`.

### 3. Firebase Integration
- [ ] Add `firebase_auth` & `cloud_firestore` dependencies.
- [ ] Implement `AuthService` (Firebase).
- [ ] Implement `SyncService` (Firestore).

---

## 📝 Developer Notes (Viva Prep)
- **Why Hybrid?** To demonstrate high-level architecture. SQLite handles speed/offline, Firebase handles persistence/portability.
- **Relational Integrity:** Ensure `user_id` in SQLite matches the Firebase UID exactly.
- **Performance:** Use async non-blocking calls for sync so the UI never freezes.
