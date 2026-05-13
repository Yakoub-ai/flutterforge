---
description: "Debug a Flutter error or crash — paste your error/stack trace and get a root-cause fix."
argument-hint: <error description or paste error message>
allowed-tools: ["Read", "Glob", "Grep", "Bash", "Task", "Write", "Edit", "TodoWrite"]
---

You are running `/flutterforge:debug-flutter`.

Error input: $ARGUMENTS

---

## Phase 1: Error Classification (Claude directly — no agent)

Read `$ARGUMENTS`.

If `$ARGUMENTS` is empty, ask the user:
"Paste the full error message and stack trace, then re-run this command — or paste it now and I'll continue."
Stop until the user provides error content.

Classify the error into exactly one of these categories by reading the error text:

| Category | Indicators |
|---|---|
| `layout` | RenderFlex overflowed, BoxConstraints, incorrect use of Expanded, Flexible |
| `null-safety` | Null check operator used on a null value, LateInitializationError, Null is not a subtype |
| `async` | Bad state: Stream already listened to, StateError, Unhandled exception in Future, MissingPluginException on async |
| `state-management` | ProviderException, BlocUnhandledErrorException, StateNotifierListenError, used after dispose |
| `android-build` | Gradle, AGP, minSdk, compileSdk, Kotlin version, Could not resolve, FAILURE: Build failed |
| `ios-build` | CocoaPods, pod install, Xcode, signing, provisioning profile, dylib, framework not found |
| `firebase` | FirebaseException, failed to initialize, google-services.json, GoogleService-Info.plist missing |
| `test-failure` | Expected:, Actual:, package:test, FlutterError in widget test, matchesGoldenFile |
| `platform-channel` | MissingPluginException, PlatformException, MethodChannel, codec |
| `other` | Anything that does not match the above |

Print to the user:
```
Classified as: [category]
Launching flutter-debugger agent for root-cause analysis...
```

---

## Phase 2: Root-Cause Analysis (flutter-debugger agent)

Launch the `flutter-debugger` agent using the Task tool with this prompt:

---
You are acting as the Flutter Debugger for the FlutterForge `/flutterforge:debug-flutter` workflow.

[CONTEXT]:
Error category: [category from Phase 1]
Project root: current working directory

Full error text and stack trace (verbatim from user):
---
$ARGUMENTS
---

[YOUR TASK]:
Your goal is to identify the root cause and propose the minimal correct fix.

1. **Parse the stack trace.** Extract every file path mentioned. Prefer paths inside `lib/` — these are the app's own code. Ignore framework internals unless they clarify the cause.

2. **Read the relevant files.** For each `lib/` path found in the stack trace, read the file. Focus on the line numbers referenced. If no stack trace is available, use the error category and error text to infer which files to read (e.g. for a `layout` error, look for the widget described in the error).

3. **Trace the call chain.** Follow the error from its origin (deepest frame in app code) upward. Read any called methods or referenced classes that are not obvious.

4. **Apply category-specific checks:**
   - `layout`: Check if the widget with overflow is inside a Column/Row without Expanded/Flexible, or inside a scrollable without shrinkWrap.
   - `null-safety`: Find where the null value originates — is it an uninitialised field, a missing null check, or an async timing issue?
   - `async`: Check whether a Future's result is awaited, whether a stream is listened to more than once, or whether a controller is closed before use.
   - `state-management`: Check widget lifecycle — is a provider being read after its scope is disposed? Is a BLoC's stream closed before the widget unmounts?
   - `android-build`: Read android/app/build.gradle. Check AGP version compatibility with Gradle wrapper version. Read android/gradle/wrapper/gradle-wrapper.properties.
   - `ios-build`: Read ios/Podfile. Check deployment target. Check if `pod install` output shows version conflicts.
   - `firebase`: Check if Firebase.initializeApp() is called before runApp(). Check for missing google-services.json or GoogleService-Info.plist.
   - `test-failure`: Read the test file. Understand what it asserts. Check if the implementation changed without updating the test.
   - `platform-channel`: Check if the plugin is listed in pubspec.yaml. Check if platform-specific setup steps (AndroidManifest.xml, Info.plist) are complete.

