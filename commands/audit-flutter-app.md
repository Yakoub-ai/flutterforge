---
description: "Audit an existing Flutter app for architecture quality, security, performance, test coverage, and release readiness."
argument-hint: [--focus architecture|security|performance|tests|release]
allowed-tools: ["Read", "Glob", "Grep", "Bash", "Task", "Write", "TodoWrite"]
---

You are running `/flutterforge:audit-flutter-app`.

Focus filter (optional): $ARGUMENTS

---

## Phase 1: Project Verification (Claude directly — no agent)

Check that this is a Flutter project by looking for `pubspec.yaml` in the current directory. If it does not exist, tell the user: "No pubspec.yaml found in the current directory. Run this command from the Flutter project root." and stop.

Read `pubspec.yaml` and extract:
- App name (the `name:` field)
- Flutter SDK constraint (`sdk:` under `environment:`)
- Key dependencies: state management, HTTP, navigation, Firebase packages, any notable third-party libs

If `$ARGUMENTS` contains `--focus`, note which single domain was requested. The 5-agent phase will still launch all 5 agents but the final report will highlight the focused domain.

Print to the user:
```
Auditing [app-name] — launching 5 specialist agents in parallel...
Flutter SDK: [version constraint]
Key dependencies: [comma-separated list]
```

---

## Phase 2: Parallel Audit (all 5 agents — dispatch in a SINGLE message)

**IMPORTANT: Launch all 5 agents simultaneously by making all 5 Task tool calls in one message. Do not wait for one agent before dispatching the next.**

---

Launch the `codebase-auditor` agent using the Task tool with this prompt:

---
You are acting as the Codebase Auditor for the FlutterForge `/flutterforge:audit-flutter-app` workflow.

[CONTEXT]:
Project root: current working directory
Goal: Architecture audit

[YOUR TASK]:
1. List the full lib/ folder structure using Glob. Identify the architecture pattern: feature-first, layer-first, clean architecture, or ad-hoc.
2. Read pubspec.yaml. Assess dependency health: flag outdated patterns, missing standard libs, or conflicting concerns.
3. Grep for scattered `setState` calls across files outside of StatefulWidget build methods to detect improper state management.
4. Grep for `Navigator.push` and `Navigator.pushNamed` to assess navigation consistency.
5. Find all .dart files in lib/ over 300 lines using Bash: `Get-ChildItem -Recurse -Filter *.dart lib/ | Where-Object { (Get-Content $_.FullName | Measure-Object -Line).Lines -gt 300 } | Select-Object Name, FullName` (Windows) or `find lib/ -name "*.dart" | xargs wc -l | awk '$1>300' | sort -rn` (Unix).
6. Check for a single consistent state management approach or multiple competing ones.
7. Check for barrel files (index.dart) as an indicator of intentional architecture.

[OUTPUT FORMAT]:
Return a structured report with:
- Status: DONE | DONE_WITH_CONCERNS | BLOCKED
- Architecture score: [1–5, where 5 = excellent]
- Detected pattern: [feature-first / layer-first / clean / ad-hoc / mixed]
- State management consistency: [consistent / mixed / unclear]
- Top 3 architecture risks: [numbered list]
- Files with issues: [list of absolute paths with one-line note each]
- Dependency health notes: [bullet list or "no issues found"]
---

Launch the `mobile-security-reviewer` agent using the Task tool with this prompt:

---
You are acting as the Mobile Security Reviewer for the FlutterForge `/flutterforge:audit-flutter-app` workflow.

[CONTEXT]:
Project root: current working directory
Goal: Security scan

