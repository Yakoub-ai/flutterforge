---
description: "Prepare your Flutter app for release — Android + iOS configuration, signing guidance, store metadata checklist, CI/CD workflows."
argument-hint: [--android-only | --ios-only | --ci-only]
allowed-tools: ["Read", "Glob", "Grep", "Bash", "Task", "Write", "Edit", "TodoWrite"]
---

You are running `/flutterforge:prepare-release`.

Platform scope: `$ARGUMENTS`

---

## Phase 1: Pre-Release Quality Gate

Verify this is a Flutter project by checking for `pubspec.yaml`. If not found, stop with: "No pubspec.yaml found. Are you in the Flutter project root?"

If `$ARGUMENTS` is `--ci-only`, skip the quality gate and jump to Phase 2.

Run the quality gate in sequence — stop and show output if any command fails:
```bash
dart format --set-exit-if-changed . && flutter analyze --no-fatal-infos && flutter test
```

On failure: "Fix the above issues before preparing a release. Rerun `/flutterforge:prepare-release` when they pass."

Do not proceed to Phase 2 unless all three pass (or `--ci-only` was passed).

---

## Phase 2: Parallel Release Audit

Dispatch BOTH agents simultaneously in a single Task invocation batch. Do not wait for one before launching the other.

**Agent 1** — Launch the `release-engineer` agent using the Task tool with this prompt:
---
Context: Flutter release readiness audit. Project root is the current working directory.
Platform scope from arguments: $ARGUMENTS (if empty or not --android-only/--ios-only, audit both platforms).

Task: Perform a complete release readiness audit:

Android (skip if --ios-only):
- pubspec.yaml: version field present and follows semver (e.g. 1.0.0+1)
- android/app/build.gradle: applicationId set (not com.example.*), versionCode + versionName wired to Flutter
- android/app/src/main/AndroidManifest.xml: permissions declared, no debug-only permissions in release manifest
- App icons: android/app/src/main/res/mipmap-* directories have non-default icons
- Signing: key.properties referenced or documented; release buildType has signingConfig
- ProGuard/R8: minifyEnabled true for release, proguard-rules.pro present

iOS (skip if --android-only):
- ios/Runner/Info.plist: CFBundleIdentifier not com.example.*, CFBundleShortVersionString and CFBundleVersion present
- ios/Runner.xcodeproj: PRODUCT_BUNDLE_IDENTIFIER set correctly
- App icons: ios/Runner/Assets.xcassets/AppIcon.appiconset has all required sizes
- Signing: DEVELOPMENT_TEAM set or documented for manual signing
- NSUsageDescription strings present for every requested permission

Both:
- Read .github/workflows/ and list any existing CI files found

Return:
- Android checklist: item | pass/fail | notes
- iOS checklist: item | pass/fail | notes
- Missing items list (critical blockers vs. recommendations)
- Existing CI files found (names only)
---

**Agent 2** — Launch the `mobile-security-reviewer` agent using the Task tool with this prompt:
---
Context: Pre-release security scan for a Flutter project. This is a focused scan — not a full audit.

Task: Check the following and report only on issues found:
1. Secrets in source: grep for API keys, tokens, passwords hardcoded in .dart files or pubspec.yaml
2. Debug flags: check for kDebugMode guards around dev-only features; flag any debugPrint or print() calls that log sensitive data
3. Obfuscation: check if `--obfuscate --split-debug-info` flags appear in release build commands (Makefile, scripts, CI, README)
4. Sensitive config files: confirm google-services.json and GoogleService-Info.plist are listed in .gitignore
5. HTTP vs HTTPS: grep for hardcoded http:// URLs in .dart files

Return:
- Security blockers: items that must be fixed before release (critical only)
- Quick wins: low-effort improvements worth doing now
- Skip low/informational findings
---

Wait for both agents to return before proceeding to Phase 3.

---

## Phase 3: Release Checklist Generation

Synthesize the results from both Phase 2 agents:

Organize all findings into three buckets:
- PASS items: working correctly, no action needed
- NEED ATTENTION items: recommended but not blocking
- BLOCKER items: must be resolved before release

Write the checklist to `docs/release/release_checklist.md` (create `docs/release/` if needed):
- `# Release Checklist — <app name> v<version>` with today's date
- Sections: Blockers, Needs Attention, Passing, Security Notes

Use the `flutter-documentation` skill to update `CHANGELOG.md` with a release entry for this version (Keep a Changelog format). If `CHANGELOG.md` does not exist, create it.

Display the three-bucket summary inline in the conversation.

Ask: "Should I generate GitHub Actions CI/CD workflows? (flutter_ci + android_build + ios_build) Reply yes/no."

---

## Phase 4: CI/CD Generation (Conditional)

Only run this phase if the user replied yes to the Phase 3 prompt.

Launch the `release-engineer` agent using the Task tool with this prompt:
---
Context: Generate GitHub Actions CI/CD workflows for a Flutter project.

Project details from audit:
- App name and version: <from pubspec.yaml>
- Android applicationId: <from audit>
- iOS bundle identifier: <from audit>
- Existing CI files already present: <list from Phase 2 Agent 1>
- Flutter version: read from .fvmrc or .flutter-version if present, otherwise use 'stable'

Task: Generate three GitHub Actions workflow files with production-ready content:

1. `.github/workflows/flutter_ci.yml`
   Triggers: push and pull_request on main and develop
   Steps: checkout, setup Flutter, flutter pub get, dart format --set-exit-if-changed, flutter analyze --no-fatal-infos, flutter test

2. `.github/workflows/android_build.yml`
   Triggers: push to main, workflow_dispatch
   Runner: ubuntu-latest
   Steps: checkout, setup Java 17, setup Flutter, pub get, decode keystore from secret (base64), write key.properties, flutter build appbundle --release, upload artifact
   Secrets needed: KEYSTORE_BASE64, KEY_ALIAS, KEY_PASSWORD, STORE_PASSWORD

3. `.github/workflows/ios_build.yml`
   Triggers: push to main, workflow_dispatch
   Runner: macos-latest
   Steps: checkout, setup Flutter, pub get, flutter build ios --release --no-codesign, upload artifact (Runner.app)
   Note in comments: full codesign requires additional certificate secrets

Do not overwrite any existing workflow file — if one already exists, generate it with a `.new.yml` suffix and note the conflict.

Return: full YAML content for each file, list of all GitHub secret names that must be configured in Settings → Secrets → Actions.
---

Write the returned workflow files to disk using Write. Display the list of required GitHub secrets to configure.
