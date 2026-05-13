# [APP NAME] — Claude Project Memory

<!-- Instruction: Drop this file into your Flutter project root as CLAUDE.md. Claude Code reads it automatically at the start of every session. Keep it current — outdated context causes wrong decisions. This file is your project's single source of truth for AI context. -->

## Project Overview

**App name:** [PLACEHOLDER — e.g., Volta]
**Description:** [PLACEHOLDER — 2-3 sentences. What does the app do, who is it for, what problem does it solve?]
**Status:** [PLACEHOLDER — e.g., Active development / MVP / Maintenance]
**Repository:** [PLACEHOLDER — e.g., github.com/yourorg/volta]

---

## Tech Stack

| Dimension | Choice | Version |
|-----------|--------|---------|
| Flutter | [PLACEHOLDER] | [PLACEHOLDER — e.g., 3.22.x] |
| Dart | [PLACEHOLDER] | [PLACEHOLDER — e.g., 3.4.x] |
| State management | [PLACEHOLDER — e.g., Riverpod] | [PLACEHOLDER — e.g., 2.5.x] |
| Router | [PLACEHOLDER — e.g., GoRouter] | [PLACEHOLDER — e.g., 13.x] |
| DI | [PLACEHOLDER — e.g., Riverpod providers / get_it] | [PLACEHOLDER] |
| HTTP client | [PLACEHOLDER — e.g., Dio] | [PLACEHOLDER] |
| Local storage | [PLACEHOLDER — e.g., Hive / Isar / SQLite] | [PLACEHOLDER] |
| Secure storage | [PLACEHOLDER — e.g., flutter_secure_storage] | [PLACEHOLDER] |
| Backend | [PLACEHOLDER — e.g., Firebase / Supabase / Custom API] | [PLACEHOLDER] |
| Analytics | [PLACEHOLDER — e.g., Firebase Analytics] | [PLACEHOLDER] |
| Crash reporting | [PLACEHOLDER — e.g., Firebase Crashlytics] | [PLACEHOLDER] |

---

## Architecture Pattern

<!-- INSTRUCTION: This section shows an EXAMPLE architecture (Riverpod + Feature-First Clean). 
Replace ALL rules and examples with your project's actual pattern. 
If you use BLoC, replace Riverpod rules with BLoC equivalents.
If you use a simple layered arch, remove the domain/use-case rules entirely.
Do NOT leave this section unchanged — it will give Claude incorrect rules for your project. -->

**Pattern:** Feature-first Clean Architecture

```
Presentation  →  Domain  →  Data
   Widgets        Use cases    Repositories (impl)
   Providers      Entities     Data sources
   Screens        Repo interfaces
```

**Non-negotiable rules:**
- Domain layer has zero Flutter or platform imports — pure Dart only
- Business logic lives in use cases — never in widgets, never in providers
- Providers/Notifiers only coordinate between use cases and UI — no business logic
- Repositories are interfaces in domain, implemented in data
- No raw exceptions cross layer boundaries — repositories return `Either<Failure, T>`

---

## Folder Structure

```
lib/
├── main.dart                    # Entry: DI setup, ProviderScope, app widget, router
├── core/
│   ├── config/                  # AppConfig (dart-define values), feature flags
│   ├── di/                      # Shared providers, external dependency setup
│   ├── error/                   # Failure sealed class hierarchy
│   ├── extensions/              # Dart/Flutter extension methods
│   ├── navigation/              # GoRouter config, route constants, guards
│   ├── theme/                   # AppTheme, color tokens, text styles, spacing
│   └── utils/                   # Pure utility functions (no Flutter imports)
├── features/
│   └── [feature]/
│       ├── data/
│       │   ├── datasources/     # Remote (API) and local (cache) data sources
│       │   ├── models/          # JSON ↔ Dart models (@JsonSerializable)
│       │   └── repositories/    # Repository implementations
│       ├── domain/
│       │   ├── entities/        # Pure Dart business objects (@freezed)
│       │   ├── repositories/    # Abstract repository interfaces
│       │   └── usecases/        # Single-responsibility use case classes
│       └── presentation/
│           ├── providers/       # @riverpod Notifier/AsyncNotifier classes
│           ├── screens/         # Full-screen route widgets
│           └── widgets/         # Feature-scoped widgets
└── shared/
    ├── widgets/                 # App-wide reusable UI components
    └── models/                  # Shared data models used across features
```

