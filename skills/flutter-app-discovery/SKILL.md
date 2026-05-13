---
name: flutter-app-discovery
description: >-
  Use this skill when the user wants to understand, audit, or explore an
  existing Flutter codebase before making changes. Trigger phrases:
  "audit existing Flutter app", "understand this Flutter codebase",
  "explore this Flutter project", "what is this app doing",
  "analyze this Flutter repo", "review this Flutter project",
  "give me an overview of this Flutter app", "what packages does this app use",
  "map out this Flutter codebase", "inspect this Flutter project".
  Also use when: the user opens a Flutter project for the first time in a
  session, asks what architecture is being used, or asks what state management
  library is in the project.
version: 1.0.0
---

# Flutter App Discovery

A read-only methodology for rapidly understanding an existing Flutter codebase
before writing a single line of code. Run this skill at the start of any session
involving an unfamiliar project, or whenever a user asks what the codebase is doing.

## Guiding Principle

Never modify files during discovery. This is a reconnaissance phase. All
conclusions drawn here feed into subsequent planning and implementation skills.
If you cannot read a file, say so — do not guess its contents.

---

## Step 1: Validate the Project Root

Before anything else, confirm this is a Flutter project.

- Check for `pubspec.yaml` in the working directory.
- If `pubspec.yaml` is absent, stop immediately and tell the user:
  "This does not appear to be a Flutter project. No `pubspec.yaml` was found."
- Check that `pubspec.yaml` contains a `flutter:` section.
- If `flutter:` is absent, note that this may be a plain Dart package, not a Flutter app.

---

## Step 2: Read `pubspec.yaml`

Extract and record the following:

- `name` — the package/app name
- `description` — app description (if present)
- `version` — current app version (semver + build number)
- `environment.sdk` — the Dart SDK constraint (e.g., `>=3.0.0 <4.0.0`)
- `environment.flutter` — Flutter SDK constraint (if set)
- `dependencies` — all runtime dependencies with version constraints
- `dev_dependencies` — all dev-only dependencies
- `flutter.uses-material-design` — whether Material is enabled
- `flutter.assets` — declared asset paths
- `flutter.fonts` — custom font declarations

Flag the following for the summary:
- Any package pinned to an exact version (no `^` or range) — this can block upgrades.
- Any package with a `path:` dependency — local packages that may not be portable.
- Any package with a `git:` dependency — unstable, tracks a branch.
- Any `flutter_localizations` or `intl` usage — indicates internationalization.

---

## Step 3: Read `analysis_options.yaml`

If this file exists, extract:

- `include:` — the lint ruleset in use (e.g., `package:very_good_analysis/analysis_options.yaml`,
  `package:flutter_lints/flutter.yaml`, `package:lints/recommended.yaml`)
- Any custom `rules:` overrides — especially rules that are disabled
- `analyzer.errors` or `analyzer.exclude` overrides

Determine strictness level:
- `very_good_analysis` → high strictness (team project, agency standard)
- `flutter_lints` → standard Flutter strictness
- `lints` or custom → minimal or custom strictness
- Absent → no lint configuration, flag as a risk

---

## Step 4: Inspect `lib/` Structure (2 Levels Deep)

List the top-level directories and their immediate children inside `lib/`.
Do not recurse deeper than 2 levels at this stage.

From the structure, determine the architecture pattern:

**Feature-first (recommended):**
```
lib/
  features/
    auth/
    home/
    profile/
  core/
  shared/
  main.dart
```

**Layered (presentation / domain / data):**
```
lib/
  presentation/
  domain/
  data/
  main.dart
```

**Flat / unstructured:**
```
lib/
  screens/
  widgets/
  models/
  services/
  main.dart
```

**MVC/MVVM variant:**
```
lib/
  models/
  views/
  controllers/ (or viewmodels/)
```

Record which pattern is in use, or note if it is mixed/unclear.

Check `main.dart` for:
- Entry point widget (e.g., `MaterialApp`, `CupertinoApp`, `ProviderScope`, `BlocProvider`)
- Theme configuration
- Initial route or home widget
- Any environment-based configuration (e.g., flavor setup, `const String.fromEnvironment`)

---

## Step 5: Assess Test Coverage Signal

Check for the presence of:
- `test/` directory — unit and widget tests
- `integration_test/` directory — integration/E2E tests

Count:
- Number of `*_test.dart` files in `test/`
- Number of `*_test.dart` files in `integration_test/`

Check for:
- A `test/helpers/` or `test/mocks/` directory — indicates organized test infrastructure
- Import of `mocktail`, `mockito`, or `flutter_test` — indicates mocking strategy

Estimate coverage signal (this is not actual coverage, just a proxy):
- 0 test files → "No tests detected — high risk"
- 1–5 test files → "Minimal testing — some coverage"
- 6–20 test files → "Moderate testing — partial coverage"
- 20+ test files → "Good testing signal — likely meaningful coverage"

---

## Step 6: Check Platform Folders

