# Project Report Blueprint: Uplift

This document follows the exact structure required by the University Guidelines. Each section contains the technical data needed for the final PDF report.

---

## 1. Title / Cover Page
*   **App Name**: Uplift
*   **Domain**: Health Informatics & Personal Wellness
*   **Developer Group**:  GROUP No. 13  Descenders
*   **Group Members**: [Your Name], [Duvindu's Name], [Nepul's Name]
*   **Submission Date**: April 2026

---

## 2. Abstract / Executive Summary
A comprehensive health tracking solution built with Flutter, designed for high-performance offline data management and cloud synchronization. The app solves the problem of fragmented health data by providing a unified "Matte-Glass" dashboard for BMI tracking, activity logging, and goal setting. Utilizing a dual-layered storage system (SQLite + Firebase), the app ensures 100% data availability.
*   **Tech Stack**: Flutter, Dart, Firebase, SQLite, Provider, fl_chart.

---

## 3. Table of Contents
*(To be generated in final PDF)*

---

## 4. Introduction & Project Context
The personal health tracking domain is often cluttered with complex, English-only applications. This project aims to bridge the gap by providing a culturally relevant (Bilingual: English/Sinhala), visually premium, and technically robust monitor that provides predictive insights rather than just raw data.

### 4.1 Functional Requirements (SRS Style)
*   **User Management**: Secure login via Email or Google OAuth with persistent session management.
*   **Activity Monitoring**: Automated step counting via device hardware sensors and manual activity logging.
*   **Visual Documentation**: Integration with the device **Camera** and **Gallery** for user profile personalization and health record attachments.
*   **Health Documentation**: Recording weight, height, and automated BMI calculation.
*   **Goal Tracking**: Setting and monitoring daily/cumulative targets for hydration, sleep, and fitness.
*   **Insights**: Generating interactive charts for 30-day health trends.
*   **Knowledge Base**: A dedicated Health Tips section fetching real-time data via a REST API.
*   **Alert System**: Push notifications and reminders for goal deadlines.

### 4.2 Non-Functional Requirements
*   **Data Integrity**: Dual-side synchronization (Local to Cloud and Cloud to Local).
*   **Availability**: Offline-first operation via SQLite; multi-device support via Firebase.
*   **Aesthetics**: Global theming system supporting Light/Dark modes with preference persistence.
*   **Usability**: Locale-aware UI with dynamic font scaling for Sinhala/English.
*   **Performance**: Background synchronization to minimize data usage and battery drain.

---

## 5. System Architecture
The system follows a **Layered Repository Pattern** optimized for production.

> **ACTION: [INSERT SYSTEM ARCHITECTURE DIAGRAM HERE]**
> *The diagram should show the flow: UI -> Provider -> Repository -> SQLite / Firebase.*

*   **Presentation Layer**: Flutter Widgets (Stateful/Stateless) + Provider Listeners.
*   **Domain Layer**: State management and business logic (AuthService, SyncService).
*   **Data Layer**: Abstract Repositories connecting to both Local (Sqflite) and Remote (Firebase) sources.

---

## 6. Layer-by-Layer Implementation Details

### 6.1 UI Architecture & Navigation
*   **Navigation Strategy**: Implementation of a persistent `BottomNavigationBar` using an `IndexedStack` to preserve the state of different screens.
*   **Named Routes**: Use of `MaterialPageRoute` for secondary screens like "Add Activity" and "Health Log".
*   **Route Guards**: Authentication-based gating. The `main.dart` entry point checks `AuthService.isLoggedIn` to redirect users.

### 6.2 State Management & Business Logic
*   **Pattern**: **Provider**.
*   **Separation of Concerns**: UI widgets handle only rendering. All logic (API calls, calculations, state updates) is in `ChangeNotifier` classes.

### 6.3 Database & Data Layer (Production Grade)

> **ACTION: [INSERT ER DIAGRAM HERE]**
> *The diagram should show the 5 tables (Users, HealthLogs, Goals, Activities, Notifications) and their relationships via userId.*

*   **SQLite Schema**: Includes 5 related tables: `Users`, `HealthLogs`, `Goals`, `Activities`, and `Notifications`.
*   **Repository Pattern**: Data access is abstracted through classes like `HealthLogRepository`.
*   **Sync Logic**: Sophisticated background sync that merges local changes with Cloud Firestore, enabling **Multi-Device Support**. If a user logs in on a new phone, their data is instantly pulled down from the cloud.

### 6.4 API & Device Features
*   **Networking**: Communication with Firebase via `firebase_core` and `cloud_firestore` with `async/await`.
*   **External API Integration**: Fetching dynamic Health Tips from a production-grade REST API to provide daily educational content.
*   **Hardware Sensor Fusion**: Implementation of the `Pedometer` API to access real-time accelerometer data for automated physical activity tracking.
*   **Multimedia Integration**: Use of the `Image_Picker` API to interface with the device **Camera** and photo library for profile data management.
*   **Notifications**: Sophisticated goal reminders and health alerts using `flutter_local_notifications`.

---

## 7. Core Features & Optimizations

*   **Bilingual Engine**: Custom i18n implementation with a locale-aware font scaling solution for Sinhala scripts.
*   **Dynamic Theming**: A global theme system supporting High-Contrast Dark and Light modes, with user preferences saved to the database.
*   **Interactive Charts**: Multi-axis charts showing BMI, weight, and activity correlations.
*   **Predictive Deadlines**: Algorithmically calculating goal completion dates based on 30-day velocity.
*   **Matte-Glass Design**: A custom design system utilizing HSL color palettes and backdrop filters.

---

## 8. Challenges & Solutions
*   **Conflict Resolution**: Handled major dependency conflicts during the branch merge by manually pinning `intl` and `syncfusion` versions.
*   **Font Rendering**: Solved Sinhala script overflow issues by implementing a global font-scaling helper (`_siSize`).

---

## 9. Conclusion & Future Enhancements
The project successfully delivers a production-ready health monitor. Future versions will include AI-driven dietary advice and integration with wearable hardware.

---

## 10. Individual Contribution Declaration
*   **[Your Name]**: System Theming, Localization Engine, UI Architecture, Routing, and Version Conflict Management.
*   **[Member 2]**: Firebase Cloud Integration, Auth Logic, Offline Sync Engine, Multi-Device Support.
*   **[Member 3]**: Database Schema, Chart Visualizations, Pedometer Integration, Health Tips API.

---

## 11. References
*   Flutter Documentation (flutter.dev)
*   Firebase Documentation (firebase.google.com)
*   Packages: `provider`, `fl_chart`, `sqflite`, `syncfusion_flutter_gauges`, `intl`, `pedometer`.

---

## 12. Appendices
*   **GitHub Repository**: [Insert Link Here]
*   **Installation**: Run `flutter pub get` followed by `flutter run`.
*   **Assets**: See `assets/images` for UI mockups and iconography.
