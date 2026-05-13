# ADR-[NUMBER]: [TITLE]

<!-- Instruction: One decision per ADR. Titles should complete the phrase "We decided to..." — e.g., "ADR-003: Use Riverpod for State Management". Number sequentially. -->

---

## Status

<!-- Instruction: Pick one. Update this field when status changes — do not delete old ADRs. -->

`proposed` | `accepted` | `deprecated` | `superseded by ADR-[NUMBER]`

**Date:** [PLACEHOLDER — YYYY-MM-DD]
**Author:** [PLACEHOLDER — @username or name]
**Deciders:** [PLACEHOLDER — list everyone who agreed to this decision]

---

## Context

<!-- Instruction: Describe the situation as it existed when this decision was made. Include constraints, forces, and requirements that shaped the choice. Be specific — vague context produces revisited decisions. -->

[PLACEHOLDER — e.g., "The app requires managing async server state (loading/error/data) across 12+ screens while keeping widgets testable and business logic out of the widget tree. The team has two Flutter developers with intermediate Riverpod experience and no BLoC experience. We need to ship the MVP in 6 weeks."]

---

## Decision

<!-- Instruction: State what was decided and the core reasoning. One clear paragraph. Avoid hedging. -->

[PLACEHOLDER — e.g., "We will use Riverpod 2.x with code generation (riverpod_annotation + build_runner) as the sole state management solution. AsyncNotifier covers loading/error/data lifecycle without custom wrappers. Providers are auto-disposed when no longer watched, preventing memory leaks. Code generation eliminates a class of runtime errors (misspelled provider names) and reduces boilerplate compared to manual provider declarations."]

---

## Consequences

### Positive

<!-- Instruction: Real benefits — not just restating the decision. -->

- [PLACEHOLDER — e.g., Providers are type-safe and compile-time verified via code generation]
- [PLACEHOLDER — e.g., Business logic in NotifierProviders is independently unit testable]
- [PLACEHOLDER — e.g., Auto-dispose eliminates a category of memory leaks]
- [PLACEHOLDER]

### Negative

<!-- Instruction: Honest trade-offs. Every decision has them. -->

- [PLACEHOLDER — e.g., build_runner adds a code generation step to the dev workflow; watch mode required during development]
- [PLACEHOLDER — e.g., Generated files must be committed or regenerated in CI — adds CI step]
- [PLACEHOLDER — e.g., Learning curve for developers new to Riverpod's provider graph model]
- [PLACEHOLDER]

---

## Alternatives Considered

<!-- Instruction: Show the work. List options that were evaluated and why they were rejected. -->

### [PLACEHOLDER — e.g., BLoC / flutter_bloc]

**Why rejected:** [PLACEHOLDER — e.g., More boilerplate per feature (Event + State + Bloc classes). Team has no existing BLoC experience and the 6-week timeline doesn't allow ramp-up. BLoC's strict event-driven model is better suited to complex state machines than this app's data-fetching use cases."]

### [PLACEHOLDER — e.g., Provider (legacy)]

**Why rejected:** [PLACEHOLDER — e.g., No longer recommended for new projects by the Riverpod maintainer. Lacks compile-time safety and the auto-dispose/family features we need."]

### [PLACEHOLDER — Option 3]

**Why rejected:** [PLACEHOLDER]

---

## Related Decisions

<!-- Instruction: Link to ADRs this decision depends on or conflicts with. -->

- [PLACEHOLDER — e.g., ADR-001: Feature-first Clean Architecture (this decision complements the presentation layer pattern)]
- [PLACEHOLDER — e.g., ADR-005: GoRouter for Navigation (providers are accessed from route guards)]

---

## Notes

<!-- Instruction: Optional. Anything that didn't fit above — links to benchmarks, prototypes, discussions. -->

[PLACEHOLDER — e.g., "Spike comparing BLoC vs Riverpod: [link]. Riverpod won on test ergonomics and less boilerplate for our use case patterns."]
