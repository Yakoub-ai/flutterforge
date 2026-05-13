# Test Plan: [FEATURE / MODULE NAME]

<!-- Instruction: Write this alongside the feature spec, not after implementation. Tests written after the fact tend to test the implementation rather than the requirements. -->

**Feature / Module:** [PLACEHOLDER — e.g., Session Logging Feature]
**Author:** [PLACEHOLDER — @username]
**Date:** [PLACEHOLDER — YYYY-MM-DD]
**Risk Level:** `high` | `medium` | `low`

<!-- Instruction: Risk level guides test depth. High = user-facing feature with money, auth, or data loss risk. Low = cosmetic or low-traffic feature. -->

---

## Unit Tests

<!-- Instruction: Unit tests cover business logic — use cases, entities, validation rules, data transformations. They run fast and have no Flutter dependencies. -->

**What to test:**

| Class / Function | Test Cases | Mock Dependencies |
|-----------------|-----------|-------------------|
| [PLACEHOLDER — e.g., `CreateSessionUseCase`] | [PLACEHOLDER — e.g., returns session on success; returns NetworkFailure when offline; returns ValidationFailure when cost and duration are both 0] | [PLACEHOLDER — e.g., `SessionRepository`] |
| [PLACEHOLDER — e.g., `Session.validate()`] | [PLACEHOLDER — e.g., valid when cost > 0; invalid when date is future; invalid when duration > 1440] | [PLACEHOLDER — e.g., none — pure function] |
| [PLACEHOLDER — e.g., `CostFormatter.toCents()`] | [PLACEHOLDER — e.g., 12.50 → 1250; 0.01 → 1; 0 → 0; negative throws] | [PLACEHOLDER — e.g., none] |

**Test file locations:**

```
test/
└── features/
    └── sessions/
        └── domain/
            └── usecases/
                └── create_session_use_case_test.dart
```

**Run command:**

```bash
flutter test test/features/sessions/domain/ --coverage
```

---

## Widget Tests

<!-- Instruction: Widget tests cover UI logic — state rendering, user interactions, navigation triggers. They don't require a device but do have Flutter dependencies. -->

**Widgets to test:**

| Widget | States to Cover | Key Assertions |
|--------|----------------|----------------|
| [PLACEHOLDER — e.g., `NewSessionScreen`] | [PLACEHOLDER — e.g., initial/empty form, validation errors visible, loading state during submit] | [PLACEHOLDER — e.g., submit button disabled while loading; error text appears after failed submit] |
| [PLACEHOLDER — e.g., `SessionListItem`] | [PLACEHOLDER — e.g., synced session, unsynced (offline) session] | [PLACEHOLDER — e.g., offline icon visible when `isSynced` is false] |
| [PLACEHOLDER — e.g., `EmptySessionsState`] | [PLACEHOLDER — e.g., default state] | [PLACEHOLDER — e.g., CTA button present with correct label] |

**Test file locations:**

```
test/
└── features/
    └── sessions/
        └── presentation/
            └── screens/
                └── new_session_screen_test.dart
```

**Run command:**

```bash
flutter test test/features/sessions/presentation/ --coverage
```

---

## Integration Tests

<!-- Instruction: Integration tests cover complete user flows. They run on a real device or emulator. Keep these focused — they're slow. Test the happy path and the most critical failure path per feature. -->

**User flows to cover:**

| Flow | Steps | Expected Outcome |
|------|-------|-----------------|
| [PLACEHOLDER — e.g., Happy path: log a session] | [PLACEHOLDER — e.g., 1. Tap FAB on HomeScreen 2. Fill form with valid data 3. Tap Save 4. Verify session appears in list] | [PLACEHOLDER — e.g., Session visible in list with correct cost and duration] |
| [PLACEHOLDER — e.g., Offline save] | [PLACEHOLDER — e.g., 1. Disable network 2. Log session 3. Re-enable network 4. Verify sync] | [PLACEHOLDER — e.g., Session saves locally, syncs when back online, offline indicator clears] |
| [PLACEHOLDER] | [PLACEHOLDER] | [PLACEHOLDER] |

**Test file locations:**

```
integration_test/
└── features/
    └── sessions/
        └── session_logging_test.dart
```

**Run command:**

```bash
# On a connected device or emulator:
flutter test integration_test/features/sessions/ \
  --dart-define-from-file=.env.test.json
```

---

## Golden Tests

<!-- Instruction: Golden tests catch unintended visual regressions. Run them for shared design components and screens that must look exact. Update goldens intentionally — never auto-update without reviewing the diff. -->

**Components to golden test:**

| Component | Variants | Notes |
|-----------|---------|-------|
| [PLACEHOLDER — e.g., `SessionListItem`] | [PLACEHOLDER — e.g., synced light, synced dark, unsynced light, unsynced dark] | [PLACEHOLDER — e.g., Test on 375pt width] |
| [PLACEHOLDER — e.g., `EmptySessionsState`] | [PLACEHOLDER — e.g., light, dark] | [PLACEHOLDER] |
| [PLACEHOLDER] | [PLACEHOLDER] | [PLACEHOLDER] |

