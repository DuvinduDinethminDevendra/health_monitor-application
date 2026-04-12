# Integrated Digital Health Monitoring Platform

A professional Flutter-based digital wellness application designed for a health-tech startup. This platform enables users to monitor their health metrics, track physical activities, and receive expert tips remotely.

## 🚀 Key Features

- **Secure User Authentication:** Robust sign-up and login protocols.
- **Activity Tracking:** Log steps and various workout types.
- **Health Data Logging:** Track vital metrics like Weight and BMI.
- **Goal Management:** Set and monitor personalized health goals.
- **Expert Health Tips:** Fetched dynamically from an external REST API.
- **Progress Analytics:** Integrated charts for health trend visualization.
- **Scheduled Reminders:** Background notifications for health tasks.

## 🛠 Technical Stack

- **Framework:** Flutter (Dart)
- **Database:** SQLite (Relational structure for User, Activities, and Goals)
- **Design Pattern:** Repository Pattern for data abstraction.
- **State Management:** Provider or Bloc recommended.
- **Notifications:** Background notification services for reminders.

## 📁 Project Structure

```text
lib/
├── core/             # Themes, constants, and utilities
├── data/
│   ├── models/       # Data entities (User, Activity, Goal)
│   ├── local/        # SQLite database implementation
│   ├── remote/       # API Services for health tips
│   └── repositories/ # Repository pattern implementations
├── presentation/
│   ├── screens/      # Auth, Dashboard, Progress, Goals
│   ├── widgets/      # Charts, form validations, and UI components
│   └── state/        # State management logic
└── main.dart
