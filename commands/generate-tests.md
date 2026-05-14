---
description: "Generate Flutter tests — unit, widget, integration — for a file, feature, or whole project."
argument-hint: <file path, feature name, or 'all'>
allowed-tools: ["Read", "Glob", "Grep", "Bash", "Task", "Write", "Edit", "TodoWrite"]
---

You are running `/flutterforge:generate-tests`.

Scope input: $ARGUMENTS

---

## Phase 1: Scope Determination (Claude directly — no agent)

Parse `$ARGUMENTS` to determine the test generation scope:

**If `$ARGUMENTS` is a file path** (contains `/` or `\`, or ends in `.dart`):
- Verify the file exists. If not, tell the user "File not found: [path]" and stop.
- Read the file to understand what it contains (class types, state management, dependencies).
- Scope = that single file.

**If `$ARGUMENTS` is a feature name** (no path separators, not `all`, not empty):
- Glob for `lib/**/*[feature-name]*.dart` and `lib/features/[feature-name]/**/*.dart`.
- List the matched files.
- If no matches: ask the user "No files matched '[feature-name]'. Try a different name or provide a file path."
- Scope = all matched files.

**If `$ARGUMENTS` is `all` or empty**:
- Find all `.dart` files in `lib/` excluding generated files (`*.g.dart`, `*.freezed.dart`, `*.mocks.dart`).
- For each, check whether a corresponding `_test.dart` exists in `test/` at the mirrored path.
- Scope = files in `lib/` with no matching test file.

**Display the scope to the user:**
```
Generating tests for [N file(s)]:
  [list each file, one per line]
```

**If scope is more than 10 files**, stop and ask:
"That's [N] files — generating tests for all at once may produce large output. Options:
  1. Proceed with all [N] files
  2. Start with the highest-priority files (repositories, blocs, notifiers — recommended)
  3. Narrow scope: provide a feature name or specific file path

Reply with 1, 2, or 3 (or a revised scope)."

If the user selects option 2: filter the scope to only files matching `*Repository*`, `*Bloc*`, `*Notifier*`, `*Provider*`, `*UseCase*`, `*Service*`.

**Wait for user confirmation if scope > 10 files.** Otherwise proceed immediately.

**Before launching the agent**, gather supporting context:
- Read `pubspec.yaml` to detect state management library (look for `flutter_riverpod`, `riverpod`, `bloc`, `flutter_bloc`, `provider`, `mobx`).
- Read `pubspec.yaml` dev_dependencies to detect test utilities: `mockito`, `mocktail`, `bloc_test`, `golden_toolkit`.
- Find and read one existing test file from the `test/` directory to capture naming conventions, import patterns, and mock setup style. Prefer a test file for a similar type (e.g. if testing a repository, find an existing repository test).

---

## Phase 2: Test Generation (flutter-test-engineer agent)

Launch the `flutter-test-engineer` agent using the Task tool with this prompt:

---
You are acting as the Flutter Test Engineer for the FlutterForge `/flutterforge:generate-tests` workflow.

[CONTEXT]:
Project root: current working directory
State management library: [from Phase 1 pubspec.yaml analysis]
Test utilities available: [mockito / mocktail / bloc_test / none — from Phase 1]

Files to test:
[List each file from Phase 1 scope with its absolute path. For each file with ≤150 lines, paste the full file content inline. For larger files, paste the class signatures, public method signatures, and any state/event definitions only.]

Existing test pattern reference (read this carefully and match its style):
[Paste the full content of the existing test file found in Phase 1]

[YOUR TASK]:
For each file in the list above, generate comprehensive tests. Follow this process per file:

**Step 1 — Determine test type:**
- File contains business logic, data transformation, or I/O (repository, use case, service, data source) → **unit test**
- File contains a Widget class → **widget test**
- File contains a StateNotifier, Cubit, Bloc, ChangeNotifier, or similar → **state/BLoC test**

**Step 2 — Identify what to test:**
- Every public method must have at minimum: one happy-path test and one error/edge-case test.
- For widgets: test each meaningful UI state (loading, error, empty, populated). Test at least one user interaction (tap, input, scroll) if any exist.
- For state classes: test each state transition and each event/action handler.

**Step 3 — Write the tests:**
- Place each test file at `test/[mirror-of-lib-path]_test.dart`. Example: `lib/features/auth/data/auth_repository.dart` → `test/features/auth/data/auth_repository_test.dart`.
- Match import style, group() nesting, and setUp() patterns from the reference test file exactly.
- Use the project's mock library. Prefer mocktail; if neither mocktail nor mockito is present, ask before adding a test dependency. Generate mock classes for any dependencies injected via constructor.
- Do NOT use `any()` from mockito if mocktail is the library — use `any()` from mocktail.
- Coverage targets: repositories and use cases → aim for 90% method coverage; blocs/notifiers → cover all state transitions; widgets → cover key states, not every pixel.

**Step 4 — Write the files:**
Write each test file. After writing, run `dart format [test-file-path]` on it.

[OUTPUT FORMAT]:
Return a structured report with:
- Status: DONE | DONE_WITH_CONCERNS | BLOCKED
- Test files written: [list of absolute paths]
- Per-file summary: [file tested → test file → number of test() calls → types covered]
- Total test count: [number]
- Coverage gaps noted: [list of methods or behaviors not tested and why — or "none"]
- Any files skipped and reason: [or "none"]
- dart format ran: yes/no
---

After the agent returns:
- If the agent returns BLOCKED or NEEDS_CONTEXT, relay the concern to the user and stop until resolved. Then re-launch with the additional information.

---

## Phase 3: Validation and Report

Run the tests that were just generated:

```
flutter test [list each test file written — space-separated]
```

Capture the full output.

**If all tests pass:**
Print to the user:
```
FlutterForge: Test generation complete.

Tests written: [total count] tests across [N] files
  [list each test file with its test count]

flutter test: PASSED [N/N]

Coverage improvement: [estimate — e.g. "6 previously untested files now have tests"]
Remaining gaps: [list files still without tests, if any, or "none"]

Next steps:
  /flutterforge:audit-flutter-app   — run a full audit to see overall test coverage signal
  /flutterforge:build-flutter-feature <feature>  — the test scaffold is ready for your next feature
```

**If any tests fail:**
Show the failing test names and their error output. Ask:
"Fix the failing tests? The test agent may have made assumptions about your data structures or mock setup. Reply 'yes' to send the failures back for correction, or 'no' to leave the test files for manual review."

If the user says yes:

Launch the `flutter-test-engineer` agent using the Task tool with this prompt:

---
You are acting as the Flutter Test Engineer for the FlutterForge `/flutterforge:generate-tests` fix-up step.

[CONTEXT]:
Project root: current working directory
State management: [from Phase 1]
Test utilities: [from Phase 1]

[YOUR TASK]:
The tests you wrote have failures. Fix them.

Failing test output:
[Paste the full flutter test failure output here]

Test files with failures:
[List the absolute paths of test files that failed]

Read each failing test file. Read the corresponding source file being tested. Understand the mismatch between the test's assumptions and the actual code. Apply the minimal fix to the test — do not change the source file being tested.

Common failure causes to check:
- Mock setup missing a `when()` stub for a method that gets called
- Wrong type passed to a mock method
- Widget test missing a required ancestor widget (e.g. MaterialApp, ProviderScope)
- Async test missing `await tester.pumpAndSettle()`
- Constructor arguments changed in source but not updated in test

[OUTPUT FORMAT]:
Return a structured report with:
- Status: DONE | DONE_WITH_CONCERNS | BLOCKED
- Files fixed: [list of absolute paths]
- Changes made: [per-file description of what was wrong and what was changed]
- Remaining known issues: [or "none"]
---

After the fix agent returns:
- Re-run `flutter test [test files]` and report the final pass/fail count.
- If tests still fail after the fix attempt, list the remaining failures and say: "Manual review needed for these tests — the implementation may have patterns the agent could not fully infer."