---

## Code Style Rules

<!-- Instruction: Rules specific to this project — things that aren't caught by the linter but matter for consistency. -->

- Max file length: 300 lines. If a file is approaching this, split it before adding more.
- Max widget build method: 80 lines. Extract sub-widgets with descriptive names.
- No `var` for anything non-trivial — explicit types in all non-local variables.
- No `dynamic` anywhere except third-party JSON deserialization.
- All `Future`-returning functions must have explicit return types.
- `const` constructors everywhere possible.
- `StatelessWidget` by default. `StatefulWidget` only when local ephemeral UI state is needed (animation controllers, focus nodes). State management via Riverpod for everything else.
- No `setState` for business logic. No `setState` for anything that survives navigation.
- No `BuildContext` passed to use cases or below.
- `[PLACEHOLDER — add project-specific rules here]`

---

## Naming Conventions

| Thing | Convention | Example |
|-------|-----------|---------|
| Screens | `PascalCase` + `Screen` suffix | `SessionListScreen` |
| Widgets | `PascalCase` | `SessionListItem`, `LoadingOverlay` |
| Providers | `camelCase` + `Provider` or use generated name | `sessionListProvider` |
| Notifiers | `PascalCase` + `Notifier` suffix | `SessionFormNotifier` |
| Use cases | `PascalCase` + `UseCase` suffix | `CreateSessionUseCase` |
| Entities | `PascalCase`, no suffix | `Session`, `UserProfile` |
| Models | `PascalCase` + `Model` suffix | `SessionModel`, `UserModel` |
| Repository interfaces | `PascalCase` + `Repository` | `SessionRepository` |
| Repository impls | `PascalCase` + `RepositoryImpl` | `SessionRepositoryImpl` |
| Files | `snake_case` | `session_list_screen.dart` |
| Routes | `snake_case` string constants | `AppRoutes.sessionDetail = '/session/:id'` |
| Test files | Mirror source + `_test.dart` | `session_list_screen_test.dart` |

---

## State Management Patterns

<!-- Instruction: Show the exact pattern to follow when adding new state. Consistency matters more than the pattern itself. -->

**Adding a new async data provider:**

```dart
// features/sessions/presentation/providers/session_list_notifier.dart

@riverpod
class SessionListNotifier extends _$SessionListNotifier {
  @override
  Future<List<Session>> build() {
    return ref.watch(getSessionsUseCaseProvider).call();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
```

**Watching state in a widget:**

```dart
class SessionListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionListNotifierProvider);

    return sessionsAsync.when(
      data: (sessions) => SessionList(sessions: sessions),
      loading: () => const SessionListSkeleton(),
      error: (e, _) => ErrorView(onRetry: () => ref.invalidate(sessionListNotifierProvider)),
    );
  }
}
```

**Never do this:**
```dart
// BAD: business logic in a widget
onPressed: () {
  if (session.cost > 0 && session.duration > 0) {
    // ... save logic
  }
}

// BAD: setState for anything that persists across navigation
setState(() { _isLoading = true; });
```

---

## Testing Requirements

<!-- Instruction: Define what "tested" means on this project. Vague requirements lead to skipped tests. -->

- Every use case has unit tests covering: happy path, each failure type, edge cases
- Every provider/notifier has unit tests for each state transition
- Every screen has widget tests for: initial load state, data state, error state, empty state
- Golden tests required for all shared widgets in `shared/widgets/`
- No feature is marked done without tests passing in CI
- Coverage floor: [PLACEHOLDER — e.g., 75% overall, 90% domain layer]
- Run tests locally before every PR: `flutter test --coverage`

---

## Environment Variables

<!-- Instruction: List every env var the app uses. Never put actual values here. Values live in .env.json (gitignored) and CI secrets. -->

