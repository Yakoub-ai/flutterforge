---
name: flutter-state-management
version: 1.0.0
description: >-
  Use this skill when the user wants to choose, design, or implement state
  management in a Flutter application. Trigger phrases: "state management
  Flutter", "Riverpod", "Bloc Flutter", "Cubit", "manage state", "provider vs
  bloc", "choose state management", "how to handle state in Flutter",
  "AsyncNotifier", "NotifierProvider", "BlocBuilder", "state architecture".
---

# Flutter State Management

Choose, implement, and maintain state management in Flutter apps. Covers the
full decision framework: picking the right approach, setting it up correctly,
and avoiding common anti-patterns.

**First question always:** "Is this state local to one widget, or shared across
the app?" That single question eliminates most wrong choices.

---

## Decision Framework

| Scenario | Recommendation | Reason |
|---|---|---|
| Async data scoped to one screen | `FutureBuilder` or local `AsyncNotifier` | No global state needed |
| Shared state across screens, reactive | Riverpod (`AsyncNotifierProvider`, `NotifierProvider`) | Code gen, DI, testable, compile-safe |
| Complex event-driven flows with audit trails | Bloc or Cubit | Explicit transitions, traceable |
| Simple shared state, small app | `ChangeNotifier` + `ListenableBuilder` | Zero deps, minimal ceremony |
| Server-driven real-time data | `StreamProvider` (Riverpod) or `StreamBuilder` | Reactive by nature |
| Avoid | GetX, Redux, MobX | High ceremony, implicit magic, poor testability |

**Riverpod vs Bloc:**
- Riverpod → code generation, compile-time safety, built-in DI
- Bloc → explicit event log, strong team expertise required

---

## Riverpod Setup

```yaml
# pubspec.yaml
dependencies:
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0
dev_dependencies:
  riverpod_generator: ^2.4.0
  build_runner: ^2.4.0
```

Always use `@riverpod` annotation with `riverpod_generator`. Hand-writing providers loses compile-time safety.

Wrap the app root with `ProviderScope`:
```dart
void main() => runApp(const ProviderScope(child: MyApp()));
```

Run code generation:
```bash
dart run build_runner watch --delete-conflicting-outputs
```

---

## Riverpod Provider Types

| Provider | Use for |
|---|---|
| `AsyncNotifierProvider` | API calls, anything async that can fail or be pending |
| `NotifierProvider` | Synchronous mutable state (tab selection, filters, toggles) |
| `Provider` | Derived/computed values with no mutation |
| `StreamProvider` | Firestore listeners, WebSocket feeds, `Stream<T>` |
| Family modifier | Parameterized providers (e.g., `productProvider('id-123')`) |

See `@references/state-management-snippets.md` for full Riverpod code examples (AsyncNotifier, NotifierProvider, StreamProvider, family, testing).

---

## `ref.watch` vs `ref.read`

| | `ref.watch` | `ref.read` |
|---|---|---|
| Where | Inside `build()` or provider `build()` | Inside callbacks, event handlers, notifier methods |
| Behavior | Subscribes; rebuilds when value changes | One-time read; no subscription |
| Wrong usage | Inside callbacks (creates leak) | Inside `build()` (misses updates) |

---

## Lifecycle

- `autoDispose` (default with code gen) — provider destroyed when no listeners remain. Use for screen-scoped data.
- `keepAlive` — opt-in to prevent disposal. Use for app-wide singletons.
- Force refresh: `ref.invalidate(myProvider)`
- Use `ref.select((state) => state.field)` to rebuild only when a specific field changes (avoids broad rebuilds).

---

## Bloc / Cubit

| | Cubit | Bloc |
|---|---|---|
| API | Method calls emit states | Explicit Event types map to state transitions |
| Use when | Forms, toggles, simple screens | Complex flows needing an audit trail |
| Boilerplate | Low | Higher |

```yaml
# pubspec.yaml
dependencies:
  flutter_bloc: ^8.1.0
  freezed_annotation: ^2.4.0
dev_dependencies:
  bloc_test: ^9.1.0
  freezed: ^2.4.0
```

| Widget | Use for |
|---|---|
| `BlocBuilder` | Rebuild subtree when state changes |
| `BlocListener` | Side effects only (navigation, dialogs, snackbars) |
| `BlocConsumer` | Both rebuild and side effects |

See `@references/state-management-snippets.md` for Cubit, Bloc, sealed state (`freezed`), BlocConsumer, and `bloc_test` examples.

---

## Anti-Patterns

- **`setState` for business logic** — use it only for widget-local UI state (animation phase, focus). Never for data from a repository.
- **Mixing two state managers in one feature** — pick one per feature; mixing creates unpredictable rebuild chains.
- **Not handling loading and error states** — every async provider must handle all three states: loading, error, data.
- **`ref.read` inside `build`** — `read` does not subscribe; the widget will not rebuild. Use `ref.watch` in `build`.
- **Holding `BuildContext` in providers** — providers outlive widgets; capturing context causes memory leaks.
- **Global state for widget-local concerns** — promote state to the minimal scope that all consumers share.
- **Watching too broadly** — `ref.watch(provider)` on a large object rebuilds on any field change. Use `select`.

---

## Output Artifacts

No dedicated docs artifact — state management decisions are recorded in:
- `docs/architecture/architecture_decisions.md` (ADR for chosen approach)
- `docs/architecture/technical_plan.md` (tech stack section)

---

## Cross-references

- Decision context: `flutter-architecture` skill
- Code examples: `@references/state-management-snippets.md`
- Agent: `state-management-specialist`
- Error mapping from providers: `@references/dart-error-mapping.md`
