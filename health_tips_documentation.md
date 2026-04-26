# Health Tips Module Documentation

This document outlines the architecture, dependencies, external services, database schema, and build configuration used to power the Health Tips functionality in the Health Monitor application.

---

## Overview

The Health Tips feature provides users with dynamic, randomized, and searchable health advice. It is designed to be highly performant, fully resilient to offline scenarios, and visually premium with shimmer loading skeletons, rich HTML rendering, and a persistent Favorites system backed by SQLite.

---

## External API

**MyHealthfinder API (health.gov)**
- **Endpoint**: `https://health.gov/myhealthfinder/api/v3/topicsearch.json`
- **Search**: `?keyword=<term>` (e.g., `?keyword=fitness`)
- **Why we use it**: It is a free, highly reliable, U.S. government-backed database containing hundreds of medically verified health and wellness articles. It supports keyword searching natively and provides structured JSON data including unique `Id` fields per topic.
- **Key JSON structure**: `Result → Resources → Resource[]` — each resource contains `Id`, `Title`, `Categories`, `Sections`, and `AccessibleVersion`.

---

## Packages Used

### Networking & Caching Layer

| Package | Why |
|---|---|
| `dio` | Powerful HTTP client for Dart. Replaces `http` for native JSON parsing, robust error handling, and interceptor support. |
| `dio_cache_interceptor` | Intercepts HTTP requests and caches responses based on server `Cache-Control` / ETag headers. Saves bandwidth and provides lightning-fast load times. |
| `dio_cache_interceptor_hive_store` | Provides a local disk-storage backend (Hive NoSQL) for the cache interceptor. Cached data survives app restarts. |
| `path_provider` | Locates the device's private App Documents directory (sandboxed on iOS/Android). Gives the Hive store a secure save location without requiring user file-access permissions. |

### UI & Rendering Layer

| Package | Why |
|---|---|
| `provider` | Industry-standard state management for Flutter. Decouples business logic from UI. |
| `shimmer` | Creates premium pulsing grey skeleton animations during loading, replacing basic `CircularProgressIndicator`. |
| `flutter_widget_from_html` | Parses and renders raw HTML (`<ul>`, `<li>`, `<b>`, etc.) from the API response. Replaces plain `Text` widgets to properly display bullet points, bold text, and structured content in the Bottom Sheet. |
| `cached_network_image` | Efficiently downloads and caches topic images from the API. Provides premium placeholders and error handling. |
| `share_plus` | Implements native social sharing functionality for tips. |
| `showcaseview` | Powers the first-time user tutorial by highlighting the first tip card. |

### Data Persistence

| Package | Why |
|---|---|
| `sqflite` | SQLite database for Flutter. Used to persist Favorite tips and Recently Viewed tips locally on the device. |

### Build Configuration

