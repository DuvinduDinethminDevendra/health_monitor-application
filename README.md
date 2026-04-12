# Integrated Digital Health Monitoring Platform

A professional Flutter-based digital wellness application designed for a health-tech startup. This platform enables users to monitor their health metrics, track physical activities, and receive expert tips remotely.

## 🚀 Key Features

- **Secure User Authentication:** Robust sign-up and login protocols using secure cryptography.
- **Activity Tracking:** Log steps, duration, and various workout types.
- **Health Data Logging:** Track vital metrics like weight and BMI.
- **Goal Management:** Set, track, and monitor personalized health and fitness goals.
- **Expert Health Tips:** Fetched dynamically via REST API.
- **Progress Analytics:** Integrated interactive charts for health trend visualization.
- **Scheduled Reminders:** Background and local notifications to keep users on track with their health tasks.

## 🛠 Technical Stack

- **Framework:** Flutter (Dart)
- **Database:** SQLite (`sqflite`) for robust, offline-first local storage.
- **Design Pattern:** Repository Pattern for clean data abstraction.
- **State Management:** Provider for scalable and reactive app state.
- **Charts & Data Viz:** `fl_chart` for progress analytics formatting.
- **Notifications:** `flutter_local_notifications` for scheduled reminders.

## 📁 Project Structure

```text
lib/
├── database/         # SQLite database initialization and configuration
├── models/           # Data entities (User, Activity, Goal, Health Log)
├── repositories/     # Repository pattern implementations for data access
├── screens/          # App UI screens (Auth, Dashboard, Charts, Goals, etc.)
├── services/         # External APIs and background services (Auth, Tips, Notifications)
└── main.dart         # Main application entry point
```

## ⚙️ Getting Started

### Prerequisites

- Flutter SDK (>=3.7.2)
- Dart SDK
- Android Studio or Visual Studio Code with Flutter extensions installed

### Installation

1. **Clone the repository:**
   ```bash
   git clone <repository_url>
   ```

2. **Navigate to the project directory:**
   ```bash
   cd health_monitor
   ```

3. **Install the dependencies:**
   ```bash
   flutter pub get
   ```

4. **Run the application:**
   Ensure you have a device connected or an emulator/simulator running, then use:
   ```bash
   flutter run
   ```
