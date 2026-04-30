# Health Monitor — Entity-Relationship Diagram

## ER Diagram

```mermaid
erDiagram
    USERS {
        TEXT id PK "Firebase UID"
        TEXT name
        TEXT email
        TEXT password
        TEXT created_at
        INTEGER age
        TEXT gender
        REAL height
        REAL weight
        TEXT profile_picture "Base64 encoded"
        TEXT interests "JSON array string"
        INTEGER sync_status "0 = unsynced"
    }

    GOALS {
        INTEGER id PK "AUTOINCREMENT"
        TEXT user_id FK "References users(id)"
        TEXT title
        TEXT category "e.g. Running, Diet, Water, General"
        REAL target_value
        REAL current_value
        TEXT unit
        TEXT deadline
        TEXT reminder_time "e.g. 08:00 AM"
        INTEGER is_completed "0 or 1"
        INTEGER sync_status "0 = unsynced"
    }

    ACTIVITIES {
        INTEGER id PK "AUTOINCREMENT"
        TEXT user_id FK "References users(id)"
        TEXT type "steps or workout"
        REAL value
        TEXT date
        INTEGER duration "minutes"
        INTEGER sync_status "0 = unsynced"
    }

    HEALTH_LOGS {
        INTEGER id PK "AUTOINCREMENT"
        TEXT user_id FK "References users(id)"
        REAL weight
        REAL height
        REAL bmi
        TEXT date
        TEXT tags "CSV string"
        TEXT notes
        TEXT unit "metric or imperial"
        REAL waist
        REAL hip
        REAL chest
        REAL body_fat
        INTEGER sync_status "0 = unsynced"
    }

    REMINDERS {
        INTEGER id PK
        TEXT title
        TEXT body
        TEXT times "JSON array of hour/minute maps"
        INTEGER is_enabled "0 or 1"
        TEXT alert_style "banner or alarm"
        TEXT repeat_days "7-char bitmask Mon-Sun"
        INTEGER vibration "0 or 1"
        TEXT sound_name "default, gentle, urgent, silent"
    }

    FAVORITE_TIPS {
        TEXT topic_id PK
        TEXT title
        TEXT description
        TEXT content
        TEXT url
        TEXT image_url
    }

    RECENT_TIPS {
        TEXT topic_id PK
        TEXT title
        TEXT description
        TEXT content
        TEXT url
        INTEGER visited_at
        TEXT image_url
    }

    USERS ||--o{ GOALS : "sets"
    USERS ||--o{ ACTIVITIES : "logs"
    USERS ||--o{ HEALTH_LOGS : "records"
```

---

## Relationship Summary

| Relationship | Type | FK Constraint | Description |
|---|---|---|---|
| **Users → Goals** | One-to-Many | `goals.user_id → users.id` (ON DELETE CASCADE) | A user sets zero or more health goals |
| **Users → Activities** | One-to-Many | `activities.user_id → users.id` (ON DELETE CASCADE) | A user logs zero or more activities |
| **Users → Health Logs** | One-to-Many | `health_logs.user_id → users.id` (ON DELETE CASCADE) | A user records zero or more health logs |
| **Reminders** | Standalone | — | Not user-scoped; device-local notification schedules |
| **Favorite Tips** | Standalone | — | Locally cached bookmarked health tips |
| **Recent Tips** | Standalone | — | Locally cached recently viewed tips |

---

## Entity Details

### 🧑 Users
The central entity. Stores Firebase UID as primary key, profile data (age, gender, height, weight, profile picture), and a JSON-encoded list of interest topics used for personalising Health Tips.

### 🎯 Goals
Tracks health goals per user with category-based tracking (Running, Diet, Water, etc.), target/current progress values, deadlines, and optional reminder times.

### 🏃 Activities
Records user activity entries — either `steps` or `workout` — with a numeric value, date, and duration in minutes.

### 📋 Health Logs
Body measurement snapshots — weight, height, auto-calculated BMI, optional body measurements (waist, hip, chest, body fat), and tagging/notes. Supports metric & imperial units.

### ⏰ Reminders
Device-local notification configuration. Stores a JSON array of `{hour, minute}` maps to support multiple daily reminder times, along with alert style (banner vs. persistent alarm), day-of-week repeat bitmask, vibration toggle, and sound selection.

### ⭐ Favorite Tips / 🕐 Recent Tips
Offline caches for health tip articles fetched from an external API. Favorite Tips are user-bookmarked; Recent Tips track visit history via `visited_at` timestamp.