**Android (`android/`):**
- Check `android/app/build.gradle` for: `compileSdkVersion`, `minSdkVersion`, `targetSdkVersion`
- Check `android/app/src/main/AndroidManifest.xml` for: declared permissions, intent filters, deep link schemes
- Check for any `*.kt` or `*.java` files in `android/app/src/main/kotlin` or `/java` — indicates custom native code

**iOS (`ios/`):**
- Check `ios/Runner/Info.plist` for: bundle identifier, permissions usage descriptions, URL schemes
- Check for any `*.swift` or `*.m` files in `ios/Runner/` — indicates custom native code
- Check `ios/Podfile` for minimum iOS version

Flag any platform-specific capabilities that have implications for plugin compatibility or OS version requirements.

---

## Step 7: Identify Router Setup

Search the codebase for router configuration:

- `GoRouter` or `go_router` import → declarative routing with route definitions
  - Look for `GoRouter(routes: [...])` — note top-level routes
  - Check for named routes, route guards, redirect logic
- `AutoRoute` or `auto_route` → code-generated declarative routing
  - Look for `@AutoRouterConfig` annotation
- `Navigator.pushNamed` or `onGenerateRoute` → imperative named routing
- `MaterialApp(home: ...)` with no named routes → ad-hoc imperative routing (no router library)

Record which router is in use and whether there is a central route definition file.

---

## Step 8: Identify State Management

Search for the following imports in `lib/`:

| Library | Import Pattern | Notes |
|---------|---------------|-------|
| Riverpod | `flutter_riverpod`, `riverpod_annotation`, `hooks_riverpod` | Check for `@riverpod` annotations |
| Bloc | `flutter_bloc`, `bloc` | Check for `Cubit` vs `Bloc` usage |
| Provider | `provider` (not riverpod) | Older pattern |
| GetX | `get` | Note if in use — often controversial |
| MobX | `mobx`, `flutter_mobx` | Code-gen required |
| setState only | No state library found | Simple/small app |

If multiple state management libraries are found, flag this as an inconsistency — mixing patterns adds cognitive overhead and should be consolidated.

---

## Step 9: Flag Key Dependency Concerns

For each package in `dependencies`, check:

1. **Outdated packages** — if you know a package has a significantly newer major version, flag it.
2. **Deprecated packages** — e.g., `pedantic` (replaced by `lints`), `provider` used alongside `riverpod`.
3. **Security-sensitive packages** — anything handling auth, cryptography, storage, networking:
   - `flutter_secure_storage`, `crypto`, `dio`, `http`, `firebase_auth`, `supabase`
   - Note the version and recommend verifying against latest stable.
4. **Large packages that may have lighter alternatives** — flag only if clearly relevant.

Also scan for:
- Hardcoded strings that look like credentials (API keys, tokens, passwords) in Dart files.
- `TODO`, `FIXME`, `HACK`, `XXX` comments — count them and note locations.
- `debugPrint` or `print` statements left in production code paths.

---

## Step 10: Produce Summary Report

Print a structured summary to the conversation with the following sections:

```
## Flutter App Discovery Report

### Project Overview
- App name:
- Version:
- Dart SDK:
- Flutter SDK constraint:

### Architecture
- Pattern: [feature-first / layered / flat / mixed]
- Router: [GoRouter / AutoRoute / imperative / none]
- State management: [Riverpod / Bloc / Provider / GetX / setState-only / mixed]

### Key Dependencies
- [List notable runtime dependencies with version]
- Flagged: [any outdated / deprecated / pinned / git dependencies]

### Test Coverage Signal
- Unit/widget tests: [count] files
- Integration tests: [count] files
- Test infrastructure: [mocktail / mockito / none]
- Signal: [None / Minimal / Moderate / Good]

### Platform-Specific Notes
- Android: minSdkVersion, targetSdkVersion, custom native code: [yes/no]
- iOS: minimum iOS version, custom native code: [yes/no]
- Declared permissions: [list]

### Code Quality Signals
- Lint configuration: [ruleset in use or absent]
- TODO/FIXME comments: [count and locations]
- print() statements: [count]
- Hardcoded credential risk: [none detected / flagged locations]

### Risks
- [Bulleted list of risks in priority order]

### Recommended Next Actions
- [Bulleted list of concrete next steps]
```

---

## Output Artifacts

The summary is always printed to the conversation.

If the user wants the report persisted, write it to:
`docs/audit/codebase_discovery.md`

Create the `docs/audit/` directory if it does not exist. Do not write the file unless the user explicitly requests persistence.

---

## Rules

- Never modify any file during this skill. Read only.
- If a file cannot be read (missing, permission denied), note it and continue — do not halt.
- Do not infer content you cannot read. State what is unknown.
- If the project has no `pubspec.yaml`, stop immediately with a clear message.
- If the user's working directory is unclear, ask before proceeding.
- Do not generate architecture recommendations during discovery — that is the `flutter-architecture` skill's job.
- Flag but do not fix: hardcoded strings, TODO comments, print statements. Discovery is not remediation.
