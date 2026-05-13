---
name: flutter-feature-dev
version: 1.0.0
description: >-
  Plan and implement Flutter features using the project architecture, with tests
  and validation. Use when the user wants to implement a Flutter feature, build a
  screen, add functionality to an existing app, or create a new widget.
  Trigger phrases: "build Flutter feature", "implement Flutter screen",
  "add feature to Flutter app", "create Flutter widget", "implement this feature
  in Flutter", "build the [feature] screen", "add [feature] to the app",
  "create the [feature] page", "write the code for [feature]", "implement [feature]
  in Flutter", "build the auth flow", "implement the profile screen",
  "add search to Flutter app", "create the onboarding flow", "write the repository for",
  "create a provider for". Also use when the architecture is defined and the user is
  ready to write code, or when a feature is referenced from the product brief.
---

# Flutter Feature Development

Seven-phase methodology: understand → plan → implement → UI states → tests → validate → summarize.
Implementation without understanding is the leading cause of rework. Tests are part of done.

---

## Workflow

1. **Read the request carefully** — identify exact user-facing behavior, implied edge cases, and ambiguities. Ask if ambiguity blocks architecture; document as assumption if minor.
2. **Run discovery** (first feature in session) — invoke `flutter-app-discovery` skill if codebase not yet inspected.
3. **Identify affected files** across data / domain / presentation / routing / tests. See `@references/feature-layer-template.md` for folder structure.
4. **Find patterns to reuse** — existing providers, repositories, widgets (`AppButton`, `ErrorView`, `EmptyStateView`), error handling, API client setup. Import; never recreate.
5. **Write feature spec** — use `templates/feature_spec.md` if present. Cover: summary, user stories, scope in/out, screens, state/async behavior, edge cases, assumptions, open questions.
6. **Produce implementation plan** — list every file to create (by layer and path) and every file to modify. Assess risk: low / medium / high.
7. **Get user approval** on the plan before writing any code. If user says "yes / go / do it", proceed without repeating the plan.
8. **Implement data → domain → presentation** in that order. Do not start presentation before domain contracts are defined.
9. **Implement all UI states** for every screen: loading, success, empty, error, offline.
10. **Write tests** alongside implementation: unit tests for use cases and repositories, widget tests for pages. See `@references/feature-layer-template.md` for patterns.
11. **Validate**: `dart format .` → `flutter analyze --no-fatal-infos` → `flutter test`. Fix all errors before marking done.
12. **Write summary** to `docs/features/<feature-name>.md`: files created/modified, tests written, validation results, next steps.
13. **Flag any file approaching 300 lines** — propose splitting before continuing.

---

## Feature Specification Fields

| Field | Description |
|---|---|
| Goal | One sentence: what problem this solves |
| User story | "As a [user] I want to [action] so that [outcome]" |
| Entry point | Screen or action that triggers this feature |
| Screens affected | Names of pages and widgets created or modified |
| State requirements | Async operations, loading/error/empty states needed |
| Data requirements | API endpoints, Firestore collections, local storage keys |
| Error states | Every failure scenario and how it's handled |
| Offline behavior | Cached fallback or explicit offline state |
| Analytics events | Event names to fire on key user actions |
| Accessibility notes | Semantic labels, tap targets, screen reader behavior |
| Test cases | Minimum unit tests and widget tests required |

---

## Architecture Rules

- **NEVER** introduce a new state management library without explicit user approval.
- **NEVER** add a package without explaining why and checking for existing alternatives.
- **NEVER** hardcode secrets, API keys, or tokens in any Dart file.
- **NEVER** skip tests for business logic — use cases and repositories must have unit tests.
- **NEVER** put business logic in widgets. Use controllers, providers, or cubits.
- **ALWAYS** preserve existing architecture. If the project uses Riverpod, do not add Bloc.
- **ALWAYS** implement all five UI states for every screen.
- **ALWAYS** get plan approval (step 7) before writing implementation code.
- After 2 failed fix attempts: re-read the full file top-to-bottom, state the wrong assumption, propose a different approach.
- Renaming: search all references — imports, string literals, dynamic imports, test mocks, re-exports.

---

## Required UI States

Every screen must handle:
- **Loading** — skeleton loader or `LoadingIndicator` (for data fetch)
- **Success** — render actual data
- **Empty** — `EmptyStateView` with a primary action
- **Error** — `ErrorView` with retry callback; never silent failure
- **Offline** — `OfflineBanner` when the app has offline behavior

Every async button must: show loading state (disable + spinner), handle success (navigate / snackbar), handle failure (inline error or snackbar).

---

## Output Artifacts

- `docs/features/<feature-name>.md` — feature spec + implementation summary
- `lib/features/<feature>/data/` — DTOs, datasources, repository impl
- `lib/features/<feature>/domain/` — entities, repository interface, use cases
- `lib/features/<feature>/presentation/` — controller/cubit, page, widgets
- `test/features/<feature>/` — unit + widget tests

---

## Cross-references

- Agents: `flutter-implementation-engineer`, `flutter-test-engineer`, `state-management-specialist`
- See `@references/feature-layer-template.md` for folder structure and Dart patterns
- See `@references/state-management-snippets.md` for Riverpod/Bloc examples
- See `@references/dart-error-mapping.md` for error hierarchy and DioException mapping