| Key | Purpose | Required In |
|-----|---------|------------|
| `API_BASE_URL` | Base URL for the backend API | All environments |
| `FIREBASE_PROJECT_ID` | Firebase project identifier | All environments |
| [PLACEHOLDER — e.g., `MAPS_API_KEY`] | [PLACEHOLDER — e.g., Google Maps API key for location features] | [PLACEHOLDER] |
| [PLACEHOLDER] | [PLACEHOLDER] | [PLACEHOLDER] |

**Local setup:** Copy `.env.example.json` to `.env.json` and fill in development values.
**Never commit** `.env.json`, `.env.staging.json`, or `.env.prod.json`.

---

## Common Commands

```bash
# Install dependencies
flutter pub get

# Run code generation (after changing @riverpod, @freezed, or @JsonSerializable)
dart run build_runner build --delete-conflicting-outputs

# Watch mode for code generation during development
dart run build_runner watch --delete-conflicting-outputs

# Run the app (development)
flutter run --dart-define-from-file=.env.json

# Run all tests
flutter test --coverage

# Run a specific test file
flutter test test/features/sessions/domain/usecases/create_session_use_case_test.dart

# Lint
flutter analyze

# Fix auto-fixable lint issues
dart fix --apply

# Build release APK
flutter build apk --release --dart-define-from-file=.env.prod.json

# Build release AAB (for Play Store)
flutter build appbundle --release --dart-define-from-file=.env.prod.json

# Build release IPA
flutter build ios --release --dart-define-from-file=.env.prod.json

# Update dependencies
flutter pub upgrade --major-versions
```

---

## Known Issues / Gotchas

<!-- Instruction: Append to this list immediately when you discover a trap. This section prevents the same mistake twice. -->

- [PLACEHOLDER — e.g., GoRouter `context.push` vs `context.go`: use `context.go` for root navigation, `context.push` for stacking. Using `push` for root routes causes back-stack buildup.]
- [PLACEHOLDER — e.g., `firebase_core` must be initialized before any other Firebase call — do this in `main()` before `runApp()` or the app crashes silently in release mode.]
- [PLACEHOLDER — e.g., `flutter_secure_storage` on Android requires `minSdkVersion 18`. Our `build.gradle` sets this — do not lower it.]
- [PLACEHOLDER — e.g., `build_runner` can get into a bad state if you `Ctrl+C` mid-generation. Run `flutter clean` and rebuild from scratch when this happens.]
- [PLACEHOLDER — add project-specific gotchas here]

---

## Things Claude Must Never Do

<!-- Instruction: Hard rules. These reflect past mistakes, style decisions, or architectural non-negotiables. -->

- Never use `GetX` or `Provider` (legacy) — we use Riverpod only
- Never use `setState` for anything that outlives the widget or relates to business data
- Never put business logic in a widget `build` method or `onPressed` callback — it belongs in a use case
- Never use `dynamic` except for deserializing raw JSON from external APIs
- Never call `DateTime.now()` directly in business logic — inject it so it's testable
- Never add a dependency without adding it to the `technical_plan.md` dependencies table
- Never commit `.env` files, keystore files, or any file containing secrets
- Never write `// ignore:` lint suppression comments without a code comment explaining why
- Never modify generated files (`*.g.dart`, `*.freezed.dart`) by hand — they will be overwritten
- [PLACEHOLDER — add project-specific rules here]

---

## Current Session Context

<!-- Instruction: Update this section at the start of each session to orient Claude quickly. Replace the previous entry — don't accumulate history here (that belongs in context-log-sessions-XX.md). -->

**Last updated:** [PLACEHOLDER — YYYY-MM-DD]
**Current focus:** [PLACEHOLDER — e.g., Implementing session logging feature (Phase 2 of MVP milestone)]
**Active branch:** [PLACEHOLDER — e.g., feature/session-logging]
**Blocking issues:** [PLACEHOLDER — e.g., None / "API endpoint not ready — using mock until [date]"]
**Next up:** [PLACEHOLDER — e.g., Session list screen after session form is complete]
