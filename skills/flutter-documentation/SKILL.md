---
name: flutter-documentation
version: 1.0.0
description: >-
  Generate and maintain project documentation for Flutter apps: README, architecture
  docs, feature docs, and onboarding materials. Use when the user wants to update
  the README, document a completed feature, write an architecture decision record,
  or prepare onboarding materials for new team members.
  Trigger phrases: "generate docs", "update README", "document Flutter app",
  "write architecture docs", "create onboarding guide", "document this feature",
  "write an ADR", "update the tech plan", "document the architecture".
  Also invoked automatically by /flutterforge:build-flutter-feature (Phase 5, feature summary)
  and /flutterforge:prepare-release (release notes generation).
---

# Flutter Documentation

Generate and maintain project documentation that helps the team understand, extend, and onboard onto the Flutter app.

---

## Workflow

1. **Identify what needs documenting** — new feature, architecture decision, release, or onboarding gap.
2. **Read the project state first** — inspect `README.md`, `docs/`, `lib/`, `pubspec.yaml`. Never write docs that contradict the actual code.
3. **Choose the right template** from `templates/` (see Output Artifacts below).
4. **Draft the document** — fill all required sections; mark `[TODO]` for sections requiring user input.
5. **Review for accuracy** — every file path, command, and class name must exist in the current codebase.
6. **Update the README** if new commands, env vars, setup steps, or architecture patterns were introduced.
7. **Cross-link** — new feature docs should be referenced from `docs/architecture/technical_plan.md` or the relevant ADR.

---

## Documentation Rules

- **Never** document something that contradicts the current code — outdated docs are worse than none.
- **Never** copy-paste code examples without verifying they match the current Flutter/Dart version.
- README must always have: setup commands, run commands, test commands, env var list, folder structure.
- ADRs are append-only — mark superseded decisions as "Superseded by ADR-XXX" rather than deleting.
- Feature docs live in `docs/features/<feature-name>.md` and are created by `/flutterforge:build-flutter-feature` Phase 7.
- Keep `templates/claude_project_memory.md` up to date — it is the `CLAUDE.md` template for AI context.

---

## README Required Sections

| Section | Content |
|---|---|
| App summary | One paragraph: what the app does and who it's for |
| Tech stack | Flutter version, state management, router, backend, key packages |
| Prerequisites | Flutter SDK version, env var setup, backend accounts |
| Setup | `git clone` → `flutter pub get` → env file setup → run |
| Run commands | `flutter run`, debug vs release flags |
| Test commands | `flutter test`, `flutter test --coverage`, integration tests |
| Build commands | `flutter build appbundle`, `flutter build ios` |
| Environment variables | Table: name, required/optional, description |
| Folder structure | Top-level `lib/` layout |
| Contributing | PR process, code style, how to add features |

---

## Architecture Decision Record (ADR) Format

Use `templates/architecture_decision_record.md`. Required fields: status (proposed / accepted / superseded), context, decision, consequences, alternatives considered.

---

## Output Artifacts

- `README.md` — main project README (updated)
- `docs/architecture/technical_plan.md` — architecture overview
- `docs/architecture/architecture_decisions.md` — ADR log
- `docs/features/<feature-name>.md` — per-feature implementation summary
- `docs/product/app_brief.md` — product brief (from planning phase)
- `docs/onboarding/` — setup guides, environment setup, team conventions

---

## Cross-references

- Agents: `flutter-architect` (ADR content), `flutter-implementation-engineer` (feature summaries)
- Templates: `templates/architecture_decision_record.md`, `templates/feature_spec.md`, `templates/claude_project_memory.md`