**Golden file locations:**

```
test/
└── goldens/
    └── sessions/
        └── session_list_item_synced_light.png
        └── session_list_item_synced_dark.png
        └── ...
```

**Run commands:**

```bash
# Generate/update goldens (review diffs before committing):
flutter test test/ --update-goldens

# Verify goldens match (run in CI):
flutter test test/ --tags golden
```

---

## Excluded from Testing

<!-- Instruction: Be explicit about what you're not testing and why. "We didn't have time" is not a valid reason — escalate if important tests are being skipped under time pressure. -->

| Item | Reason |
|------|--------|
| [PLACEHOLDER — e.g., Third-party Firebase SDK internals] | [PLACEHOLDER — e.g., Tested by Firebase SDK team — we test our wrapper, not theirs] |
| [PLACEHOLDER — e.g., Platform-specific permission dialogs] | [PLACEHOLDER — e.g., OS-level UI, cannot be automated in Flutter tests] |
| [PLACEHOLDER] | [PLACEHOLDER] |

---

## Test Data Setup

<!-- Instruction: Define the test fixtures and fake data factories needed. Shared factories prevent test data drift. -->

**Factories:**

```dart
// test/helpers/factories/session_factory.dart

Session makeSession({
  String? id,
  int durationMinutes = 45,
  double costInCents = 1250,
  bool isSynced = true,
}) => Session(
  id: id ?? 'test-session-id',
  userId: 'test-user-id',
  startedAt: DateTime(2024, 6, 15, 14, 30),
  durationMinutes: durationMinutes,
  costInCents: costInCents,
  isSynced: isSynced,
);
```

**Fakes:**

```dart
// test/helpers/fakes/fake_session_repository.dart

class FakeSessionRepository implements SessionRepository {
  List<Session> sessions = [];
  bool shouldFailOnSave = false;

  @override
  Future<Either<Failure, Session>> createSession(Session session) async {
    if (shouldFailOnSave) return Left(NetworkFailure('Simulated error'));
    sessions.add(session);
    return Right(session);
  }
  // ...
}
```

---

## Edge Cases

<!-- Instruction: List the non-obvious inputs and conditions that could break this feature. -->

- [PLACEHOLDER — e.g., Session submitted with exactly 0 cost and 0 duration (should fail validation)]
- [PLACEHOLDER — e.g., Session submitted while offline (should queue locally)]
- [PLACEHOLDER — e.g., User rapidly double-taps submit button (should not create duplicate session)]
- [PLACEHOLDER — e.g., Form submitted with a date set to December 31, 23:59 local time (timezone edge case)]
- [PLACEHOLDER — e.g., Cost entered with more than 2 decimal places (e.g., $12.999)]
- [PLACEHOLDER — e.g., Very long location name (>200 characters)]
- [PLACEHOLDER]

---

## Mocking Strategy

<!-- Instruction: Define the boundary at which mocking happens. Mocking too deep (e.g., mocking HTTP responses) makes tests fragile. Mocking too shallow (e.g., never mocking) makes tests slow and side-effectful. -->

**Mock at these boundaries:**

| Boundary | Tool | Notes |
|----------|------|-------|
| `SessionRepository` interface | `mocktail` | Use case tests mock the repository interface, not the implementation |
| `NetworkInfo` / connectivity | `mocktail` | Simulates online/offline for use case tests |
| `DateTime.now()` | Injectable dependency | Pass `Clock` or a `DateTime` parameter — never call `DateTime.now()` in business logic |
| Firebase / external SDKs | `fake_cloud_firestore`, `fake_firebase_auth` | Use official Firebase fake packages for data layer tests |

**Do not mock:**
- [PLACEHOLDER — e.g., Riverpod providers in widget tests — use `ProviderScope` with overrides instead]
- [PLACEHOLDER — e.g., Flutter framework itself]

---

## CI Commands

<!-- Instruction: Exact commands CI will run. Keep these updated when test locations change. -->

```bash
# Lint and static analysis
flutter analyze --fatal-infos

# All unit and widget tests with coverage
flutter test --coverage

# Coverage threshold check (requires lcov)
lcov --summary coverage/lcov.info
# or use: flutter test --coverage && dart pub global run full_coverage

# Integration tests (device required — runs in CI with emulator)
flutter test integration_test/ \
  --dart-define-from-file=.env.test.json

# Golden tests only
flutter test test/ --tags golden
```

---

## Coverage Target

<!-- Instruction: Coverage targets are a floor, not a ceiling. 100% coverage with weak assertions means nothing. -->

| Layer | Target |
|-------|--------|
| Domain (use cases, entities) | [PLACEHOLDER — e.g., 90%] |
| Data (repositories, models) | [PLACEHOLDER — e.g., 80%] |
| Presentation (providers/notifiers) | [PLACEHOLDER — e.g., 80%] |
| Overall project | [PLACEHOLDER — e.g., 75%] |

**Coverage report:** `coverage/lcov.info` (generated by `flutter test --coverage`)