[YOUR TASK]:
1. Grep for hardcoded secrets: API keys, tokens, passwords. Patterns to search: `api_key`, `apiKey`, `secret`, `password`, `token`, `Bearer `, `sk-`, `pk_live`, `AIza`.
2. Grep for `http://` (non-TLS) URLs in Dart files.
3. Read `android/app/src/main/AndroidManifest.xml` if it exists. Flag: INTERNET permission (expected), any `android:usesCleartextTraffic="true"`, exported activities/services without explicit intent filters.
4. Read `ios/Runner/Info.plist` if it exists. Flag: `NSAllowsArbitraryLoads` in ATS, overly broad permission descriptions (camera, location, contacts without justification in the description string).
5. Grep for `SharedPreferences` or `NSUserDefaults` usage that stores tokens or user PII (common insecure storage pattern).
6. Grep for `debugPrint`, `print(`, `log(` calls that may leak sensitive data in release builds.
7. Check if `flutter_secure_storage` is in pubspec.yaml — its absence when the app stores credentials is a finding.

[OUTPUT FORMAT]:
Return a structured report with:
- Status: DONE | DONE_WITH_CONCERNS | BLOCKED
- Security findings table: [finding | severity (Critical/High/Medium/Low) | file/location]
- Top 3 security risks: [numbered list]
- Secrets found: [list or "none detected"]
- ATS/cleartext issues: [description or "none"]
- Storage pattern assessment: [secure / insecure / not applicable]
---

Launch the `mobile-performance-engineer` agent using the Task tool with this prompt:

---
You are acting as the Mobile Performance Engineer for the FlutterForge `/flutterforge:audit-flutter-app` workflow.

[CONTEXT]:
Project root: current working directory
Goal: Performance scan

[YOUR TASK]:
1. Grep for `ListView(` without `.builder` — these build all children at once and are problematic for long lists.
2. Grep for widget constructors that could be `const` but are not: look for `Text(`, `Icon(`, `SizedBox(`, `Padding(`, `Container(` without the `const` keyword.
3. Grep for `Image.network(` without explicit `width:` and `height:` — causes layout thrashing.
4. Grep for `StreamSubscription` declarations. For each, check whether the enclosing class has a `dispose()` method that calls `.cancel()`. Flag any that don't.
5. Grep for `build()` method bodies over 60 lines — these indicate widgets that should be decomposed.
6. Grep for `await Future.delayed` in production code (test/debug smell).
7. Check if `cached_network_image` or similar caching lib is in pubspec.yaml when `Image.network` is used.

[OUTPUT FORMAT]:
Return a structured report with:
- Status: DONE | DONE_WITH_CONCERNS | BLOCKED
- Performance findings: [finding | impact (High/Medium/Low) | file/location]
- Top 3 performance risks: [numbered list]
- Missing const constructors: [count and sample locations]
- Unmanaged StreamSubscriptions: [list of files or "none found"]
- ListView rebuild risk: [number of unsafe ListView usages]
---

Launch the `flutter-test-engineer` agent using the Task tool with this prompt:

---
You are acting as the Flutter Test Engineer for the FlutterForge `/flutterforge:audit-flutter-app` workflow.

[CONTEXT]:
Project root: current working directory
Goal: Test coverage signal (read-only analysis — do not write any tests)

[YOUR TASK]:
1. Count all .dart source files in lib/ (excluding generated files: *.g.dart, *.freezed.dart).
2. Count all test files in test/ (files ending in _test.dart).
3. Identify which test types are present: unit tests, widget tests (look for `testWidgets`), integration tests (check integration_test/ directory), golden tests (look for `matchesGoldenFile`).
4. For each file in lib/features/ (or lib/ if no features dir), check whether a corresponding _test.dart exists in test/.
5. Find files with significant logic (grep for `class.*Repository`, `class.*Bloc`, `class.*Notifier`, `class.*Provider`) that have no corresponding test file.
6. Check pubspec.yaml dev_dependencies for: mockito, mocktail, bloc_test — note which testing utilities are available.

