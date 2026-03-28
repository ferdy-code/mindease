# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get          # Install dependencies
flutter analyze          # Run linter (flutter_lints)
flutter test             # Run test suite
flutter test test/widget_test.dart  # Run a single test file
flutter run              # Run on connected device/emulator
flutter build apk        # Build Android APK
flutter build ios        # Build iOS app
```

## Architecture

**Stack**: Flutter + Riverpod (state) + GoRouter (navigation) + Dio (HTTP) + Hive/SharedPreferences (storage)

### State Management — Riverpod
- All providers live in `lib/providers/`
- `authProvider` is a `StateNotifierProvider<AuthNotifier, AuthState>` with states: `initial`, `loading`, `authenticated`, `unauthenticated`
- Auth state is persisted via SharedPreferences (tokens + user JSON)

### Navigation — GoRouter (`lib/app/app.dart`)
- Uses `StatefulShellRoute` with indexed branches for bottom nav persistence
- A `_RouterNotifier` bridges Riverpod's `authProvider` to GoRouter's `refreshListenable`, triggering auth-based redirects automatically
- Main shell routes: `/` (Home), `/journal`, `/chat`, `/zen`; modal route: `/mood`
- Auth routes: `/login`, `/register`

### HTTP — Dio (`lib/core/api_client.dart`)
- Singleton `ApiClient` with a Dio instance
- Auth interceptor automatically injects `Bearer` token from SharedPreferences
- On 401: attempts token refresh via `POST /auth/refresh`, retries original request; on failure, clears tokens

### Data Flow
- Models (`lib/models/`) are plain Dart classes with `fromJson`/`toJson`
- Screens call methods on `StateNotifier`s via `ref.read(provider.notifier)`
- Several screens (Journal, Chat, Zen) are currently UI shells with hardcoded mock data — backend integration is pending

## Key Details

- **API base URL**: `http://10.0.2.2:3000/api/v1` (Android emulator localhost) — defined in `lib/core/constants.dart`
- **UI language**: Indonesian throughout (labels, error messages, copy)
- **Theme**: Material 3, Poppins font, primary color `#6C5CE7` (purple) — defined in `lib/app/theme.dart`
- **Mood scale**: 5 levels (`veryBad` → `veryGood`) with emoji labels, defined in `lib/models/mood_entry.dart`
- `fl_chart` and `flutter_local_notifications` are included as dependencies but not yet wired up
