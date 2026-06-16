---
description: shredMembers coding guidelines and conventions
---

## Language

- **All UI strings must be in English.** Localisation / translations are deferred to a later phase.
- Do not introduce German (or any other language) strings in source code, even for temporary labels.

## Tech Stack

- Flutter 3.44.1 · Dart
- State management: Riverpod 2 (`NotifierProvider`, `AsyncNotifierProvider`)
- Navigation: GoRouter 13
- Backend: Supabase (Auth + Postgres)
- Charts: fl_chart
- Fonts/Icons: Google Fonts (Inter), Material Icons

## Project Structure

```
lib/src/
  models/       – immutable data classes with copyWith + Equatable
  services/     – repository classes (AuthRepository, WorkoutRepository)
  providers/    – Riverpod notifiers and providers
  routing/      – GoRouter setup (app_router.dart)
  screens/      – one folder per feature
  widgets/      – shared UI components
  theme/        – AppColors, AppSpacing, AppRadius, AppTheme
```

## Conventions

- Prefer minimal, focused edits. Do not rewrite working code unnecessarily.
- Keep `supabase_config.dart` out of version control (it is in `.gitignore`).
- No `print()` statements in production code – use them only for temporary debugging and remove afterwards.
- All Supabase responses must be explicitly cast: `e as Map<String, dynamic>`.
- Hot reload (`r`) is sufficient for UI changes; full restart required after changing `Supabase.initialize()` or provider structure.

## Running the App

```zsh
# Web (dev)
/opt/homebrew/bin/flutter run -d web-server --web-port 8080

# iPhone Simulator
/opt/homebrew/bin/flutter run -d 361AB118-7CE1-46D2-97C8-4D18F2137ACE
```

## Pending Features (roadmap)

- [ ] Rest timer between sets
- [ ] Personal Records screen
- [ ] Push notifications
- [ ] Localisation / translations (German + others)
