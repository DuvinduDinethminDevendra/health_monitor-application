# ICT4153 Mobile Application Development - Group Project (2026)
**Dept of ICT, FOT, UOR**

This group project evaluates your ability to design, architect, and implement a production-level Flutter mobile application using advanced concepts covered in this module.

## Common Advanced Technical Requirements (MANDATORY FOR ALL PROJECTS)

Each group must implement:

### 1. Advanced Navigation
* Named routes
* Nested navigation (e.g., BottomNavigationBar with independent stacks)
* Route guards or authentication-based routing

### 2. State Management (Advanced)
* Provider / Riverpod / Bloc (NOT only setState)
* Separation of UI and business logic

### 3. Clean Architecture Structure
* Presentation Layer
* Business Logic Layer
* Data Layer
* Repository pattern

### 4. Local & Remote Data Integration
* SQLite (complex relational structure - at least 2 related tables)
* REST API consumption
* Proper async/await handling
* Error & exception handling

### 5. Authentication Simulation
* Login/Registration system (mock or Firebase)

### 6. Device Feature Integration (At least one)
* Camera
* QR
* Location
* Push notifications
* Background tasks

### 7. Performance & UX Optimization
* Lazy loading/pagination
* Loading indicators
* Form validation
* Null safety handling

## Equal Role Distribution (Same for All Projects)

| Member | Responsibility | Assessed On |
| :--- | :--- | :--- |
| Member 1 | UI Architecture & Navigation | Layouts, responsiveness, routing |
| Member 2 | State Management & Business Logic | Bloc/Provider, validation, logic separation |
| Member 3 | Database & Data Layer | SQLite schema, repository pattern |
| Member 4 | API Integration & Device Features | Networking, async handling, plugin integration |

*Each member must defend their layer during viva.*

---

## PROJECT 1: Smart Campus Operations System

### Practical Context
A university administration wants to modernize academic and campus services through a centralized mobile application. The system should support students and staff with real-time information and operational tools.

### Your Task
Design and develop a Flutter application that includes:

**Functional Requirements:**
* Role-based authentication (Student / Staff)
* Timetable management system
* Event registration with QR confirmation
* Campus map integrated with location service
* Real-time announcements fetched from REST API
* Push notifications for urgent university updates

**Technical Expectations:**
* Relational SQLite schema:
  * Users
  * Events
  * Registrations
* API integration for announcements
* QR code generation and scanning
* Location service plugin
* Clean navigation structure (nested navigation required)

*You simulate building a real digital transformation solution for a university.*

---

## PROJECT 2: Integrated Digital Health Monitoring Platform

### Practical Context
A health-tech startup aims to build a digital wellness tracking application that allows users to monitor their health and receive expert health tips remotely.

### Your Task
Develop a Flutter application that supports:

**Functional Requirements:**
* Secure user authentication
* Activity tracking (steps, workouts)
* Health data logging (weight, BMI)
* Goal management system
* Health tips fetched from external API
* Progress charts
* Scheduled health reminders

**Technical Expectations:**
* Relational database:
  * User
  * Activities
  * Goals
* Repository pattern implementation
* Background notifications
* Form validation and error handling
* Chart integration for analytics

*You simulate developing a commercial digital health monitoring product.*

---

## PROJECT 3: Intelligent Personal Finance & Budgeting System

### Practical Context
A fintech startup wants a budgeting application that analyzes spending habits and provides financial insights.

### Your Task
Build a smart finance management Flutter application with:

**Functional Requirements:**
* Secure login system
* Add/edit/delete income and expense transactions
* Category-based classification
* Monthly financial analytics dashboard
* Currency conversion using a mock API
* CSV export of financial summary

**Technical Expectations:**
* Relational database:
  * Users
  * Transactions
  * Categories
* Complex filtering queries
* Pagination for transaction list
* Chart-based visualization
* Robust async error handling

*You simulate developing a financial analytics mobile application.*

---

## PROJECT 4: Smart Event & Ticket Management Platform

### Practical Context
An event management company wants a digital mobile platform for booking and validating event tickets.

### Your Task
Develop a Flutter-based event management system that includes:

**Functional Requirements:**
* Multi-role authentication (Organizer / User)
* Event creation and seat allocation
* Ticket booking workflow
* QR-based ticket validation
* API integration for featured events
* Notification reminders before events

**Technical Expectations:**
* Relational seat allocation database
* QR scanning plugin
* Nested navigation structure
* Multi-role UI handling
* Notification scheduling

*You simulate building a scalable event ticketing platform.*

---

## PROJECT 5: Adaptive Learning & Assessment Platform

### Practical Context
An EdTech startup wants a mobile application that adapts quizzes based on user performance to enhance personalized learning.

### Your Task
Develop a Flutter learning system with:

**Functional Requirements:**
* User authentication
* Quiz engine with multiple difficulty levels
* Timed quizzes
* Score tracking and history
* Performance analytics dashboard
* Question bank fetched from API

**Technical Expectations:**
* Relational quiz database:
  * Users
  * Questions
  * Results
* Timer-based state control
* Async question loading
* Chart-based progress visualization
* Proper state management for quiz flow

*You simulate building a modern adaptive mobile learning application.*

---

## Deliverables

Each group must submit:
1. Source code (ZIP or GitHub link)
2. Project report (PDF)
3. ER diagram for database
4. Architecture diagram
5. APK file
6. Individual contribution declaration

**Submission Deadline:** 01st May 2026
