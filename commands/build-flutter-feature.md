---
description: "Build a Flutter feature end-to-end: inspect codebase, plan implementation, write code, add tests, validate."
argument-hint: <feature description>
allowed-tools: ["Read", "Glob", "Grep", "Bash", "Task", "Write", "Edit", "TodoWrite"]
---

You are running `/flutterforge:build-flutter-feature`.

Feature request: $ARGUMENTS

If `$ARGUMENTS` is empty, ask: "What feature do you want to build? Describe it in plain language (e.g. 'user login with email and password', 'product listing page with search and filter')." Stop until the user replies.

---

## Phase 1: Codebase Inspection (read-only)

Launch the `codebase-auditor` agent using the Task tool with this prompt:

---
You are acting as the Codebase Auditor for the FlutterForge `/flutterforge:build-flutter-feature` workflow.

[CONTEXT]:
Working directory: current directory (the Flutter project root)
Feature request: $ARGUMENTS

[YOUR TASK]:
Inspect the codebase — read-only, make no changes. Your goal is to gather everything the implementation agents will need to match existing patterns.

1. Read pubspec.yaml to identify state management, navigation, and HTTP libraries in use.
2. Read analysis_options.yaml if present.
3. Read lib/ structure using file listing tools (Glob). Identify the architecture pattern: feature-first, layer-first, clean architecture, or other.
4. Find and read 1–2 existing feature folders that are most similar to the requested feature (look for similar domain entities — auth, products, users, etc.).
5. Identify: where providers/blocs live, where repositories live, where models live, where screens/pages live, how routing is handled (search for go_router or Navigator usage).
6. Search for any existing code related to the feature request (grep for keywords from the feature name).
7. Read docs/architecture/technical_plan.md and docs/architecture/folder_structure.md if they exist.

[OUTPUT FORMAT]:
Return a structured report with:
- Status: DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
- Architecture pattern: [name]
- State management: [library and usage pattern]
- Navigation approach: [go_router / Navigator 2.0 / other]
- HTTP client: [Dio / http / other / none]
- Feature folder convention: [example path pattern, e.g. lib/features/[name]/data/]
- Related existing files: [list of absolute paths most relevant to the new feature]
- Existing code found for this feature: [files and what they contain, or "none"]
- Key patterns to follow: [3–5 bullet points the implementation agent must replicate]
- Concerns or missing context: [anything that would block implementation]
---

After the agent returns:
- Read each file listed under "Related existing files" so you have the content in context.
- If the agent returns NEEDS_CONTEXT or BLOCKED, present the concern to the user and stop until resolved.

---

## Phase 2: Architecture and Implementation Planning

Launch the `flutter-architect` agent using the Task tool with this prompt:

---
You are acting as the Flutter Architect for the FlutterForge `/flutterforge:build-flutter-feature` workflow.

[CONTEXT]:
Feature request: $ARGUMENTS
Architecture pattern: [from Phase 1 report]
State management: [from Phase 1 report]
Navigation: [from Phase 1 report]
HTTP client: [from Phase 1 report]
Feature folder convention: [from Phase 1 report]
Key patterns to follow: [paste bullet list from Phase 1 report]
Related existing files: [paste file list from Phase 1 report]

[YOUR TASK]:
Produce a concrete implementation plan for the feature. Be specific — name every file.

1. **Files to create** — List each file with its full relative path (from project root), its layer (data/domain/presentation), and a one-sentence description of what it contains.
2. **Files to modify** — List each existing file that needs changes, what change is needed, and why.
3. **State design** — Describe the state model: what data is held in state, what actions/events exist, what the loading/error/success states look like.
4. **API requirements** — If the feature needs network calls: endpoint(s), HTTP method, request/response shape.
5. **Routing changes** — Any new routes to add to the router.
6. **Potential risks** — Breaking changes, missing dependencies, ambiguous requirements.

Do NOT write any Dart code. The plan must be in plain English with file paths.

[OUTPUT FORMAT]:
Return a structured report with:
- Status: DONE | DONE_WITH_CONCERNS | BLOCKED
- Files to create: [numbered list with path, layer, description]
- Files to modify: [list with path and change description]
- State design summary: [paragraph]
- API requirements: [list or "none — local only"]
- Routing changes: [description or "none"]
- Estimated file count: [number]
- Risks: [bullet list or "none identified"]
---

After the agent returns:
- Display the implementation plan clearly formatted to the user.

**STOP here.** Ask the user: "Does this implementation plan look correct? Reply 'yes' or 'approve' to begin writing code, or give feedback to revise the plan."

Wait for explicit user approval before proceeding to Phase 3.

---

## Phase 3: Implementation

Launch the `flutter-implementation-engineer` agent using the Task tool with this prompt:

---
You are acting as the Flutter Implementation Engineer for the FlutterForge `/flutterforge:build-flutter-feature` workflow.

