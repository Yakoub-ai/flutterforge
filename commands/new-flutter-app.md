---
description: "Scaffold a new Flutter project with production-ready structure, dependencies, architecture, and baseline tests."
argument-hint: "[app-name] [--android-only | --ios-only]"
allowed-tools: ["Read", "Glob", "Grep", "Bash", "Task", "Write", "Edit", "TodoWrite"]
---

You are running `/flutterforge:new-flutter-app`.

Raw arguments: $ARGUMENTS

---

## Phase 1: Environment Validation and Input Collection (no agent — Claude does this directly)

Run the following shell command and report the output to the user:

```
flutter --version
```

If the command fails or Flutter is not found, stop and say: "Flutter SDK is not installed or not on PATH. Install it from https://docs.flutter.dev/get-started/install and re-run this command."

**Determine the app name:**
- If `$ARGUMENTS` contains a word that looks like an app name (e.g. `my_app`, `todo_list`), use it.
- If `$ARGUMENTS` is empty or ambiguous, ask: "What should the app be named? Use snake_case (e.g. my_todo_app)." Stop until the user replies.

**Determine production identifiers:**
- Ask the user for the reverse-domain organization identifier, e.g. `com.examplecompany`. Do not derive it from the app name.
- Ask for the display name users will see under the app icon, e.g. `My Todo`.
- If the user does not know yet, use `com.example` only for local prototypes and mark it as a release blocker in the final summary.

**Determine the target platform:**
- If `$ARGUMENTS` contains `--android-only`, set platforms to `--platforms android`.
- If `$ARGUMENTS` contains `--ios-only`, set platforms to `--platforms ios`.
- Otherwise, default to no platform flag (all platforms).

**Determine the target directory:**
Ask the user: "Where should the project be created? Provide the full path to the parent directory (e.g. C:\Dev or /home/user/projects)."
Stop until the user replies with a path.

**Confirm before running:**
Print: "I'll create a Flutter project named `[app-name]` at `[path]/[app-name]`. The flutter create command I'll run is:

```
flutter create --org [reverse-domain-org] --project-name [app-name] --template app [platform-flag] [app-name]
```

Reply 'yes' to proceed."

**STOP.** Wait for user confirmation before running any shell command.

After approval, run the flutter create command in the specified parent directory. Report success or any errors.

---

## Phase 2: Architecture Setup

Launch the `flutter-architect` agent using the Task tool with this prompt:

---
You are acting as the Flutter Architect for the FlutterForge `/flutterforge:new-flutter-app` workflow.

[CONTEXT]:
App name: [app-name from Phase 1]
Display name: [display name from Phase 1]
Reverse-domain org: [reverse-domain-org from Phase 1]
Project path: [full absolute path to the newly created project]
Planning docs available: Check if docs/architecture/technical_plan.md, docs/architecture/folder_structure.md, and docs/product/app_brief.md exist in the current working directory. If they exist, read them and use them to guide decisions. If they do not exist, proceed with sensible defaults (feature-first architecture, Riverpod for state, go_router for navigation).

[YOUR TASK]:
1. Read the project's pubspec.yaml.
2. Produce a list of dependencies to add (name, version, and one-line justification for each). Query pub-dev MCP before pinning versions. Include at minimum: go_router, flutter_riverpod, riverpod_annotation, dio, flutter_secure_storage, freezed_annotation, json_annotation in dependencies; and build_runner, riverpod_generator, freezed, json_serializable, very_good_analysis, mocktail in dev_dependencies.
3. Produce the full folder structure to create under lib/. Return it as a JSON array of relative paths (e.g. ["lib/app", "lib/core/errors", "lib/features/home/data"]).
4. Write docs/architecture/scaffold_decisions.md documenting the dependencies chosen and folder structure rationale. Create the docs/architecture/ directory if needed.

Do NOT modify pubspec.yaml or create any files other than scaffold_decisions.md — return the dependency list and folder paths in your report for the main session to apply.

[OUTPUT FORMAT]:
Return a structured report with:
- Status: DONE | DONE_WITH_CONCERNS | BLOCKED
- Dependencies to add (yaml-formatted block ready to paste into pubspec.yaml under `dependencies:`):
- Dev dependencies to add (yaml-formatted block ready to paste under `dev_dependencies:`):
- Folders to create: [JSON array of relative paths from project root]
- scaffold_decisions.md written: yes/no
- Any concerns or assumptions
---

After the agent returns:
- Open `[project-path]/pubspec.yaml` and add the dependencies and dev_dependencies exactly as specified by the agent. Re-read the file before editing. Do not remove any existing entries.
- Create each folder in the returned folder list. Create a `.gitkeep` file in empty leaf directories so git tracks them.
- Run `flutter pub get` in the project directory and report the result.

