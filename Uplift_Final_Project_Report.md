# 1. Title / Cover Page

*   **App Name:** Uplift
*   **Domain:** Health Informatics & Personal Wellness
*   **Institution:** University of Ruhuna
*   **Developer Group:** GROUP No. 13 - Descenders
*   **Group Members:** Lakindu Sadumina, Duvindu, Nepul
*   **Submission Date:** April 2026

---

# 2. Abstract / Executive Summary

The "Uplift" application is a comprehensive health tracking solution built with the Flutter framework, meticulously designed for high-performance offline data management and seamless cloud synchronization. This project effectively addresses the pervasive issue of fragmented health data by delivering a unified, visually refined "Matte-Glass" dashboard. Through this central interface, users can effortlessly manage Body Mass Index (BMI) tracking, log daily physical activities, and establish personalized wellness goals. By leveraging a sophisticated dual-layered storage architecture that combines SQLite for localized persistence with Firebase for remote cloud backup, the application guarantees 100% data availability, even in offline scenarios. The robust technology stack incorporates Flutter, Dart, Firebase, SQLite, the Provider state management solution, and the `fl_chart` library for dynamic data visualization.

---

# 3. Table of Contents

1. [Title / Cover Page](#1-title--cover-page)
2. [Abstract / Executive Summary](#2-abstract--executive-summary)
3. [Table of Contents](#3-table-of-contents)
4. [Introduction & Project Context](#4-introduction--project-context)
    *   [4.1 Functional Requirements](#41-functional-requirements)
    *   [4.2 Non-Functional Requirements](#42-non-functional-requirements)
5. [System Architecture](#5-system-architecture)
6. [Layer-by-Layer Implementation Details](#6-layer-by-layer-implementation-details)
    *   [6.1 UI Architecture & Navigation](#61-ui-architecture--navigation)
    *   [6.2 State Management & Business Logic](#62-state-management--business-logic)
    *   [6.3 Database & Data Layer (Production Grade)](#63-database--data-layer-production-grade)
    *   [6.4 API & Device Features](#64-api--device-features)
7. [Core Features & Optimizations](#7-core-features--optimizations)
8. [Challenges & Solutions](#8-challenges--solutions)
9. [Conclusion & Future Enhancements](#9-conclusion--future-enhancements)
10. [Individual Contribution Declaration](#10-individual-contribution-declaration)
11. [References](#11-references)
12. [Appendices](#12-appendices)

---

# 4. Introduction & Project Context

The contemporary domain of personal health tracking is frequently characterized by applications that are overly complex and predominantly English-centric. The Uplift project aims to bridge this discernible gap by providing a culturally relevant health monitor that supports a bilingual interface (English and Sinhala). Beyond its visually premium aesthetic, the application is engineered to be technically robust, offering users predictive, actionable insights rather than merely presenting raw, unprocessed health metrics.

### 4.1 Functional Requirements

*   **User Management:** The system facilitates secure user authentication through Email or Google OAuth protocols, ensuring persistent and reliable session management.
*   **Activity Monitoring:** The application features automated step counting by interfacing with device hardware sensors, supplemented by a manual activity logging mechanism.
*   **Visual Documentation:** Users can personalize their profiles and attach visual records to their health documentation through seamless integration with the device Camera and Gallery.
*   **Health Documentation:** The platform supports the rigorous recording of essential physical metrics, including weight and height, while automating the calculation of the user's BMI.
*   **Goal Tracking:** Users possess the ability to set and monitor both daily and cumulative targets spanning hydration, sleep, and physical fitness.
*   **Insights:** The system generates dynamic, interactive charts that visualize health trends over a 30-day period.
*   **Knowledge Base:** A dedicated Health Tips module enriches the user experience by fetching real-time, educational health data via a designated REST API.
*   **Alert System:** To sustain user engagement, the application employs push notifications and automated reminders concerning goal deadlines.

### 4.2 Non-Functional Requirements

*   **Data Integrity:** The architecture enforces a dual-side synchronization protocol, ensuring accurate data mirroring from Local to Cloud and vice versa.
*   **Availability:** The application operates on an offline-first paradigm utilizing SQLite, while concurrent multi-device support is achieved through Firebase integration.
*   **Aesthetics:** A global theming system is implemented, providing comprehensive Light and Dark modes alongside persistent user preference management.
*   **Usability:** The user interface is locale-aware, featuring dynamic font scaling specifically engineered to accommodate both Sinhala and English scripts fluidly.
*   **Performance:** Background data synchronization is optimized to strictly minimize cellular data consumption and mitigate battery drain.

---

# 5. System Architecture

The application is structured upon a highly scalable **Layered Repository Pattern**, specifically optimized for production environments. 

> [System Architecture Diagram to be inserted manually here: Flow depicting UI -> Provider -> Repository -> SQLite / Firebase]

*   **Presentation Layer:** This layer is composed of Flutter Widgets (both Stateful and Stateless) acting in concert with Provider Listeners to render the interface efficiently.
*   **Domain Layer:** Responsible for centralized state management and core business logic, encapsulating crucial services such as `AuthService` and `SyncService`.
*   **Data Layer:** This layer establishes abstract Repositories that securely connect to and arbitrate between the Local persistence engine (Sqflite) and the Remote cloud infrastructure (Firebase).

---

# 6. Layer-by-Layer Implementation Details

### 6.1 UI Architecture & Navigation

*   **Navigation Strategy:** The application employs a persistent `BottomNavigationBar` paired with an `IndexedStack`. This sophisticated approach preserves the state of distinct operational screens during lateral navigation.
*   **Named Routes:** Standardized `MaterialPageRoute` configurations are utilized for invoking secondary interfaces, such as the "Add Activity" and "Health Log" screens.
*   **Route Guards:** Access to the application's core functionality is governed by authentication-based route gating. The central `main.dart` entry point actively monitors `AuthService.isLoggedIn` to reliably redirect unauthenticated users.

### 6.2 State Management & Business Logic

*   **Pattern:** The Provider package constitutes the primary state management solution.
*   **Separation of Concerns:** A strict architectural boundary is maintained wherein UI widgets are exclusively responsible for rendering. Consequently, all computational logic, external API invocations, and state mutations are securely isolated within dedicated `ChangeNotifier` classes.

### 6.3 Database & Data Layer (Production Grade)

> [ER Diagram to be inserted manually here: Depicting 5 core tables - Users, HealthLogs, Goals, Activities, Notifications - related via userId]

*   **SQLite Schema:** The local relational database enforces a rigorous schema comprising five interconnected tables: `Users`, `HealthLogs`, `Goals`, `Activities`, and `Notifications`.
*   **Repository Pattern:** Raw data access operations are systematically abstracted through formalized classes, exemplified by the `HealthLogRepository`.
*   **Sync Logic:** A sophisticated background synchronization engine intelligently merges localized SQLite modifications with Cloud Firestore. This crucial infrastructure enables seamless Multi-Device Support, allowing user data to be instantaneously retrieved and populated when authenticating on a new device.

### 6.4 API & Device Features

*   **Networking:** Secure, asynchronous communication with Firebase infrastructure is facilitated through the `firebase_core` and `cloud_firestore` libraries utilizing standard `async/await` paradigms.
*   **External API Integration:** The application dynamically consumes a production-grade REST API to populate the Health Tips module with contemporary wellness education.
*   **Hardware Sensor Fusion:** Real-time accelerometer data is captured and processed via the `Pedometer` API, enabling the automated quantification of physical movement.
*   **Multimedia Integration:** The `Image_Picker` API is integrated to directly interface with the device Camera and native photo library, streamlining user profile data management.
*   **Notifications:** Timely goal reminders and critical health alerts are dispatched natively utilizing the `flutter_local_notifications` framework.

---

# 7. Core Features & Optimizations

*   **Bilingual Engine:** The application features a custom internationalization (i18n) implementation, distinguished by a locale-aware font scaling solution designed explicitly to handle the typographic nuances of Sinhala scripts.
*   **Dynamic Theming:** A cohesive global theme system supports High-Contrast Dark and Light visual modes. User preferences are persistently stored within the database to ensure continuity across sessions.
*   **Interactive Charts:** The integration of multi-axis graphical components allows users to visually correlate diverse metrics, including BMI variations against historical physical activity.
*   **Predictive Deadlines:** The system employs algorithmic calculation to project estimated goal completion dates, analyzing the user's velocity over a trailing 30-day period.
*   **Matte-Glass Design:** The visual aesthetic is governed by a bespoke design system that utilizes targeted HSL color palettes and sophisticated backdrop filters to achieve a premium user experience.

---

# 8. Challenges & Solutions

*   **Conflict Resolution:** During the development lifecycle, substantial dependency conflicts were encountered during a major branch merge. This architectural impasse was systematically resolved by manually pinning and stabilizing the specific versions of the `intl` and `syncfusion` packages.
*   **Font Rendering:** The implementation of Sinhala script initially presented significant UI overflow anomalies. This was successfully mitigated by engineering and deploying a global font-scaling helper function (`_siSize`) to dynamically adjust typographic bounds.

---

# 9. Conclusion & Future Enhancements

The Uplift project successfully culminates in the delivery of a highly resilient, production-ready health monitoring platform. By seamlessly merging a sophisticated offline-first architecture with dynamic cloud synchronization, it addresses the core requirements of modern health informatics. Future developmental iterations are strategically planned to introduce AI-driven, personalized dietary advisories and establish direct data integration with external wearable hardware peripherals.

---

# 10. Individual Contribution Declaration

| Member Name | Key Features Implemented | Responsible Layer |
| :--- | :--- | :--- |
| **Member 1: MASV Karunathilak** | Health Log System, UI Architecture design, and Application Navigation Framework. | UI Architecture & Navigation: Layouts, responsiveness, and routing. |
| **Member 2: MMND Senivirathne** | Activity Tracking section and real-time step counter implementation. | API Integration & Device Features: Networking, async handling, and plugin integration. |
| **Member 3: LSR Vidanaarachchi** | Firebase Integration, Authentication (Login/Register), Profile Management, Goal System, Charting, Theming, and UI Design. | Database & Data Layer: SQLite schema design and repository pattern implementation. |
| **Member 4: BDD Devendra** | Localization Engine (English/Sinhala), Health Tips API Integration, and Goal Reminder/Notification section. | State Management & Business Logic: Provider implementation, validation, and logic separation. |

---

# 11. References

*   Flutter Documentation (flutter.dev)
*   Firebase Documentation (firebase.google.com)
*   External Packages: `provider`, `fl_chart`, `sqflite`, `syncfusion_flutter_gauges`, `intl`, `pedometer`.

---

# 12. Appendices

*   **GitHub Repository:** [Insert Link Here]
*   **Installation:** To initialize the project environment, execute `flutter pub get` followed by `flutter run`.
*   **Assets:** Reference the `assets/images` directory for primary UI mockups and systemic iconography.
