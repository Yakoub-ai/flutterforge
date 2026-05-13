---
name: flutter-architecture
version: 1.0.0
description: >-
  Define, choose, or review the technical architecture for a Flutter app.
  Use when the user wants to structure a new Flutter project, choose a state
  management approach, set up routing, or review an existing architecture.
  Trigger phrases: "design Flutter architecture", "choose state management",
  "set up Flutter project structure", "what architecture should I use",
  "Flutter clean architecture", "feature-first Flutter", "help me structure my
  Flutter app", "should I use Riverpod or Bloc", "define the tech stack",
  "Flutter project setup". Also use when the product brief is complete and the
  user is ready to define the technical foundation.
---

# Flutter Architecture

A structured methodology for defining the technical architecture of a Flutter app — covering structure, state management, routing, and the dependency stack — before any feature is implemented.

**Guiding principle:** Preserve existing architecture in active projects. Only recommend changes — do not apply them without explicit approval.

---

## Workflow

1. **Gather context** — read `docs/product/app_brief.md` if it exists. Ask: app scale (small/medium/large), team size and Flutter experience, offline requirements, backend type (Firebase/Supabase/REST/none), release timeline, platform targets.
2. **Recommend architecture pattern** — apply decision rules below.
3. **Design folder structure** — feature-first or layer-first, based on app scale.
4. **Choose state management** — apply decision rules in `@references/state-management-snippets.md`.
5. **Define routing strategy** — GoRouter for most apps; auto_route for heavy typed routing needs.
6. **Define dependency stack** — list recommended packages with justifications. Query pub-dev MCP for current versions before pinning any.
7. **Document decisions** — produce an ADR for each major choice. Use `templates/architecture_decision_record.md`.
8. **Get user approval** on the architecture plan before any implementation begins.

---

## Architecture Pattern Decision Rules

| App profile | Recommended pattern |
|---|---|
| Small app, 1-2 dev, simple state | Layer-first, `ChangeNotifier` + `ListenableBuilder` |
| Medium app, team product | Feature-first, Clean Architecture, Riverpod |
| Large app, multiple teams | Feature-first, Clean Architecture, Riverpod or Bloc, Melos monorepo |
| Existing Bloc codebase | Preserve Bloc; suggest Cubit where appropriate |
| Team has strong Bloc expertise | Bloc/Cubit regardless of scale |

**Default recommendation for new medium+ apps:** feature-first structure with Riverpod, GoRouter, Freezed, Dio, flutter_secure_storage.

---

## Feature-First Folder Structure

```
lib/
├── app/                    # MaterialApp, router, theme, localization
├── core/                   # config, constants, errors, network, utils, shared widgets
└── features/
    └── <feature>/
        ├── data/           # DTOs, datasource interfaces+impls, repository impls
        ├── domain/         # entities, repository interfaces, use cases
        └── presentation/   # controller/cubit, pages, widgets
```

See `@references/feature-layer-template.md` for per-layer file naming and patterns.

---

## State Management Decision

See `@references/state-management-snippets.md` for full Riverpod and Bloc examples.

Quick rule:
- **Riverpod** — code gen, DI, compile-time safety, composable; best for new medium/large apps
- **Bloc/Cubit** — explicit event log, strong team expertise required; best for complex business flows
- **ChangeNotifier** — simple apps, minimal ceremony, no code gen
- **GetX, Redux, MobX** — avoid unless team has deep existing expertise

---

## Routing Decision

| Router | Use when |
|---|---|
| `go_router` | Most apps; supports deep links, web URLs, shell routes |
| `auto_route` | Strongly typed routes, complex guards, large navigation trees |
| `Navigator 2.0` directly | Avoid — high boilerplate |

---

## Recommended Default Stack (new medium+ app)

- State management: Riverpod + riverpod_annotation
- Routing: go_router
- HTTP: Dio + pretty_dio_logger (debug)
- Serialization: freezed + json_serializable
- Secure storage: flutter_secure_storage
- Local DB: Hive (simple) / Drift (relational) / Isar (high-perf)
- Linting: very_good_analysis or flutter_lints
- Testing: mocktail

Query pub-dev MCP (`getPackage`, `getPackageScore`) before pinning any package version.

---

## Output Artifacts

- `docs/architecture/technical_plan.md` — architecture overview (use `templates/technical_plan.md`)
- `docs/architecture/architecture_decisions.md` — ADR log
- `lib/app/` — initial app, router, theme scaffold
- `lib/core/errors/` — Failure + AppException hierarchy
- `analysis_options.yaml` — configured linting

---

## Cross-references

- Agent: `flutter-architect`
- State management patterns: `@references/state-management-snippets.md`
- Layer patterns: `@references/feature-layer-template.md`
- Error patterns: `@references/dart-error-mapping.md`
- Package research: pub-dev MCP, context7 MCP
