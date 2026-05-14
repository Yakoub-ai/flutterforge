# Release Checklist

<!-- Instruction: Complete every applicable item before submitting to either store. A missed item here means a rejected build or a broken production app. Assign a person to each section — one owner per platform. -->

**App Name:** [PLACEHOLDER]
**Release Version:** [PLACEHOLDER — e.g., 1.2.0]
**Build Number:** [PLACEHOLDER — e.g., 47]
**Release Type:** `major` | `minor` | `patch` | `hotfix`
**Release Owner:** [PLACEHOLDER — @username]
**Date:** [PLACEHOLDER — YYYY-MM-DD]

---

## Common Checks

<!-- Instruction: Run these before touching platform-specific steps. -->

- [ ] `pubspec.yaml` version updated: `version: [VERSION]+[BUILD_NUMBER]`
- [ ] `CHANGELOG.md` updated with this version's changes
- [ ] All feature branches merged to the release branch
- [ ] `git tag v[VERSION]` created and pushed after final build

**Code Quality**
- [ ] `flutter analyze` passes with zero errors and zero warnings
- [ ] All tests pass: `flutter test`
- [ ] No TODO or FIXME comments introduced in this release (review with `grep -r "TODO\|FIXME" lib/`)
- [ ] No hardcoded secrets, API keys, or passwords in source code
- [ ] `.env` files are gitignored and not committed

**Build Sanity**
- [ ] Debug-only code wrapped in `kDebugMode` guards or disabled in release profile
- [ ] Verbose logging of sensitive data removed or gated behind debug flag
- [ ] All feature flags for this release set to correct values in production config
- [ ] Release build tested on a physical device (not just simulator/emulator)
- [ ] Release builds use `--obfuscate --split-debug-info` and debug symbols are archived
- [ ] Crash reporting / release health dashboard is configured and visible to the release owner
- [ ] Staged rollout, rollback threshold, and first-24-hour monitoring owner are documented

---

## Android

**Owner:** [PLACEHOLDER — @username]

**App Identity**
- [ ] `applicationId` in `android/app/build.gradle` is the correct production ID
- [ ] `targetSdkVersion` / `targetSdk` meets current Google Play policy. As of 2026-05-14, new apps and updates must target Android 15 / API level 35 or higher unless an exception applies
- [ ] `versionName` and `versionCode` match `pubspec.yaml` (or are derived from it)
- [ ] App name in `android/app/src/main/res/values/strings.xml` is correct

**Signing**
- [ ] Keystore file exists and is accessible (path documented in team password manager, not committed)
- [ ] Signing config in `build.gradle` references environment variables or CI secrets — no hardcoded paths
- [ ] You have tested the signed build locally: `flutter build appbundle --release`
- [ ] Keystore password and key password are stored in CI secrets

**Assets and Resources**
- [ ] Launcher icons set for all densities (mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)
- [ ] Adaptive icons configured for Android 8+ (foreground + background layers in `mipmap-anydpi-v26/`)
- [ ] No placeholder or debug app icon

**Permissions**
- [ ] `AndroidManifest.xml` permissions reviewed — only request what is actually used
- [ ] Removed any permissions from a previous feature that is no longer in this build
- [ ] Permissions with `maxSdkVersion` or `uses-permission-sdk-23` attributes reviewed

**Build**
- [ ] Clean build: `flutter clean && flutter pub get`
- [ ] Release AAB built: `flutter build appbundle --release --dart-define-from-file=.env.prod.json`
- [ ] AAB file size is within expected range (large spikes indicate an asset was accidentally included)
- [ ] ProGuard/R8 minification rules reviewed if enabled (`android/app/proguard-rules.pro`)
- [ ] `--obfuscate --split-debug-info=build/app/outputs/symbols` used if code obfuscation is enabled

**Play Store Metadata**
- [ ] Screenshots updated for this release (if UI changed)
- [ ] Store listing short description and full description up to date
- [ ] Privacy policy URL is live and accurate
- [ ] Content rating is current
- [ ] Target API level meets Google's current requirements
- [ ] Data safety section accurate for data this release collects
- [ ] Play Data Safety answers match the app's actual data collection, sharing, encryption, and deletion behavior

---

## iOS

**Owner:** [PLACEHOLDER — @username]

**App Identity**
- [ ] Bundle identifier in Xcode and `Info.plist` is the correct production ID
- [ ] `CFBundleShortVersionString` matches the version in `pubspec.yaml`
- [ ] `CFBundleVersion` (build number) matches `pubspec.yaml`
- [ ] App display name in `Info.plist` is correct

**Signing**
- [ ] Signing team and provisioning profile set in Xcode project settings
- [ ] Signing configuration uses automatic signing or CI-managed certificates — not committed developer certificates
- [ ] Certificates and provisioning profiles are valid and not expiring within 60 days
- [ ] Archive built without errors: `flutter build ios --release --dart-define-from-file=.env.prod.json`

**Assets**
- [ ] App icons set for all required sizes (use `flutter_launcher_icons` or Xcode asset catalog)
- [ ] No missing icon size (App Store will reject a build with a missing icon)
- [ ] Launch screen (`LaunchScreen.storyboard`) configured and matches brand

**Permissions (Info.plist)**
- [ ] Every `NS*UsageDescription` key has a clear, user-facing explanation (not a developer note)
- [ ] No permission keys present for entitlements not actually used in this build
- [ ] `PrivacyInfo.xcprivacy` present when required-reason APIs or third-party SDK requirements apply
- [ ] App Tracking Transparency (`NSUserTrackingUsageDescription`) included if any tracking used

**Dependencies**
- [ ] CocoaPods are up to date: `cd ios && pod install --repo-update`
- [ ] No deprecated CocoaPods or conflicting dependency versions
- [ ] `Podfile.lock` committed and matches current `Podfile`

**Build and Archive**
- [ ] `flutter clean` run before archive build
- [ ] Archive builds successfully in Xcode with no warnings treated as errors
- [ ] App validates in Xcode Organizer before uploading to App Store Connect
- [ ] Uploaded to App Store Connect and passes automated binary validation

**App Store Connect Metadata**
- [ ] Screenshots updated for relevant device sizes (6.7" and 12.9" required)
- [ ] App description accurate for this release
- [ ] What's New text written (visible on update prompt)
- [ ] Privacy nutrition labels accurate for data this release collects
- [ ] Age rating current
- [ ] Privacy policy URL is live

---

## Post-Release

- [ ] Monitor crash reporting dashboard for the first 24 hours after release
- [ ] Check Analytics for anomalous drop-off in core flows
- [ ] Pause or roll back staged rollout if crash-free sessions, ANRs, failed purchases, or core conversion cross the documented threshold
- [ ] Tag release in git: `git tag v[VERSION]` and push
- [ ] Archive this checklist in the release notes folder or attach to the release PR
- [ ] Close any release milestone in the issue tracker

---

**Sign-off**

| Role | Name | Date |
|------|------|------|
| Developer (Android) | [PLACEHOLDER] | [PLACEHOLDER] |
| Developer (iOS) | [PLACEHOLDER] | [PLACEHOLDER] |
| QA | [PLACEHOLDER] | [PLACEHOLDER] |
| Product | [PLACEHOLDER] | [PLACEHOLDER] |
