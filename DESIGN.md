# Health Monitor - UI Architecture & Design System

## Global Theme Concept: "Matte Alabaster & Solid Sapphire" (Updated Pallet 2)
The application utilizes a premium **Dual-Theme** architecture that prioritizes high-contrast and vibrant visuals over faded aesthetics.

- **Light Mode**: A clean, "Matte Alabaster" aesthetic using solid surfaces and high-contrast typography. No faded transparency on primary cards.
- **Dark Mode**: A sophisticated "Solid Sapphire" aesthetic utilizing deep, vibrant colors and high-contrast glassmorphism that maintains text legibility.

## Core Palette
All UI elements must strictly adhere to these constants defined in `AppTheme`.

- **Alabaster (Background Light)**: `#F5F5F5` - Primary background for light mode.
- **Sapphire (Background Dark)**: `#0F172A` - Deep, premium blue for dark mode base.
- **Scooter (Primary Accent)**: `#2F9D94` - Used for primary actions and active navigation.
- **Blue Lagoon (Secondary Accent)**: `#025F67` - Used for primary buttons and success states.
- **Warm Orange**: `#F97316` - Used for warnings and specific health metrics.
- **Sky Blue**: `#0EA5E9` - Used for secondary metrics.

## Theme Implementation Rules

### 1. No Faded Colors
- **Prohibited**: Low-alpha transparencies (e.g., `alpha: 0.1`) for text or main components.
- **Required**: High contrast text (`White` on Dark, `Sapphire` on Light).
- **Vibrancy**: Use color saturation to define hierarchy rather than opacity.

### 2. Glassmorphism (Dark Mode)
The `GlassCard` widget remains the primary container but with higher vibrancy.
- **Background**: Slate/Sapphire mix with `0.8+` opacity.
- **Icons & Text**: Must be `White` or `White70` for maximum legibility.

### 3. Navigation & Branding
- **Bottom Navigation**: Solid background in both themes to prevent "faded" footer appearance.
- **Icons**: Use pallet colors only; avoid grey/muted versions in primary flows.

## Component Architecture
- **`AppTheme`**: Source of truth for theme definitions.
- **`GlassCard`**: Reusable high-vibrancy container.
- **`HorizontalWeekCalendar`**: Solid header date picker.

## Maintenance Protocol
- Never use generic `Colors.*` unless it's `white` or `transparent`.
- Always check contrast ratios for text visibility.
- Ensure all sub-pages (Profile, Activities, Goals) inherit the same high-vibrancy style.
