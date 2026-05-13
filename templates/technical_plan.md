# Technical Plan

<!-- Instruction: Write this after the app brief is approved and before writing code. Every architectural decision made here is cheaper to change than after implementation. -->

## App Overview

<!-- Instruction: 1-2 sentences. What does the app do and who is it for? -->

[PLACEHOLDER — e.g., "Volta is a Flutter app for EV drivers to log charging sessions and track monthly costs. It targets iOS 16+ and Android 8+ with Firebase as the backend."]

---

## Architecture Pattern

<!-- Instruction: Choose one. Don't mix patterns — consistency matters more than which one you pick. -->

**Pattern:** Feature-first Clean Architecture

```
Presentation → Domain → Data
     ↕              ↕         ↕
  Widgets    Use Cases   Repositories
  Providers  Entities    Data Sources
```

**Why this pattern:**
[PLACEHOLDER — e.g., "Features stay self-contained, making it easy to add/remove them without touching unrelated code. Clean boundaries make unit testing straightforward — use cases have no Flutter dependencies."]

**Rules enforced by this pattern:**
- Domain layer has zero Flutter imports
- Use cases contain all business logic — no logic in widgets
- Repositories are interfaces in domain, implemented in data
- Providers/Blocs own state — widgets are dumb

---

## Folder Structure

<!-- Instruction: Show the actual structure you will build, not a generic example. Add annotations to non-obvious folders. -->

```
lib/
├── main.dart                    # Entry point — DI setup, router, app widget
├── core/
│   ├── config/                  # App configuration, env vars, feature flags
│   ├── di/                      # Dependency injection (Riverpod providers or get_it)
│   ├── error/                   # Failure types, error handling utilities
│   ├── extensions/              # Dart extension methods
│   ├── navigation/              # Router config (GoRouter/AutoRoute)
│   ├── theme/                   # AppTheme, color tokens, text styles
│   └── utils/                   # Pure utility functions
├── features/
│   └── [feature_name]/          # One folder per feature
│       ├── data/
│       │   ├── datasources/     # Remote (API) and local (Hive/SQLite) sources
│       │   ├── models/          # JSON-serializable data models
│       │   └── repositories/    # Repository implementations
│       ├── domain/
│       │   ├── entities/        # Pure Dart business objects
│       │   ├── repositories/    # Abstract repository interfaces
│       │   └── usecases/        # Single-action use case classes
│       └── presentation/
│           ├── providers/       # Riverpod providers (or blocs/)
│           ├── screens/         # Full-screen widgets
│           └── widgets/         # Feature-scoped reusable widgets
└── shared/
    ├── widgets/                 # App-wide reusable widgets
    └── models/                  # Shared data models used across features
```

---

## State Management Decision

**Choice:** [PLACEHOLDER — e.g., Riverpod 2.x (code generation)]

**Why:**
[PLACEHOLDER — e.g., "Riverpod's compile-safe providers eliminate runtime dependency errors. Code generation reduces boilerplate. AsyncNotifier covers loading/error/data states without custom wrappers. Works well with the clean architecture boundaries — providers live in presentation, use cases in domain."]

**Pattern for async data:**

```dart
@riverpod
class SessionListNotifier extends _$SessionListNotifier {
  @override
  Future<List<Session>> build() => ref.watch(getSessionsUseCaseProvider).call();

  Future<void> refresh() => ref.refresh(sessionListNotifierProvider.future);
}
```

