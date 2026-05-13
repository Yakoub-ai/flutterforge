---
name: flutter-debugging
version: 1.0.0
description: >-
  Use this skill when the user wants to diagnose and fix a Flutter error,
  crash, or build failure. Trigger phrases: "debug Flutter", "fix Flutter
  error", "stack trace Flutter", "RenderFlex overflow", "null safety error",
  "Flutter build error", "Gradle error", "CocoaPods error", "Flutter crash",
  "StateError Flutter", "BuildContext async gap", "provider disposed error",
  "hot reload not working", "Firebase not initialized".
---

# Flutter Debugging

A repeatable protocol for diagnosing Flutter errors: classify → gather context
→ trace root cause → apply minimal fix → validate → prevent recurrence.

**Rules:** never rewrite because of a bug; never accept a workaround when the
root cause is findable; state the root cause in one sentence before writing any code.

---

## Step 1: Classify the Issue

| Error Pattern | Category | Primary Tool |
|---|---|---|
| `RenderFlex overflowed by N pixels` | Layout | Widget Inspector, wrap in `Expanded`/`Flexible` |
| `Null check operator used on a null value` | Null safety | Stack trace, find where `!` is called on null |
| `StateError: Bad state: No element` | Collection/async | Provider lifecycle, stream state |
| `LateInitializationError` | Initialization | Trace where `late` field is used before `initState` |
| `type 'Null' is not a subtype of 'X'` | Type / JSON | DTO `fromJson`, null field in API response |
| Gradle build failure | Android build | Gradle logs, SDK/AGP version matrix |
| CocoaPods error | iOS build | `pod install`, Podfile.lock conflicts |
| Firebase initialization error | Config | `google-services.json`, `firebase_options.dart` |
| `MissingPluginException` | Plugin | `flutter clean && flutter pub get`, full rebuild |
| `PlatformException` | Native interop | Plugin version, gradle/pod sync |
| `ProviderException` / `ProviderDisposedException` | Riverpod lifecycle | `autoDispose` timing, `keepAlive` |
| `setState() called after dispose()` | Widget lifecycle | `mounted` check after `await` |

---

## Step 2: Gather Context

Before attempting a fix:
- Full error message and stack trace (exact text, not paraphrased)
- Flutter version: `flutter --version`
- Platform: iOS / Android / Web
- Trigger: hot reload / cold start / specific action / after specific data
- Recent changes: `git diff`

For build errors: `flutter doctor -v`

For runtime crashes: `flutter run --verbose 2>&1 | head -200`

---

## Step 3: Root Cause by Category

### RenderFlex Overflow
Open Widget Inspector, find the `Row`/`Column` in the stack trace.

Fixes in priority order:
1. `Expanded(child: Text(longText))` — fills available space
2. `Flexible(child: Text(longText))` — shrinks but doesn't force fill
3. `SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(...))` — for scrollable content

### Null Safety Errors
Find the `!` on the stack trace line. Trace backwards to when the variable is null.

```dart
final name = user?.displayName ?? 'Anonymous';   // null-aware
if (user == null) return;                         // early guard
```

Never use `late` unless the value is guaranteed set in `initState` before first `build`.

### Riverpod / Provider Errors
`ProviderDisposedException` — provider with `autoDispose` accessed after widget unmount, or `ref.read` called in async method after `await` when provider was already disposed.

Fix: cache the value before `await`:
```dart
final repo = ref.read(repositoryProvider); // before await
await someAsyncOperation();
await repo.doSomething();                  // use cached ref
```

For providers that must outlive the screen: `@Riverpod(keepAlive: true)`.

### Async / BuildContext Errors
`setState()` or `Navigator.of(context)` called after `await` when widget may be disposed.
```dart
await repository.save(data);
if (!mounted) return;
Navigator.of(context).pop();
```

Or capture navigator before the await: `final navigator = Navigator.of(context);`

### Android / Gradle Build Failures
1. Read the FULL output — the real error is before `BUILD FAILED`.
2. Check `compileSdkVersion`, `targetSdkVersion`, `minSdkVersion`, `kotlinVersion`.
3. Check Android Gradle Plugin (AGP) version compatibility.

```bash
flutter clean && flutter pub get
cd android && ./gradlew clean --refresh-dependencies
```

Common: `D8: Invoke-customs only supported with --min-api 26` → raise `minSdkVersion` to 26.
`Duplicate class kotlin.collections.jdk8` → Kotlin version to 1.8+.

### iOS / CocoaPods Build Failures
```bash
cd ios && pod deintegrate && pod install
pod repo update && pod install   # if repo is stale
```

If deployment target issue, update `ios/Podfile`: `platform :ios, '14.0'`
After any Podfile change: `flutter clean && cd ios && pod install && cd .. && flutter run`

### Firebase Initialization Errors
Checklist:
1. `google-services.json` in `android/app/` (not `android/`).
2. `GoogleService-Info.plist` in `ios/Runner/` and added to Xcode target.
3. `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` before `runApp()`.
4. `firebase_options.dart` generated via `flutterfire configure`.
5. Package name in `google-services.json` matches `applicationId` in `build.gradle`.

### MissingPluginException
Plugin's native code not compiled into the app.
```bash
flutter clean && flutter pub get && flutter run   # full rebuild required
```

---

## Step 4: Apply the Minimal Fix

State the root cause in one sentence. Apply the smallest change that fixes it.
Do not refactor surrounding code during a bug fix — that changes two things at
once and makes the fix harder to verify.

---

## Step 5: Validate

```bash
flutter analyze
flutter test
flutter clean && flutter pub get && flutter build [apk|ios|web]   # for build errors
```

Never mark a bug fixed until `flutter analyze` passes and the relevant test passes.
If no test covers the bug, write one before closing.

---

## Step 6: Prevent Recurrence

1. Write a regression test that would have caught the bug.
2. If the bug is from a pattern the team repeats, append to `context-log-gotchas.md`.
3. If it required a non-obvious setup step, document in `docs/debugging/` or the README.

---

## Flutter Gotcha Reference

- **Hot reload vs hot restart** — hot reload preserves widget state; hot restart re-initializes everything. Changes to `main.dart` init, platform channels, and plugin registration require hot restart.
- **`const` constructors** — mark every widget `const` when fields are compile-time constants. `flutter analyze` flags missing `const`.
- **Keys in lists** — always provide `ValueKey(item.id)` to list items that can reorder, be inserted, or removed.
- **`BuildContext` across async gaps** — any `await` creates a gap; the widget may unmount before the code after `await` runs. Check `mounted` or capture imperative objects before `await`.
- **Streams not closed** — `StreamSubscription` and `StreamController` must be cancelled/closed in `dispose()`. Riverpod: use `ref.onDispose`.
- **`autoDispose` timing** — provider is destroyed when last listener is removed. Use `keepAlive` for data that must persist across navigation.
- **`freezed` union exhaustiveness** — missing `when`/`map` case compiles but throws at runtime. Use `maybeWhen` only when you genuinely don't need all states.

---

## Cross-references

- Error type hierarchy: `@references/dart-error-mapping.md`
- Agent: `flutter-debugger`
- Build config issues: `flutter-release-readiness` skill (Android/iOS checklist)
