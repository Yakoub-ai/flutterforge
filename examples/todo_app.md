# Recipe: To-Do App with Local Storage

## What We're Building

A clean, offline-first to-do app where users can create, complete, edit, and delete tasks. Tasks persist across app restarts using Hive (or Isar if you prefer SQL-style queries). The final app will have a task list screen, an add/edit bottom sheet, and swipe-to-delete — a solid foundation for any list-based Flutter app.

## Prerequisites

- Flutter 3.19+ and Dart on `PATH`
- FlutterForge plugin installed in Claude Code
- Android emulator or iOS simulator running
- No backend account needed — this app is fully local

---

## Step-by-Step Workflow

### Step 1 — Plan the App

```
/flutterforge:plan-flutter-app "I want to build an offline to-do app with task creation, editing, completion toggling, and swipe-to-delete. Tasks should persist locally across sessions. Clean Material 3 UI."
```

**What happens:** Three agents run in sequence. First the product-strategist agent reads your description and returns:

- A one-paragraph product brief
- 2–3 user personas (e.g., "Busy professional who manages daily tasks on their phone")
- 8–12 user stories in the format "As a [persona], I want to [action] so that [benefit]"
- A prioritized feature list: P0 (MVP), P1 (next release), P2 (future)

Then the UX designer and Flutter architect run in parallel. You receive:

- From the UX designer: a screen map (typically 2–3 screens for this app), key interaction patterns, and navigation flow in text/diagram form
- From the Flutter architect: a recommended tech stack, folder structure, state management choice (likely Riverpod or Bloc), and local storage recommendation (Hive vs Isar)

**Decision point:** The architect may suggest `flutter_bloc` for state management. If you prefer Riverpod, reply:

> "Please redesign the architecture using Riverpod with `AsyncNotifier` instead of Bloc."

The architect will revise the plan. Once you're happy with both outputs, confirm with:

> "Looks good, let's proceed."

---

### Step 2 — Scaffold the Project

```
/flutterforge:new-flutter-app
```

**What happens:** FlutterForge asks you two questions interactively:

1. **App name:** Enter something like `todo_local` (snake_case, valid Dart package name)
2. **Target directory:** Enter the full path, e.g., `C:\Projects\todo_local` or `~/projects/todo_local`

Three agents then run:

- The **Flutter architect** generates the complete folder structure, `pubspec.yaml` dependencies, and initial configuration files
- The **Flutter engineer** scaffolds all the boilerplate: `main.dart`, theme setup, router, and empty feature modules
- The **Test engineer** creates the test directory structure and a basic smoke test to confirm the app boots

**What you get:** A runnable Flutter project. Verify it by running:

```bash
cd ~/projects/todo_local
flutter run
```

You should see a blank Material 3 scaffold with your app name in the title bar. If it compiles and runs, you're ready to build features.

---

### Step 3 — Build the Task List Feature

```
/flutterforge:build-flutter-feature "Task list screen that displays all tasks from local Hive storage. Each task shows its title, a checkbox to toggle completion, and a delete button. Completed tasks are visually distinguished (strikethrough). List is empty-state friendly."
```

**What happens:** Five phases run, with an approval gate after Phase 2:

- **Phase 1 (Inspect):** The agent reads your existing codebase to understand the current folder structure, existing imports, and theme setup. It reports what it found.
- **Phase 2 (Plan):** A detailed implementation plan is shown to you: which files will be created, which modified, what the `Task` model looks like, how Hive boxes are initialized. Review this carefully.

**Approval gate:** Reply `"go"` to proceed, or ask for changes. For example:

> "Use `Isar` instead of Hive for storage — I want typed queries later."

The agent will revise the plan. Once approved:

- **Phase 3 (Implement):** Files are written — the `Task` model with Hive adapters, the Hive initialization in `main.dart`, the task list widget, and the Riverpod providers.
- **Phase 4 (Test):** Unit tests for the `Task` model and widget tests for the task list are generated and run.
- **Phase 5 (Validate):** The agent does a final pass — checks for unused imports, verifies the Hive adapter is registered, confirms the empty state widget renders.

Run the app and verify the task list loads, shows an empty state, and the UI matches what you planned.

---

### Step 4 — Build the Add/Edit Task Feature

```
/flutterforge:build-flutter-feature "Add and edit task bottom sheet. Tapping a FAB opens a bottom sheet with a text field for the task title. Submitting creates a new task. Tapping an existing task opens the same sheet pre-populated for editing. Validation: title cannot be empty."
```