| Item | Why |
|---|---|
| `dependency_overrides: vector_math: 2.3.0` (in `pubspec.yaml`) | `flutter_widget_from_html` pulled `vector_math` down to `2.1.4`, but `fl_chart` requires `2.3.0+` for `translateByDouble`. This override pins the correct version. |
| `kotlin.incremental=false` (in `gradle.properties`) | Disables Kotlin incremental compilation to fix a cross-drive crash on Windows when the project (`D:\`) and Pub Cache (`C:\`) are on different drives. |
| `org.jetbrains.kotlin.android: 2.1.21` (in `settings.gradle.kts`) | Upgraded from `1.8.22`. The new packages pull in `kotlin-stdlib 2.2.0` which requires a Kotlin compiler that can read metadata version `2.2.0`. |

---

## Database Schema (SQLite v4)

### `favorite_tips`
Stores tips the user has explicitly saved by tapping the Heart icon.

| Column | Type | Notes |
|---|---|---|
| `topic_id` | `TEXT PRIMARY KEY` | The official API `Id` — avoids the UNIQUE title collision trap. |
| `title` | `TEXT NOT NULL` | |
| `description` | `TEXT NOT NULL` | |
| `content` | `TEXT NOT NULL` | Raw HTML content. |
| `url` | `TEXT NOT NULL` | Link to the accessible web version. |
| `image_url` | `TEXT` | URL to the topic image. |

### `recent_tips`
Stores the 20 most recently viewed tips (auto-pruned).

| Column | Type | Notes |
|---|---|---|
| `topic_id` | `TEXT PRIMARY KEY` | |
| `title` | `TEXT NOT NULL` | |
| `description` | `TEXT NOT NULL` | |
| `content` | `TEXT NOT NULL` | |
| `url` | `TEXT NOT NULL` | |
| `visited_at` | `INTEGER NOT NULL` | Epoch milliseconds. Used for ordering and pruning. |
| `image_url` | `TEXT` | URL to the topic image. |

---

## Files & Architecture

We follow a strict separation of concerns: **Data Layer → Logic Layer → Presentation Layer**.

---

### 1. Data Layer

#### `lib/services/health_tips_service.dart`
**Role**: All external I/O (network + database).

**Responsibilities**:
- Configures the `Dio` client with `HiveCacheStore` and an **Instant-First** (`forceCache`) policy.
- Makes HTTP GET requests to `health.gov` and maps JSON to `HealthTip` objects.
- Handles image URL processing (prepending `https://health.gov` to relative paths).
- Provides SQLite CRUD methods:
  - `saveFavoriteTip(tip)` / `removeFavoriteTip(id)` / `getFavoriteTips()`
  - `saveRecentTip(tip)` / `getRecentTips()` (auto-prunes to 20 entries)
- Contains the `HealthTip` model class with fields: `id`, `title`, `description`, `content`, `url`, `imageUrl`. Includes static helper for URL normalization.

#### `lib/database/database_helper.dart`
**Role**: SQLite lifecycle management.

**Responsibilities**:
- Singleton pattern for database access.
- Manages schema migrations (`_onUpgrade`). Currently at **version 4**.
- Version 4: Added `image_url` column to `favorite_tips` and `recent_tips`.
- Creates all tables: `users`, `activities`, `goals`, `health_logs`, `reminders`, `favorite_tips`, `recent_tips`.

---

### 2. Logic Layer

#### `lib/providers/health_tips_provider.dart`
**Role**: Business logic and state management.

**Responsibilities**:
- Manages UI state via `HealthTipsState` enum: `initial`, `loading`, `loaded`, `error`, `empty`.
- Tracks the active tag chip (`_selectedTag`) and favorite IDs (`_favoriteTipIds`).
- Resolves the **Tags vs. Search Bar conflict**:
  - Tapping a tag → clears the search bar.
  - Typing in the search bar → deselects the active tag.
- Handles special tag logic:
  - `Trending` → passes empty keyword to API (returns random 20 tips).
  - `Favorites` → reads from SQLite, skips the API entirely.
  - `Recent` → reads from SQLite, ordered by `visited_at DESC`.
  - Any other tag (e.g., `Fitness`) → passes the tag name as a keyword to the API.
- Provides `toggleFavorite(tip)` and `isFavorite(id)` for the UI.
- Implements `refreshCurrentList()` with `forceRefresh` capability to bypass cache on user demand.
- Tracks `_currentSearchQuery` to ensure refreshes work correctly during search modes.

---

### 3. Presentation Layer

#### `lib/screens/health_tips_screen.dart`
**Role**: Visual UI.

**Responsibilities**:
- **Search Bar**: `TextField` with a 500ms debouncer to prevent excessive API calls.
- **Tag Chips**: Horizontal scrollable `ChoiceChip` list below the search bar.
  - Tags: `Favorites`, `Recent`, `Trending`, `Fitness`, `Nutrition`, `Sleep`, `Mental Health`.
- **Shimmer Skeleton**: Pulsing grey placeholders matching card layout during loading.
- **Tip Cards**: `ListView.builder` with Material Cards showing title, category, and a color-coded icon.
- **Bottom Sheet** (`showModalBottomSheet` → `DraggableScrollableSheet`):
  - Category badge, title, and `HtmlWidget` for rich content rendering (line height 1.6, 24px padding).
  - **Sticky Action Bar** at the bottom with:
    - ❤️ Heart icon — toggles favorite state.
    - 📤 Share icon — triggers native share sheet via `share_plus`.
  - Opening the sheet automatically saves the tip to the `recent_tips` table.
- **Tutorial Integration**:
  - `ShowCaseWidget` wraps the entire screen.
  - Automatically triggers `startShowCase` on the first item (`_cardKey`) once the state transitions to `loaded`.
- **Media Performance**:
  - Uses `CachedNetworkImage` with 12.0 border radius.
  - Custom gradient placeholders and medical-themed error fallbacks for resilient UI.

---

## Data Flow Diagram

```
User taps "Fitness" chip
        │
        ▼
HealthTipsScreen ──► HealthTipsProvider.fetchTipsByTag("Fitness")
                            │
                            ▼
                     HealthTipsService.fetchHealthTips(keyword: "Fitness")
                            │
                            ▼
                     Dio GET health.gov/...?keyword=Fitness
                            │
                     ┌──────┴──────────────────┐
                     │ Cache Policy:           │
                     │  forceCache (Disk First)│
                     │  refresh (Pull down)    │
                     └──────┬──────────────────┘
                            │
                            ▼
                     List<HealthTip> returned
                            │
                            ▼
                     Provider sets state → loaded
                            │
                     ┌──────┴──────────────────┐
                     │ Tutorial Hook:          │
                     │  Is index 0? Showcase!  │
                     └──────┬──────────────────┘
                            │
                            ▼
                     Consumer rebuilds UI with tip cards
```

---

## Known Considerations

- **Offline**: If the network fails, `dio_cache_interceptor` serves cached responses (up to 7 days old) automatically. If no cache exists, the error state is shown with a "Load Offline Tips" fallback button.
- **Database Migrations**: When upgrading to v4, `_onUpgrade` handles adding the `image_url` columns. Users must fully restart the app.
- **Caching Strategy**: We use an **Instant-First** model. The UI loads from disk immediately. Fresh data is only fetched from the internet when the user explicitly "Pulls to Refresh."
- **Tutorial Logic**: The showcase tutorial is triggered every time the list is loaded to ensure users see the "Read & Save" functionality. To prevent annoyance in production, a `SharedPreferences` flag should be implemented to only show it once.
- **Cross-Drive Windows Bug**: If the project and Pub Cache are on different drive letters, `kotlin.incremental=false` must be set in `gradle.properties`.
