---
description: "Plan a new Flutter app from idea to technical blueprint — product brief, screen flows, and architecture before any code."
argument-hint: <app idea or description>
allowed-tools: ["Read", "Glob", "Grep", "Bash", "Task", "Write", "Edit", "TodoWrite"]
---

You are running `/flutterforge:plan-flutter-app`.

The user's app idea: $ARGUMENTS

If `$ARGUMENTS` is empty, ask: "What app do you want to plan? Describe it in a sentence or two." and stop until the user replies.

Before launching agents, check whether the idea clearly states these product-critical facts:
- Target platforms: iOS, Android, or both
- Backend/data source: Firebase, Supabase, REST API, local-only, or unknown
- Account/auth needs and any payments/subscriptions
- Offline requirements
- Privacy-sensitive data or device permissions (location, camera, contacts, health, microphone)
- Timeline and one measurable success metric

If two or more facts are missing, ask a concise follow-up and wait for the user. If only one fact is missing, proceed and mark it as an assumption in the product brief.

---

## Phase 1: Product Discovery

Launch the `product-strategist` agent using the Task tool with this prompt:

---
You are acting as the Product Strategist for the FlutterForge `/flutterforge:plan-flutter-app` workflow.

[CONTEXT]:
App idea: $ARGUMENTS
Output directory: docs/product/ (relative to the current working directory)
Document status: draft until explicitly approved by the user

[YOUR TASK]:
Produce three planning documents and write them to docs/product/:

1. **app_brief.md** — App name, one-line pitch, problem statement, target platforms, backend assumptions, account/auth/payment needs, privacy-sensitive data, device permissions, target users, core value proposition, success metrics (3–5), and out-of-scope items for v1.
2. **user_stories.md** — 10–15 user stories in "As a [user], I want to [action] so that [outcome]" format, grouped by epic.
3. **mvp_scope.md** — Features ranked as Must/Should/Could/Won't (MoSCoW), with a recommended MVP cutline and estimated complexity (S/M/L) per feature.

Create the docs/product/ directory if it does not exist. Write each document as clean Markdown.

[OUTPUT FORMAT]:
Return a structured report with:
- Status: DONE | DONE_WITH_CONCERNS | BLOCKED
- Files written: [list of absolute paths]
- App name chosen: [name]
- Core problem: [one sentence]
- MVP feature count: [number of Must features]
- Any concerns or assumptions made
---

After the agent returns:
- Read docs/product/app_brief.md, docs/product/user_stories.md, and docs/product/mvp_scope.md.
- Display a concise summary: app name, problem, target user, MVP must-have features (bullet list), and any concerns the agent flagged.

**STOP here.** Ask the user: "Does this product brief capture your vision? Reply 'yes' or 'approve' to continue to UX design and architecture planning, or give me feedback to revise."

Wait for explicit user approval before proceeding to Phase 2.

---

## Phase 2: UX Design + Architecture (parallel)

Dispatch BOTH agents simultaneously in a single step. Do not wait for one before launching the other.

**Agent A — Launch the `ux-mobile-designer` agent using the Task tool with this prompt:**

---
You are acting as the UX Mobile Designer for the FlutterForge `/flutterforge:plan-flutter-app` workflow.

[CONTEXT]:
Read docs/product/app_brief.md and docs/product/user_stories.md before starting. These files exist in the current working directory.
Output directory: docs/ux/

[YOUR TASK]:
Produce four UX planning documents and write them to docs/ux/:

1. **screen_map.md** — Every screen in the app as a Markdown list with: screen name, purpose, entry points, and exit points.
2. **user_flows.md** — 3–5 primary user journeys as numbered step-by-step flows (text-based, no image tools needed). Include happy path and one error/edge path per flow.
3. **design_system.md** — Color palette (primary, secondary, surface, error, on-* variants), typography scale (display/headline/body/label), spacing scale, border radii, and shadow levels. Align with Material 3 conventions.
4. **component_inventory.md** — List of all reusable UI components the app needs, grouped by: navigation, forms, cards/lists, feedback (dialogs/snackbars), and custom components unique to this app.

Create docs/ux/ if it does not exist.

[OUTPUT FORMAT]:
Return a structured report with:
- Status: DONE | DONE_WITH_CONCERNS | BLOCKED
- Files written: [list of absolute paths]
- Screen count: [number]
- Primary user flows: [list of flow names]
- Design system primary color: [hex]
- Component count: [number]
- Any concerns or assumptions
---

**Agent B — Launch the `flutter-architect` agent using the Task tool with this prompt:**

---
You are acting as the Flutter Architect for the FlutterForge `/flutterforge:plan-flutter-app` workflow.

[CONTEXT]:
Read docs/product/app_brief.md and docs/product/user_stories.md before starting. These files exist in the current working directory.
Output directory: docs/architecture/

[YOUR TASK]:
Produce three architecture planning documents and write them to docs/architecture/:

1. **technical_plan.md** — Recommended Flutter architecture pattern (e.g. feature-first with Riverpod, clean architecture with BLoC), state management choice with justification, navigation approach (go_router vs Navigator 2.0), data layer strategy (local vs remote, caching), and third-party dependencies with rationale for each.
2. **architecture_decisions.md** — ADR-style records for the top 5 architectural choices. Each ADR: title, status, context, decision, consequences.
3. **folder_structure.md** — Full proposed lib/ directory tree as a code block, with a one-line description for each folder's responsibility.

Create docs/architecture/ if it does not exist.

[OUTPUT FORMAT]:
Return a structured report with:
- Status: DONE | DONE_WITH_CONCERNS | BLOCKED
- Files written: [list of absolute paths]
- Architecture pattern: [name]
- State management: [library/approach]
- Navigation: [approach]
- Key dependencies: [list]
- Any concerns or assumptions
---

After both agents return:
- Display a side-by-side summary table:
  | | UX Design | Architecture |
  |---|---|---|
  | Key output | [screen count] screens, [component count] components | [pattern], [state mgmt] |
  | Files | [list] | [list] |
  | Concerns | [any] | [any] |

---

## Phase 3: Review and Handoff

Present a final planning summary:

- **Product brief** — App name, problem, MVP must-have features
- **UX** — Number of screens, primary user flows, design system palette
- **Architecture** — Pattern, state management, navigation approach, key dependencies
- **All docs written to:** docs/product/, docs/ux/, docs/architecture/

Then say:

"Planning is complete. Your next steps:
- Run `/flutterforge:new-flutter-app` to scaffold the project using this plan.
- Run `/flutterforge:build-flutter-feature <feature name>` to start implementing individual features.
- All planning docs are in docs/ and will be referenced automatically by downstream commands."