**What happens:** Same 5-phase flow as Step 3. The agent inspects your existing task list screen and Riverpod providers, then plans the bottom sheet implementation using the same patterns already established.

**Decision point:** The plan may propose using `showModalBottomSheet` directly. If you want a reusable `TaskFormSheet` widget that can be tested in isolation, tell the agent:

> "Extract the bottom sheet content into a separate `TaskFormSheet` widget with a callback for onSubmit."

After implementation, manually test:
- FAB opens an empty sheet
- Typing a title and tapping Save creates the task in the list
- Tapping an existing task pre-fills the sheet
- Tapping Save on an existing task updates it in place
- Attempting to save with an empty title shows a validation error

---

### Step 5 — Add Swipe-to-Delete

```
/flutterforge:build-flutter-feature "Swipe-to-delete on task list items using Dismissible widget. Swiping left reveals a red delete background with a trash icon. Completing the swipe deletes the task from Hive. Add an undo snackbar that appears for 3 seconds and restores the task if tapped."
```

**What happens:** The agent inspects the existing task list widget and wraps the list items with `Dismissible`. It also adds the snackbar logic using `ScaffoldMessenger`.

After implementation, test on a real device or emulator — swipe behavior on simulator can feel different from physical devices.

---

### Step 6 — Generate Tests

```
/flutterforge:generate-tests "Full coverage for the todo app: Task model serialization, Riverpod provider state transitions (add, toggle, delete, edit), and widget tests for TaskListScreen and TaskFormSheet."
```

**What happens:** The test engineer audits existing tests and fills the gaps. Expect 15–25 new test cases across unit and widget tests.

Run the full suite:

```bash
flutter test
```

All tests should pass before moving on. If any fail, the agent will explain why and fix them.

---

### Step 7 — UX Polish

```
/flutterforge:improve-ux "task list and form"
```

**What happens:** The UX agent reviews the task list screen and form sheet. It typically returns:

- Accessibility audit (tap target sizes, missing semantic labels)
- Animation suggestions (hero transitions, fade-in for new tasks)
- Typography and spacing recommendations based on Material 3 guidelines
- Empty state improvements

Review the suggestions and reply with which ones to implement. For a simple to-do app, prioritize the accessibility fixes and empty state — skip complex animations for now.

---

### Step 8 — Final Audit

```
/flutterforge:audit-flutter-app
```

**What happens:** Five agents run in parallel and produce a combined report:

- **Codebase auditor:** Dead code, unused dependencies in `pubspec.yaml`, file organization
- **Security reviewer:** No significant concerns for a local-only app; may flag hardcoded strings
- **Performance engineer:** Checks for unnecessary rebuilds in the Riverpod providers, widget const constructors
- **Test engineer:** Coverage gaps
- **Release engineer:** App icon, display name, version in `pubspec.yaml`, debug logging left in

Work through the report item by item. For a first release, focus on the release engineer's checklist.

---

### Step 9 — Prepare for Release

```
/flutterforge:prepare-release
```

**What happens:** The release agent walks you through the Android and iOS release checklists:

- App icon (requires you to provide a 1024x1024 PNG)
- Splash screen
- Version and build number in `pubspec.yaml`
- Android: keystore setup, `build.gradle` signing config, Play Store metadata
- iOS: Xcode signing, bundle ID, `Info.plist` review, App Store metadata

The agent generates the checklist but **you must complete the platform-specific steps manually** (keystore generation, Xcode signing). Follow each item in order.

---

## Tips for This App Type

**Hive vs Isar:** Hive is simpler to set up and sufficient for flat lists. Choose Isar if you plan to add filtering, sorting by multiple fields, or relations (e.g., tasks with subtasks or tags).

**Hive adapter regeneration:** Any time you change a `@HiveType` model, re-run:
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```
Forgetting this is the most common Hive gotcha.

**Riverpod `invalidate` vs `state =`:** For list state, prefer mutating through a `Notifier` method rather than reassigning `state` directly — it gives you finer control and makes testing easier.

**Testing local storage:** In widget tests, use an in-memory Hive box rather than a real file. The test engineer agent handles this automatically when it sees Hive in your stack.

**Undo snackbar timing:** 3 seconds is standard on Android. On iOS, users expect undo via shake — if you want to follow platform conventions, tell the UX agent to implement platform-specific undo behavior.