[CONTEXT]:
Feature request: $ARGUMENTS
Project root: [current working directory absolute path]
Architecture pattern: [from Phase 1]
State management: [from Phase 1]
Navigation: [from Phase 1]
HTTP client: [from Phase 1]
Key patterns to follow: [paste bullet list from Phase 1]

Approved implementation plan:
[Paste the full FILES TO CREATE and FILES TO MODIFY sections from the Phase 2 agent report here]

[YOUR TASK]:
Implement the feature in three layers, in order. Format each file after writing it.

**Layer 1 — Data layer:**
Create all data models, repository implementations, and remote/local data sources listed in the plan. Follow the exact same patterns as existing files in the project.

**Layer 2 — Domain layer:**
Create repository interfaces, use cases or domain services, and domain entities listed in the plan.

**Layer 3 — Presentation layer:**
Create providers/blocs/controllers, screen widgets, and any reusable UI components listed in the plan. Wire routing changes into the existing router file.

After completing each layer, run: `dart format lib/`

Apply all modifications to existing files listed under "Files to modify". Re-read each file immediately before editing it.

Do not delete or overwrite any existing file that is not listed in the plan's "Files to modify" section.

[OUTPUT FORMAT]:
Return a structured report with:
- Status: DONE | DONE_WITH_CONCERNS | BLOCKED
- Files created: [list of absolute paths, grouped by layer]
- Files modified: [list of absolute paths]
- dart format ran: yes/no
- Any files skipped and why
- Any Dart errors encountered during implementation
- Anything the test agent needs to know
---

After the agent returns:
- Read 2–3 of the key created files to verify they look correct and match the project's patterns.
- If the agent reports BLOCKED or Dart errors, investigate and fix before proceeding.

---

## Phase 4: Tests

Launch the `flutter-test-engineer` agent using the Task tool with this prompt:

---
You are acting as the Flutter Test Engineer for the FlutterForge `/flutterforge:build-flutter-feature` workflow.

[CONTEXT]:
Feature request: $ARGUMENTS
Project root: [current working directory absolute path]
State management: [from Phase 1]

Files created in Phase 3 (implementation):
[Paste the "Files created" list from the Phase 3 agent report here]

Notes from implementation agent: [paste "Anything the test agent needs to know" from Phase 3 report]

[YOUR TASK]:
Write tests for the feature. Mirror the file structure — if the feature is at lib/features/auth/, tests go in test/features/auth/.

1. **Unit tests** — For each repository implementation and use case/domain service, write unit tests using the project's existing mock library. Prefer mocktail; if neither mocktail nor mockito is present, ask before adding a new test dependency instead of silently choosing one. Test success path and at least one failure/error path per method.
2. **Widget tests** — For the main screen widget(s) created, write widget tests that: render the screen in idle/loading/error/success states, simulate a primary user interaction (e.g. button tap, form submit), assert the expected outcome.
3. **Provider/BLoC tests** — If using Riverpod, write ProviderContainer-based tests for the feature's providers. If using BLoC, write bloc_test tests.

Follow the same test file naming and import conventions as existing test files in the project (read test/ directory first).

[OUTPUT FORMAT]:
Return a structured report with:
- Status: DONE | DONE_WITH_CONCERNS | BLOCKED
- Test files created: [list of absolute paths]
- Test count: [total number of test() calls written]
- Coverage areas: [list: which files have tests]
- Any files that could not be tested and why
---

After the agent returns:
- Run `flutter test` and capture the output.
- If tests fail, read the failure output and determine if it is a test bug or an implementation bug. Fix the test bug directly if it is minor (wrong import, typo); if it is an implementation bug, report it clearly to the user.

---

## Phase 5: Validation and Summary

Run the following commands in order and capture all output:

1. `flutter analyze --no-fatal-infos`
2. `flutter test`

Then print the final summary to the user:

```
FlutterForge: Feature build complete.

Feature: $ARGUMENTS

Files created ([count]):
  [list all files from Phase 3, grouped by layer]

Files modified ([count]):
  [list all files from Phase 3]

Tests written ([count] tests in [count] files):
  [list test files from Phase 4]

flutter analyze: [PASSED / N warnings, N errors]
flutter test:    [PASSED N/N / FAILED N/N]
```

If `flutter analyze` reported errors (not warnings): list each error with its file and line, and say "Fix these before merging."

If `flutter test` had failures: list the failing test names.

If everything passed, use the `flutter-documentation` skill to update project documentation:
- Update `README.md` if new setup steps, env vars, or commands were introduced.
- Create `docs/features/<feature-name>.md` summarizing the implementation (files created, layer structure, state approach).
- Append an ADR to `docs/architecture/architecture_decisions.md` if the feature introduced a non-obvious pattern.

Then say: "Feature is complete and validated. Suggested next steps:"
- List 2–3 related features or improvements that would naturally follow this one.
- Mention `/flutterforge:improve-ux` if the feature added new screens.
- Mention `/flutterforge:flutter-accessibility` if the feature added new screens.
- Mention `/flutterforge:prepare-release` if this completes a milestone.