---

## Phase 3: Implementation Scaffold

Launch the `flutter-implementation-engineer` agent using the Task tool with this prompt:

---
You are acting as the Flutter Implementation Engineer for the FlutterForge `/flutterforge:new-flutter-app` workflow.

[CONTEXT]:
Project path: [full absolute path to project]
App name: [app-name]
Display name: [display name]
Architecture decisions: [paste the full content of scaffold_decisions.md here, or summarize the pattern, state management, and navigation choices from Phase 2]
Dependencies added: [list the key dependencies from Phase 2]

[YOUR TASK]:
Create the following files in the project. Each file should be minimal but correct — real imports, no placeholder comments like "// TODO implement", valid Dart syntax.

Files to create:
1. `lib/main.dart` — Entry point. Calls `runApp(const ProviderScope(child: App()))`.
2. `lib/app/app.dart` — Root app widget. Creates `MaterialApp.router` with go_router and applies AppTheme. Do not wrap this widget in ProviderScope because `main.dart` owns the app-level scope.
3. `lib/app/router.dart` — go_router configuration with at least one route (the home screen). Export the router instance.
4. `lib/app/theme/app_theme.dart` — ThemeData for light and dark themes using Material 3. Export AppTheme class with static lightTheme and darkTheme getters.
5. `lib/core/errors/app_exception.dart` — Base AppException hierarchy using Dart sealed classes, no generated code.
6. `lib/core/network/network_client.dart` — Dio-based NetworkClient class with base options (baseUrl from `const String.fromEnvironment('API_BASE_URL')`, connect/receive timeouts).
7. `analysis_options.yaml` — Include `package:very_good_analysis/analysis_options.yaml` and only add local rule overrides when needed.
8. `.env.example` — Template env file with: APP_ENV=development, API_BASE_URL=https://api.example.com, API_TIMEOUT_SECONDS=30.

After writing each file, run `dart format [file-path]` to format it.

[OUTPUT FORMAT]:
Return a structured report with:
- Status: DONE | DONE_WITH_CONCERNS | BLOCKED
- Files created: [list of absolute paths]
- Any files skipped and why
- Any syntax issues encountered
- Dart format ran: yes/no
---

After the agent returns:
- Run `dart format .` in the project directory.
- Run `flutter pub get` to ensure new code doesn't break resolution.
- Report any errors.

---

## Phase 4: Baseline Tests and Final Validation

Launch the `flutter-test-engineer` agent using the Task tool with this prompt:

---
You are acting as the Flutter Test Engineer for the FlutterForge `/flutterforge:new-flutter-app` workflow.

[CONTEXT]:
Project path: [full absolute path to project]
App name: [app-name]
Root widget: defined in lib/app/app.dart, class name follows Flutter convention (e.g. MyApp or [AppName]App).

[YOUR TASK]:
Write a baseline widget test at `test/widget_test.dart`. The test must:
1. Import the root app widget from lib/app/app.dart.
2. Wrap it in a ProviderScope because `main.dart` owns ProviderScope in production and tests pump the root widget directly.
3. Assert that the app renders without throwing (use pumpWidget + pumpAndSettle).
4. Include one named test: 'App widget renders without errors'.

Replace any existing content in test/widget_test.dart.

[OUTPUT FORMAT]:
Return a structured report with:
- Status: DONE | DONE_WITH_CONCERNS | BLOCKED
- test/widget_test.dart written: yes/no
- Test names written: [list]
- Any concerns about the root widget setup
---

After the agent returns:
- Run `flutter analyze --no-fatal-infos` in the project directory. Record any errors (not warnings).
- Run `flutter test` in the project directory. Record pass/fail.
- Run `flutter build apk --debug --no-pub` (skip if `--ios-only` was specified) to verify the project compiles.
- If any `@riverpod`, `@freezed`, or `@JsonSerializable` annotations were created, run `dart run build_runner build --delete-conflicting-outputs` before analyze/test.

**Final summary — print to the user:**

```
FlutterForge: Project scaffolded successfully.

Project: [app-name]
Location: [full path]
Architecture: [pattern from Phase 2]
State management: [library]
Navigation: go_router

Files created:
  [list all files created across phases]

Commands to get started:
  cd [project-path]
  flutter run

Next steps:
  /flutterforge:build-flutter-feature <feature name>   — add your first feature
  /flutterforge:plan-flutter-app <idea>                — plan before building (if not done)
```

If `flutter analyze` or `flutter test` reported errors, list them here and say: "Resolve these before running the app."
