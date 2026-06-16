# shredMembers 🏋️

A modern, minimalist fitness app for workout planning, tracking and progress monitoring.  
Built with **Flutter 3.44+** · **Riverpod** · **GoRouter** · **fl_chart**

---

## Tech Stack

| Layer | Choice | Reason |
|---|---|---|
| Frontend | Flutter 3.44 | Single codebase for Android, iOS, Web, macOS |
| State | Riverpod 2 | Null-safe, no BuildContext dependency, testable |
| Routing | GoRouter 13 | Declarative, deep-link ready, shell routes |
| Backend (prep) | Supabase-ready service layer | Simple REST + Auth, easy to wire up |
| Charts | fl_chart | Lightweight, customizable |

---

## Project Structure

```
lib/
└── src/
    ├── theme/          # AppColors, AppTheme, AppSpacing
    ├── models/         # AppUser, WorkoutPlan, Exercise, WorkoutSession
    ├── services/       # MockData (swap for Supabase/API service)
    ├── providers/      # Riverpod providers (auth, workout, session)
    ├── routing/        # GoRouter config + route constants
    ├── screens/
    │   ├── onboarding/
    │   ├── auth/       # Login + Signup
    │   ├── home/       # Dashboard
    │   ├── plans/      # Plan list
    │   ├── workout/    # Detail + Tracking flow
    │   ├── progress/   # Stats + history
    │   └── profile/    # Settings
    └── widgets/
        ├── common/     # AppButton, AppCard, StatChip, SectionHeader, GradientText
        └── layout/     # MainScaffold (responsive BottomNav / SideNav)
```

---

## Setup

```bash
# 1. Install Flutter (if not done)
brew install --cask flutter

# 2. Install dependencies
flutter pub get

# 3. Run
flutter run -d macos          # macOS Desktop (requires Xcode)
flutter run -d web-server --web-port 8080   # Web (any browser)
flutter run -d chrome         # Web in Chrome
flutter run                   # iOS Simulator / Android Emulator
```

---

## MVP Screens

- **Onboarding** – 3-page swipe intro
- **Login / Signup** – form validation, mock auth
- **Home Dashboard** – greeting, stats, today's workout card, recent sessions
- **Plans** – grid/list of workout plans, activate plan
- **Workout Detail** – tabbed day view, exercise & set breakdown
- **Workout Tracking** – live set checking, progress bar, timer, completion sheet
- **Progress** – volume bar chart (fl_chart), session history
- **Profile** – goal selector, weekly target, sign out

---

## Next Steps

- [ ] Wire up Supabase auth in `AuthNotifier`
- [ ] Replace `MockData` with Supabase/REST calls in service layer
- [ ] Add rest timer between sets
- [ ] Personal records tracking
- [ ] Push notifications for workout reminders
- [ ] iOS / Android release builds

Fitness App

## Start App

flutter run -d "iPhone 17"	
flutter run -d macos
flutter run -d chrome --web-port=8080	
