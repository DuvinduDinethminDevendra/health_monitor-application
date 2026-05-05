# Uplift Health UI Refinement Task List

- [x] **Phase 1: Activity Screen Refactoring**
  - [x] Standardize Header with SyncStatusBadge and AppTheme colors.
  - [x] Refactor `ActivityStatCard`, `SmartInsightCard`, `GoalProgressTile`, and `RecentActivityTile` to `MatteCard`.
  - [x] Standardize w900/w700 typography and AppTheme tokens.

- [x] **Phase 2: Activity History Screen**
  - [x] Wrap Summary Tiles and Daily Logs in `MatteCard`.
  - [x] Convert legacy text colors to `AppTheme` tokens.

- [x] **Phase 3: Health Log & Goal Progress**
  - [x] Refactor `HealthLogScreen` list items to `MatteCard`.
  - [x] Replace `LiquidHealthIndicator` with standard styled MatteCard text blocks for measurements.
  - [x] Apply AppTheme.sapphire and w900 alignments to floating metrics.
  - [x] Resolve any compile errors (e.g., MatteCard alignment parameters).

- [ ] **Phase 4: Navigation & Profile Review**
  - [ ] Final visual QA on navigation items and profile screen to ensure full Pallet 2 Matte consistency.
  - [ ] Cross-platform verification for dark/light mode rendering.
