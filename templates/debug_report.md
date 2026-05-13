# Debug Report: [ISSUE TITLE]

<!-- Instruction: Fill this out when investigating a significant bug. It serves as a record for the team, a reference if the issue recurs, and documentation for the fix. A good debug report prevents the same bug from recurring. -->

**Issue Title:** [PLACEHOLDER — e.g., "App crashes on session save when device is in airplane mode"]
**Date Reported:** [PLACEHOLDER — YYYY-MM-DD]
**Date Resolved:** [PLACEHOLDER — YYYY-MM-DD or "Open"]
**Reporter:** [PLACEHOLDER — @username or "User report via App Store review"]
**Assignee:** [PLACEHOLDER — @username]

---

## Severity

`critical` — app crashes or data loss for any user
`high` — core feature broken for significant user segment
`medium` — feature partially broken, workaround exists
`low` — cosmetic or minor inconvenience

**Selected:** [PLACEHOLDER]

---

## Issue Type

`runtime error` | `layout / rendering` | `async / race condition` | `build / compile` | `platform specific` | `test failure` | `performance` | `memory leak`

**Selected:** [PLACEHOLDER]
**Affected Platforms:** `iOS` | `Android` | `Both`

---

## Reproduction Steps

<!-- Instruction: Numbered, precise steps. "Sometimes crashes" is not a bug report. Include exact data inputs if relevant. -->

1. [PLACEHOLDER — e.g., Open the app while connected to WiFi]
2. [PLACEHOLDER — e.g., Navigate to Home → tap the "+" FAB]
3. [PLACEHOLDER — e.g., Fill in: Duration = 45 min, Cost = $12.50]
4. [PLACEHOLDER — e.g., Enable airplane mode]
5. [PLACEHOLDER — e.g., Tap "Save Session"]
6. [PLACEHOLDER — e.g., App crashes immediately]

**Reproduction rate:** [PLACEHOLDER — e.g., 100% reproducible / ~50% / intermittent]
**Regression introduced in:** [PLACEHOLDER — e.g., v1.1.3 / unknown]

---

## Error Message

<!-- Instruction: Exact error text. Copy from the device, Crashlytics, or flutter logs — don't paraphrase. -->

```
[PLACEHOLDER — paste exact error message here, e.g.:

Unhandled Exception: SocketException: Failed host lookup:
'api.example.com' (OS Error: Network is unreachable, errno = 101)
]
```

---

## Stack Trace

<!-- Instruction: Full stack trace. Truncate only if it exceeds ~100 lines and the relevant frames are clear. -->

```
[PLACEHOLDER — paste full stack trace here, e.g.:

#0      _SimpleSocket.address (dart:io/socket.dart:331:7)
#1      NetworkRepository.saveSession (package:myapp/features/sessions/data/repositories/network_session_repository.dart:47:5)
#2      CreateSessionUseCase.call (package:myapp/features/sessions/domain/usecases/create_session_use_case.dart:22:3)
#3      SessionFormNotifier.save (package:myapp/features/sessions/presentation/providers/session_form_notifier.dart:38:7)
...
]
```

---

## Environment

**Flutter version:** [PLACEHOLDER — e.g., `flutter --version` output]

```
Flutter 3.19.0 • channel stable
Framework • revision abc123 (3 weeks ago) • 2024-02-15
Engine • revision def456
Tools • Dart 3.3.0 • DevTools 2.31.1
```

**App version:** [PLACEHOLDER — e.g., 1.1.3+42]
**Device / OS:** [PLACEHOLDER — e.g., iPhone 15 Pro (iOS 17.2) and Pixel 7 (Android 14)]
**Build mode:** `debug` | `profile` | `release`

---

## Root Cause Analysis

<!-- Instruction: Describe what was actually wrong — not the symptom but the underlying cause. "The network call failed" is a symptom. "The repository threw a SocketException that was not caught in the use case, propagating as an unhandled exception to the Dart isolate" is a root cause. -->

[PLACEHOLDER — e.g., "The `NetworkSessionRepository.saveSession()` method called the API directly without a try/catch. When the device has no connectivity, `Dio` throws a `DioException` wrapping a `SocketException`. This exception was not caught at the repository boundary and propagated up through the use case and notifier as an unhandled exception, crashing the app.

The root cause is a missing error handling contract at the repository layer: the repository is supposed to return `Either<Failure, Session>` but the implementation let raw exceptions escape."]

---

## Fix Applied

<!-- Instruction: Summarize the change. If the diff is short, include it. If it's long, link to the commit or PR. -->

**Commit:** [PLACEHOLDER — git SHA or PR link]
**Files changed:** [PLACEHOLDER — list affected files]

```dart
// BEFORE — repository let DioException escape
Future<Either<Failure, Session>> saveSession(Session session) async {
  final response = await _dio.post('/sessions', data: session.toJson());
  return Right(Session.fromJson(response.data));
}

// AFTER — catch network errors at the boundary
Future<Either<Failure, Session>> saveSession(Session session) async {
  try {
    final response = await _dio.post('/sessions', data: session.toJson());
    return Right(Session.fromJson(response.data));
  } on DioException catch (e) {
    if (e.type == DioExceptionType.connectionError) {
      return Left(NetworkFailure('No internet connection'));
    }
    return Left(ServerFailure(e.message ?? 'Unexpected server error'));
  }
}
```

---

## Verification Commands

<!-- Instruction: Exact steps to confirm the fix works and the regression test passes. -->

```bash
# Run the regression test added for this bug
flutter test test/features/sessions/data/repositories/network_session_repository_test.dart

# Run the full session feature test suite
flutter test test/features/sessions/ --coverage

# Manual verification: reproduce original steps with airplane mode
# Expected: app shows offline error banner, session saved locally, no crash
```

**Manual verification result:** [PLACEHOLDER — e.g., Confirmed fixed on iPhone 15 Pro (iOS 17.2) and Pixel 7 (Android 14)]

---

## Prevention Notes

<!-- Instruction: How do we prevent this class of bug from recurring? Add a rule to code review, a linter, or the project's CLAUDE.md. -->

- [PLACEHOLDER — e.g., All repository implementations must catch `DioException` and return typed `Failure` — no raw exceptions across the domain boundary. Added to code review checklist.]
- [PLACEHOLDER — e.g., Added a base `SafeRepository` mixin that wraps calls in a try/catch as a safety net.]
- [PLACEHOLDER — e.g., Integration test added that simulates offline mode during save to prevent regression.]
- [PLACEHOLDER — e.g., Added to `context-log-gotchas.md`: "Repository implementations must never throw — always return Either<Failure, T>."]

---

## Related Issues

- [PLACEHOLDER — e.g., #42 — Similar crash in the profile update flow (same root cause, fixed in same PR)]
- [PLACEHOLDER — e.g., ADR-007 — Error handling strategy (this bug validates the decision)]