[OUTPUT FORMAT]:
Return a structured report with:
- Status: DONE | DONE_WITH_CONCERNS | BLOCKED
- Source file count: [number, excluding generated]
- Test file count: [number]
- Test-to-source ratio: [percentage]
- Test types present: [unit / widget / integration / golden — list what is found]
- Critical untested files: [list of absolute paths — repositories, blocs, notifiers with no tests]
- Testing utilities available: [mockito / mocktail / bloc_test / none]
- Overall test coverage signal: [Excellent (>80%) / Good (50–80%) / Poor (20–50%) / Critical (<20%)]
---

Launch the `release-engineer` agent using the Task tool with this prompt:

---
You are acting as the Release Engineer for the FlutterForge `/flutterforge:audit-flutter-app` workflow.

[CONTEXT]:
Project root: current working directory
Goal: Release readiness check

[YOUR TASK]:
1. Read pubspec.yaml. Check: version field format is `x.y.z+build` (e.g. `1.0.0+1`), name does not contain `example` or `template`.
2. Read `android/app/build.gradle` or `android/app/build.gradle.kts` if present. Check: `applicationId` is not `com.example.*`, minSdkVersion is set, targetSdkVersion is recent (31+).
3. Read `ios/Runner/Info.plist` if present. Check: `CFBundleIdentifier` is not `com.example.*`, `CFBundleDisplayName` is set.
4. Check for app icons: `android/app/src/main/res/mipmap-*/ic_launcher.png` (should exist in multiple densities), `ios/Runner/Assets.xcassets/AppIcon.appiconset/` (should have Contents.json).
5. Grep for `com.example` in all Gradle and plist files.
6. Read `android/key.properties` or check for signing documentation in any README or docs/ file. Note if signing is configured or documented.
7. Check for `flutter_launcher_icons` or `flutter_native_splash` in pubspec.yaml as indicators of launch asset configuration.

[OUTPUT FORMAT]:
Return a structured report with:
- Status: DONE | DONE_WITH_CONCERNS | BLOCKED
- Release readiness score: [1–5, where 5 = ship-ready]
- Version format: [valid / invalid / missing]
- Application ID status: [custom / still com.example (BLOCKER) / not found]
- Bundle identifier status (iOS): [custom / still com.example (BLOCKER) / not found]
- App icons: [configured / missing / partial]
- Signing: [documented / configured / not found]
- Blockers: [numbered list of must-fix items before release, or "none"]
---

---

## Phase 3: Consolidated Report (Claude synthesizes — wait for all 5 agents)

Wait for all 5 agent reports to complete. Then produce the following consolidated output.

**Executive Summary** (3 sentences):
1. Overall health of the app based on all 5 domain scores.
2. The single biggest risk identified across all audits.
3. The recommended first action to take.

**Domain Scorecard Table:**

| Domain | Score | Top Risk |
|---|---|---|
| Architecture | [1–5 from codebase-auditor] | [top risk] |
| Security | [severity from mobile-security-reviewer] | [top risk] |
| Performance | [from mobile-performance-engineer] | [top risk] |
| Test Coverage | [signal from flutter-test-engineer] | [top gap] |
| Release Readiness | [1–5 from release-engineer] | [top blocker] |

**Prioritized Action Plan:**

P0 — Blockers (fix before next release):
[Items from any agent marked Critical severity, release blockers, or security findings rated High+]

P1 — Important (fix in next sprint):
[Architecture risks, Medium security findings, performance issues affecting user experience]

P2 — Improvements (address when convenient):
[Low-severity findings, test coverage gaps for non-critical code, code style issues]

Save the full report to `docs/audit/app_audit_[YYYY-MM-DD].md` (create the directory if needed, use today's date).

Print to the user:
```
Audit complete. Report saved to docs/audit/app_audit_[date].md

Recommended first command to run:
  [suggest the most relevant FlutterForge command based on the P0 items]
  e.g. /flutterforge:generate-tests  — if test coverage is the primary P0
       /flutterforge:debug-flutter    — if a specific critical bug was surfaced
       /flutterforge:build-flutter-feature <security fix>  — if security is P0
```