**Alternatives rejected:**
- [PLACEHOLDER — e.g., BLoC: too much boilerplate for this team's velocity target]
- [PLACEHOLDER — e.g., Provider (legacy): not recommended for new projects]

---

## Navigation

**Router:** [PLACEHOLDER — e.g., GoRouter ^13.x]

**Pattern:** [PLACEHOLDER — e.g., Declarative with route guards for auth]

```dart
// Route structure
/                  → SplashScreen (redirect to /home or /login)
/login             → LoginScreen
/home              → HomeScreen (shell route with bottom nav)
  /home/sessions   → SessionListScreen
  /home/stats      → StatsScreen
/session/new       → NewSessionScreen
/session/:id       → SessionDetailScreen
/settings          → SettingsScreen
```

**Auth guard:** [PLACEHOLDER — e.g., GoRouter redirect checks auth state via Riverpod; unauthenticated users land on /login]

---

## Key Dependencies

<!-- Instruction: Pin major versions. "Any" is not a version. Justify each dependency — if you can't, don't add it. -->

| Package | Version | Purpose |
|---------|---------|---------|
| [PLACEHOLDER — e.g., flutter_riverpod] | [PLACEHOLDER — e.g., ^2.5.0] | [PLACEHOLDER — e.g., State management] |
| [PLACEHOLDER — e.g., riverpod_annotation] | [PLACEHOLDER — e.g., ^2.3.0] | [PLACEHOLDER — e.g., Code generation for providers] |
| [PLACEHOLDER — e.g., go_router] | [PLACEHOLDER — e.g., ^13.0.0] | [PLACEHOLDER — e.g., Navigation] |
| [PLACEHOLDER — e.g., freezed] | [PLACEHOLDER — e.g., ^2.4.0] | [PLACEHOLDER — e.g., Immutable state/entity classes] |
| [PLACEHOLDER — e.g., json_serializable] | [PLACEHOLDER — e.g., ^6.7.0] | [PLACEHOLDER — e.g., JSON model generation] |
| [PLACEHOLDER — e.g., dio] | [PLACEHOLDER — e.g., ^5.4.0] | [PLACEHOLDER — e.g., HTTP client with interceptors] |
| [PLACEHOLDER — e.g., firebase_auth] | [PLACEHOLDER — e.g., ^4.17.0] | [PLACEHOLDER — e.g., Authentication] |
| [PLACEHOLDER — e.g., cloud_firestore] | [PLACEHOLDER — e.g., ^4.15.0] | [PLACEHOLDER — e.g., Cloud database] |
| [PLACEHOLDER — e.g., shared_preferences] | [PLACEHOLDER — e.g., ^2.2.0] | [PLACEHOLDER — e.g., Simple local key-value storage] |
| [PLACEHOLDER — e.g., flutter_secure_storage] | [PLACEHOLDER — e.g., ^9.0.0] | [PLACEHOLDER — e.g., Encrypted token storage] |

**Dev dependencies:**

| Package | Version | Purpose |
|---------|---------|---------|
| [PLACEHOLDER — e.g., build_runner] | [PLACEHOLDER — e.g., ^2.4.0] | [PLACEHOLDER — e.g., Code generation runner] |
| [PLACEHOLDER — e.g., mocktail] | [PLACEHOLDER — e.g., ^1.0.0] | [PLACEHOLDER — e.g., Mocking in tests] |
| [PLACEHOLDER — e.g., flutter_test] | SDK | [PLACEHOLDER — e.g., Widget and unit testing] |

---

## Environment Configuration

<!-- Instruction: Never hardcode environment-specific values. Define the pattern here so all contributors follow it. -->

**Method:** [PLACEHOLDER — e.g., `--dart-define-from-file` with `.env.json` files (not committed)]

```
.env.json          ← local dev (gitignored)
.env.staging.json  ← staging (gitignored, in CI secrets)
.env.prod.json     ← production (gitignored, in CI secrets)
.env.example.json  ← committed, no real values, shows required keys
```

**Access in code:**

```dart
abstract class AppConfig {
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const firebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  // Add all keys here — fail loudly if empty in debug mode
}
```

**CI command example:**

```bash
flutter build apk --release \
  --dart-define-from-file=.env.prod.json
```

---

## Error Handling Strategy

**Approach:** [PLACEHOLDER — e.g., Typed failures using sealed classes, no raw exceptions across layer boundaries]

```dart
// Domain layer — typed failures
sealed class Failure {
  const Failure(this.message);
  final String message;
}
class NetworkFailure extends Failure { ... }
class AuthFailure extends Failure { ... }
class CacheFailure extends Failure { ... }
class ServerFailure extends Failure { ... }
```

**Rules:**
- Repositories catch exceptions, return `Either<Failure, T>` (or `Result<T>`)
- Use cases propagate failures, add context if needed
- Providers map failures to user-visible messages in one place
- Widgets never catch exceptions directly

**Global error handler:** [PLACEHOLDER — e.g., FlutterError.onError + PlatformDispatcher.instance.onError both route to Crashlytics in release mode]

---

## Testing Strategy

<!-- Instruction: Define this now — retrofitting tests to untestable code is painful. -->

| Layer | Type | Tool | Target Coverage |
|-------|------|------|----------------|
| Domain (use cases, entities) | Unit | flutter_test + mocktail | [PLACEHOLDER — e.g., 90%] |
| Data (repositories, models) | Unit | flutter_test + mocktail | [PLACEHOLDER — e.g., 80%] |
| Presentation (providers) | Unit | flutter_test + mocktail | [PLACEHOLDER — e.g., 80%] |
| Widgets | Widget | flutter_test | [PLACEHOLDER — e.g., Key states per screen] |
| Critical user flows | Integration | integration_test | [PLACEHOLDER — e.g., Auth, core action] |
| Shared design components | Golden | golden_toolkit | [PLACEHOLDER — e.g., All reusable widgets] |

**Test file location:** Mirror the `lib/` structure under `test/`

---

## CI/CD Plan

**Platform:** [PLACEHOLDER — e.g., GitHub Actions]

**Pipelines:**

| Trigger | Pipeline | Steps |
|---------|----------|-------|
| Pull request | `ci.yml` | analyze → test → coverage check |
| Merge to main | `build.yml` | CI steps + build APK + build IPA (simulator) |
| Tag `v*.*.*` | `release.yml` | build.yml + sign + upload to Play/TestFlight |

**Branch strategy:** [PLACEHOLDER — e.g., `main` (stable) + `develop` + feature branches]

---

## Open Decisions

<!-- Instruction: List everything that needs a decision before building the affected feature. Assign owners. -->

| Decision | Options | Owner | Needed By |
|----------|---------|-------|-----------|
| [PLACEHOLDER — e.g., Offline-first vs online-only at MVP] | [PLACEHOLDER — e.g., offline-first / online-only] | [PLACEHOLDER — @name] | [PLACEHOLDER — date] |
| [PLACEHOLDER — e.g., Auth providers at launch] | [PLACEHOLDER — e.g., Email+Password only / + Google / + Apple] | [PLACEHOLDER] | [PLACEHOLDER] |
| [PLACEHOLDER] | [PLACEHOLDER] | [PLACEHOLDER] | [PLACEHOLDER] |