5. **Propose a fix.** The fix must be minimal — change as few lines as possible. Do not refactor unrelated code. Show the fix as a before/after diff or a clear code block with the corrected lines.

6. **Provide validation commands.** List the exact shell commands the user should run to verify the fix worked.

[OUTPUT FORMAT]:
Return a structured report with:
- Status: DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
- Root cause: [one sentence — what went wrong and why]
- Affected file: [absolute path]
- Affected line(s): [line number(s) or range]
- Proposed fix: [code block with before/after or corrected snippet]
- Fix confidence: [High / Medium / Low — and why if not High]
- Validation commands: [shell commands to run]
- If NEEDS_CONTEXT: [what additional information is needed from the user]
---

After the agent returns:
- If the agent returns NEEDS_CONTEXT or BLOCKED, relay the missing information request to the user and stop until they respond. Then re-launch the agent with the additional context added.
- If fix confidence is Low, flag this to the user before applying.

---

## Phase 3: Fix Application (conditional on user approval)

Read the agent's proposed fix.

If the fix is a code change to one or more files:
- Show the diff or corrected code to the user with clear before/after formatting.
- Ask: "Apply this fix? Reply 'yes' to apply or 'no' to skip."
- **STOP.** Wait for user reply.

If the user approves:
1. Re-read each affected file immediately before editing (never edit from memory).
2. Apply the fix using the Edit tool with surgical precision — change only the lines identified.
3. Run validation:
   ```
   flutter analyze --no-fatal-infos
   ```
   If a specific test file is known from the stack trace, also run:
   ```
   flutter test [relevant-test-file]
   ```
4. Report the analyze and test results to the user.

If the fix is a configuration change (Gradle, Podfile, pubspec.yaml, plist):
- Show the exact change.
- Ask: "Apply this configuration change?"
- After applying, instruct the user to run the appropriate setup command (e.g. `flutter pub get`, `pod install`, `./gradlew clean`).

---

## Phase 4: Regression Test (flutter-test-engineer agent — optional)

Ask the user: "Write a regression test to prevent this bug from returning? (recommended for logic bugs — less critical for layout/build errors)"

If the user says yes or equivalent:

Launch the `flutter-test-engineer` agent using the Task tool with this prompt:

---
You are acting as the Flutter Test Engineer for the FlutterForge `/flutterforge:debug-flutter` regression prevention step.

[CONTEXT]:
Bug that was fixed: [paste the root cause sentence from Phase 2]
Affected file: [absolute path from Phase 2]
Error category: [from Phase 1]
Project root: current working directory

[YOUR TASK]:
Write a targeted test that would have caught this bug before it reached the user.

1. Read the affected file to understand what it does and what class/function was broken.
2. Read the test/ directory structure to find the right location for the new test file (mirror the lib/ path under test/).
3. Read one nearby existing test file to match style, imports, and mock setup conventions.
4. Write the regression test. It must:
   - Reproduce the exact condition that caused the bug.
   - Assert the correct behavior (not just "doesn't crash" — assert the expected value or state).
   - Use the project's existing mock/stub library (mockito, mocktail, or flutter_test only).
   - Be a single focused test, not a full test suite (though adding it to an existing test file is fine if one exists).

[OUTPUT FORMAT]:
Return a structured report with:
- Status: DONE | DONE_WITH_CONCERNS | BLOCKED
- Test file: [absolute path — existing file appended to, or new file created]
- Test name: [the string passed to test() or testWidgets()]
- What the test validates: [one sentence]
- Any assumptions made: [or "none"]
---

After the agent returns:
- Run `flutter test [test-file]` to verify the regression test passes with the fix applied.
- Report: test file location, test name, pass/fail result.
