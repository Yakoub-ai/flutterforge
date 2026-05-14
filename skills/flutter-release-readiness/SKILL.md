---
name: flutter-release-readiness
version: 1.0.0
description: >-
  Prepare a Flutter app for Android and iOS release. Use when the user wants to
  run a pre-release checklist, prepare a build for the App Store or Google Play,
  configure signing, or check release build readiness.
  Trigger phrases: "prepare Flutter release", "app store Flutter", "Google Play Flutter",
  "release checklist", "publish Flutter app", "flutter build appbundle",
  "iOS archive Flutter", "sign Flutter app", "release build Flutter",
  "production build Flutter", "Play Store Flutter", "TestFlight Flutter".
---

# Flutter Release Readiness

Prepare a Flutter app for Android and iOS release: versioning, quality gate, signing guidance, store metadata, build commands, and CI/CD checklist.

---

## Workflow

1. **Run universal pre-release gate** (both platforms must pass before continuing).
2. **Run Android-specific checks**.
3. **Run iOS-specific checks**.
4. **Run quality validation** — all three commands must pass.
5. **Generate `docs/release/release_checklist.md`** using `templates/release_checklist.md`.
6. **Generate CI/CD templates** if not present (from `templates/github_workflows/`).
7. **Present final blockers list** — do not execute release builds until user approves.

**NEVER** run `flutter build` release or publish commands without explicit user approval. **NEVER** commit signing credentials to source control.

---

## Universal Pre-Release Gate

- [ ] `pubspec.yaml` version follows `MAJOR.MINOR.PATCH+BUILD` — build number strictly greater than last submission
- [ ] `CHANGELOG.md` updated with this release's changes (Keep a Changelog format)
- [ ] `dart format --set-exit-if-changed .` passes
- [ ] `flutter analyze --no-fatal-infos` passes (zero errors; warnings documented)
- [ ] `flutter test` passes — all tests green
- [ ] No hardcoded secrets detected (run `bash scripts/collect_flutter_logs.sh` or grep `lib/` for `AIza`, `sk-`, `password =`, `private_key`)
- [ ] `.env`, `google-services.json`, `GoogleService-Info.plist` are in `.gitignore`
- [ ] Crash reporting / release health dashboard identified (Crashlytics, Sentry, or equivalent)
- [ ] Rollout plan documented: staged rollout percentage, rollback threshold, first-24-hour owner

---

## Android Checklist

- [ ] `applicationId` set correctly in `android/app/build.gradle`
- [ ] `targetSdkVersion` / `targetSdk` meets current Google Play policy. As of 2026-05-14, new apps and updates must target Android 15 / API level 35 or higher unless an exception applies
- [ ] Launcher icons configured (`flutter_launcher_icons` package or manual)
- [ ] Adaptive icons configured for API 26+ (`ic_launcher.xml`)
- [ ] Permissions in `AndroidManifest.xml` — remove any unused permissions
- [ ] `minSdkVersion` set appropriately (Flutter minimum is 21)
- [ ] Proguard/R8 rules present if using code shrinking
- [ ] Signing: keystore documented (never committed); `key.properties` in `.gitignore`
- [ ] Release build: `flutter build appbundle --release`
- [ ] Play Store metadata: title (≤30 chars), short description (≤80 chars), full description (≤4000 chars), screenshots, feature graphic
- [ ] Privacy policy URL ready
- [ ] Play Data Safety answers prepared and match actual app behavior

---

## iOS Checklist

- [ ] `PRODUCT_BUNDLE_IDENTIFIER` set in `ios/Runner.xcodeproj`
- [ ] App icons configured in `ios/Runner/Assets.xcassets/AppIcon.appiconset`
- [ ] Launch screen configured in `LaunchScreen.storyboard`
- [ ] `Info.plist` permission strings present for every permission requested (camera, location, microphone, etc.)
- [ ] `PrivacyInfo.xcprivacy` present when required-reason APIs or third-party SDK requirements apply
- [ ] App Store privacy details prepared; ATT reviewed if the app tracks users across apps or websites
- [ ] `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` match `pubspec.yaml`
- [ ] CocoaPods up to date: `cd ios && pod install --repo-update`
- [ ] Signing: Xcode managed signing or manual profile documented (never committed)
- [ ] Release build: `flutter build ios --release --no-codesign` (verify then sign via Xcode)
- [ ] App Store metadata: app name, description, keywords (≤100 chars), screenshots for required device sizes
- [ ] Privacy nutrition labels prepared for App Store Connect

---

## Build Commands

```bash
# Android
flutter build appbundle --release                    # Play Store (preferred)
flutter build apk --release --split-per-abi          # APK (direct installs)

# iOS
flutter build ios --release --no-codesign            # then archive via Xcode

# Run final checks first
dart format --set-exit-if-changed .
flutter analyze --no-fatal-infos
flutter test
```

---

## Output Artifacts

- `docs/release/release_checklist.md` — completed checklist for this release
- `.github/workflows/flutter_ci.yml` — CI quality gate (if not present)
- `.github/workflows/android_build.yml` — Android build workflow (if not present)
- `.github/workflows/ios_build.yml` — iOS build workflow (if not present)

---

## Cross-references

- Agent: `release-engineer`
- Templates: `templates/release_checklist.md`, `templates/github_workflows/`
- Security: `flutter-security` skill for secrets scan before release
