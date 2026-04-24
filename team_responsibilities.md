# Team Responsibilities & File Mapping

This document outlines the responsibilities of each team member and maps them to the specific files and folders they will be working on in the `health_monitor` project.

## Member 1: UI Architecture & Navigation
**Responsibilities:** Layouts, responsiveness, routing.
**Key Files and Folders:**
- `lib/main.dart` (Routing setup and core app styling)
- `lib/screens/activity_screen.dart`
- `lib/screens/charts_screen.dart`
- `lib/screens/dashboard_screen.dart`
- `lib/screens/goals_screen.dart`
- `lib/screens/health_log_screen.dart`
- `lib/screens/health_tips_screen.dart`
- `lib/screens/login_screen.dart`
- `lib/screens/register_screen.dart`
- `lib/screens/reminders_screen.dart`

## Member 2: State Management & Business Logic
**Responsibilities:** Bloc/Provider, validation, logic separation.
**Key Files and Folders:**
- `lib/providers/` or `lib/blocs/` (Future directory for state management classes)
- Validation logic integration within `lib/screens/register_screen.dart` and `lib/screens/login_screen.dart`
- ViewModels / Controllers (to separate UI from logic)

## Member 3: Database & Data Layer
**Responsibilities:** SQLite schema, repository pattern.
**Key Files and Folders:**
- `lib/database/database_helper.dart` (SQLite schema & queries)
- `lib/models/activity.dart`
- `lib/models/goal.dart`
- `lib/models/health_log.dart`
- `lib/models/user.dart`
- `lib/repositories/activity_repository.dart`
- `lib/repositories/goal_repository.dart`
- `lib/repositories/health_log_repository.dart`
- `lib/repositories/user_repository.dart`

## Member 4: API Integration & Device Features
**Responsibilities:** Networking, async handling, plugin integration.
**Key Files and Folders:**
- `lib/services/` (Directory for API integrations, e.g., `api_service.dart`)
- `pubspec.yaml` (Managing plugin dependencies)
- Device features integration like `flutter_local_notifications` (e.g., inside `lib/services/notification_service.dart`)
- Android/iOS native configuration files for plugins (e.g., `android/app/build.gradle.kts`, `ios/Runner/Info.plist`)
