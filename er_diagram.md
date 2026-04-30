# Health Monitor Application — Database ER Diagram

## ER Diagram

```mermaid
erDiagram
    users {
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
        INTEGER is_dark_mode "0 or 1"
        TEXT interests "JSON array string"
        INTEGER sync_status "0 or 1"
    }

    goals {
        INTEGER id PK "AUTOINCREMENT"
        TEXT user_id FK "→ users.id"
        TEXT title
        TEXT category "Running, Diet, Water, General"
        REAL target_value
        REAL current_value
        TEXT unit
        TEXT deadline
        TEXT reminder_time "e.g. 08:00 AM"
        INTEGER is_completed "0 or 1"
        INTEGER sync_status "0 or 1"
    }

    activities {
        INTEGER id PK "AUTOINCREMENT"
        TEXT user_id FK "→ users.id"
        TEXT type "steps or workout"
        REAL value
        TEXT date
        INTEGER duration "in minutes"
        INTEGER sync_status "0 or 1"
    }

    health_logs {
        INTEGER id PK "AUTOINCREMENT"
        TEXT user_id FK "→ users.id"
        REAL weight
        REAL height
        REAL bmi "auto-calculated"
        TEXT date
        TEXT tags "comma-separated"
        TEXT notes
        TEXT unit "metric or imperial"
        REAL waist
        REAL hip
        REAL chest
        REAL body_fat
        INTEGER sync_status "0 or 1"
    }

    step_records {
        INTEGER id PK "AUTOINCREMENT"
        TEXT user_id FK "→ users.id"
        TEXT date
        INTEGER step_count
        INTEGER goal "default 10000"
    }

    workout_records {
        INTEGER id PK "AUTOINCREMENT"
        TEXT user_id FK "→ users.id"
        TEXT workout_type
        INTEGER duration_mins
        INTEGER calories_burned
        TEXT logged_at
        TEXT notes
    }

    reminders {
        INTEGER id PK
        TEXT title
        TEXT body
        TEXT times "JSON array"
        INTEGER is_enabled "0 or 1"
        TEXT alert_style "banner or alarm"
        TEXT repeat_days "7-char bitmask"
        INTEGER vibration "0 or 1"
        TEXT sound_name
    }

    favorite_tips {
        TEXT topic_id PK
        TEXT title
        TEXT description
        TEXT content
        TEXT url
        TEXT image_url
    }

    recent_tips {
        TEXT topic_id PK
        TEXT title
        TEXT description
        TEXT content
        TEXT url
        INTEGER visited_at
        TEXT image_url
    }

    users ||--o{ goals : "has many"
    users ||--o{ activities : "logs many"
    users ||--o{ health_logs : "records many"
    users ||--o{ step_records : "tracks many"
    users ||--o{ workout_records : "logs many"
```

## Relationship Summary

| Relationship | Type | FK Constraint |
|---|---|---|
| `users` → `goals` | One-to-Many | `goals.user_id` → `users.id` (ON DELETE CASCADE) |
| `users` → `activities` | One-to-Many | `activities.user_id` → `users.id` (ON DELETE CASCADE) |
| `users` → `health_logs` | One-to-Many | `health_logs.user_id` → `users.id` (ON DELETE CASCADE) |
| `users` → `step_records` | One-to-Many | `step_records.user_id` → `users.id` (ON DELETE CASCADE) |
| `users` → `workout_records` | One-to-Many | `workout_records.user_id` → `users.id` (ON DELETE CASCADE) |
| `reminders` | Standalone | No FK — device-local only |
| `favorite_tips` | Standalone | No FK — device-local only |
| `recent_tips` | Standalone | No FK — device-local only |

## Sync Architecture

- Tables with `sync_status`: `users`, `goals`, `activities`, `health_logs` → synced to **Firebase Firestore**
- Firestore path: `users/{userId}/goals/{goalId}`, `users/{userId}/activities/{activityId}`, `users/{userId}/health_logs/{logId}`
- `reminders`, `favorite_tips`, `recent_tips`, `step_records`, `workout_records` → **local-only (SQLite)**
