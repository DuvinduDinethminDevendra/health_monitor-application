# Health Monitor - UI Architecture & Design System

## Global Theme Concept: "Emerald Glass"
The application utilizes a **Light Glassmorphism** aesthetic designed to reduce eye strain while feeling premium and deeply integrated with modern mobile OS trends. 

### Core Palette
To ensure visual harmony, we use a soothing background juxtaposed with vibrant, health-focused accents.
- **Background Gradient Base**: Soft Warm White (`#FAFAF8`) blending into subtle variations.
- **Primary Accent (Vue/Emerald Green)**: `#10B981` (Used for primary actions, progress completion, active states).
- **Secondary Accent (Orange)**: `#F97316` (Used for warnings, secondary metrics like calories, call-to-action highlights).
- **Tertiary Accent (Sky Blue)**: `#0EA5E9` (Used for water/hydration goals, neutral stats).
- **Text Primary**: `#1F2937` (Dark Grey/Charcoal for maximum readability without harsh black contrast).
- **Text Secondary**: `#6B7280` (Muted Grey for subtitles and inactive states).

### Component Architecture

#### 1. GlassCards
The primary container for all UI elements (Forms, Stats, Lists).
- **Background**: `Colors.white.withOpacity(0.4)` to `0.6`.
- **Blur Effect**: `ImageFilter.blur(sigmaX: 12, sigmaY: 12)`.
- **Border**: `Border.all(color: Colors.white.withOpacity(0.5), width: 1.5)`.
- **Shadow**: Extremely subtle, large spread shadow (`Colors.black.withOpacity(0.03)`, `blurRadius: 20`).
- **Border Radius**: Generous rounding (`BorderRadius.circular(24)`).

#### 2. Typography
- Modern, clean sans-serif (default Flutter Roboto or similar).
- Headers are bold and clean (`FontWeight.w700`).
- Data numbers are prominently large (`FontWeight.w800`, `fontSize: 28+`).

#### 3. Navigation
- **Top Date Picker**: A horizontal week-view calendar residing at the top of the Dashboard. Features a sleek, slightly darker glass container for contrast against the warm background.
- **Bottom Navigation**: Floating, pill-shaped `BottomNavigationBar` hovering above the bottom edge, using a robust glass effect so the background scrolls underneath it.

#### 4. Interaction & Feedback
- Tap actions provide subtle scale/opacity changes.
- Form inputs feature soft internal shadows or subtle white borders.
- Floating Action Buttons (FABs) match the primary/secondary accent colors and use soft drop shadows to float above the UI.

## File Organization Requirements
- All glassmorphism utilities (wrappers, gradients) should reside in a centralized file (e.g., `lib/widgets/glass_card.dart`).
- Screen components should remain strictly UI-focused, delegating logic to existing repositories and providers.
- **ABSOLUTELY NO BACKEND LOGIC CHANGES**. The UI refactor strictly maps existing data structures into the new visual paradigm.
