---
description: "Safely refactor Flutter code — architecture alignment, widget extraction, pattern standardization, with analyzer and test validation."
argument-hint: "<what to refactor: file path, pattern name, or description>"
allowed-tools: ["Read", "Glob", "Grep", "Bash", "Task", "Write", "Edit", "TodoWrite"]
---

You are running `/flutterforge:refactor-flutter`.

Refactor request: `$ARGUMENTS`

---

## Phase 1: Refactor Scope Analysis

Parse `$ARGUMENTS`:
- If it ends in `.dart` or contains a `/`: treat as a file path — read the file directly.
- If it matches a known pattern keyword (state management, navigation, widgets, theming, networking, dependency injection): search `lib/` for files relevant to that pattern using Grep and Glob.
- Otherwise: treat as a free-form description and search `lib/` broadly for relevant files using Grep on the description terms.

Launch the `codebase-auditor` agent using the Task tool with this prompt:
---
Context: Flutter codebase refactor scoping task.

Refactor request: $ARGUMENTS

Files identified in scope:
[For each file found above, paste:]
FILE: <path>
```dart
<full file contents>
```

Task: Analyze the files above against the refactor request and return:

1. Specific anti-patterns or violations present — list each with file path and line number(s)
2. Scope classification:
   - Small: 1–3 files, low interdependency
   - Medium: 4–10 files, some shared types or interfaces
   - Large: 10+ files, cross-cutting concern
3. Risk assessment:
   - Low: purely internal changes, no public API or shared widget impact
   - Medium: changes to types or interfaces used by other files
   - High: changes to shared state, routing, or foundational abstractions
4. For Large scope: recommend how to break into incremental phases (e.g. "Phase A: extract widget, Phase B: migrate state")
5. Suggested approach: step-by-step description of what to change and in what order

Return:
- refactor_scope: description of what will be changed
- files_and_lines: list of file paths with specific line numbers
- risk_level: low / medium / high
- risk_reason: one sentence
- suggested_approach: ordered steps
- phase_breakdown: (only if Large scope) list of incremental phases
---

Wait for the agent to return before proceeding to Phase 2.

---

## Phase 2: Plan Approval

Present the auditor's findings to the user:

```
Refactor Plan
─────────────
Scope: <refactor_scope>
Risk: <risk_level> — <risk_reason>
Files affected: <count>

Approach:
<suggested_approach as numbered steps>

[If Large scope:]
Recommended phases:
<phase_breakdown>
```

STOP. Ask: "Approve this refactor plan? (Risk: [risk_level] — [risk_reason]) Reply yes to proceed, or describe changes to the plan."

Do NOT proceed to Phase 3 without an explicit yes or equivalent approval ("go", "do it", "looks good").

If the user modifies the plan, update the plan description and confirm the updated version before proceeding.

---

## Phase 3: Baseline Test Run

Before making any code changes, establish a test baseline.

Run: `flutter test`

If tests fail before the refactor:
- Show which tests are failing and their error output.
- Ask: "There are N pre-existing test failures unrelated to this refactor. Proceed anyway? These failures will not be caused by the refactor, but they will make it harder to tell if the refactor breaks anything."
- Wait for confirmation before proceeding.

Record the passing test count and any pre-existing failures. This is the baseline.

---

## Phase 4: Incremental Refactor

Launch the `flutter-implementation-engineer` agent using the Task tool with this prompt:
---
Context: Approved Flutter refactor. Apply changes incrementally with analyzer validation between each file.

Approved refactor plan:
<paste the full plan text from Phase 2 including scope, approach steps, and phase breakdown if applicable>

Files to change (in this order):
<paste files_and_lines from Phase 1 in recommended change order>

Constraints:
- Make changes one file at a time. After each file, mentally verify the change would pass `flutter analyze` before moving to the next.
- Do NOT change public APIs (method signatures, class names, exported types) unless the refactor plan explicitly requires it. If a public API change is required, note it clearly in your return and list every other file that will be affected.
- Do NOT swap state management solutions, routing libraries, or DI frameworks unless that is explicitly the stated refactor goal.
- Preserve existing test files — do not modify test files during this phase.
- Extract widgets only when the extracted widget is used in 2+ places or exceeds 80 lines.
- After all files are changed, run: dart format .
- If you encounter a situation where the approved plan cannot be applied cleanly (import cycle, breaking change, ambiguous architecture choice), stop at that file and flag it — do not improvise a different approach.

Return:
- files_changed: list of file paths
- per_file_summary: for each file, 1–3 sentences on what changed and why
- flagged_items: anything that could not be cleanly applied (if any)
- public_api_changes: list of any public API changes made (if any) and files that reference them
---

Apply the returned changes using Edit. For any flagged items, present them to the user and ask how to proceed before continuing.

---

## Phase 5: Validation

Run both validation commands:

```bash
flutter analyze --no-fatal-infos
```
```bash
flutter test
```

Compare against the Phase 3 baseline:
- New failures (passed before, fail now): broken by the refactor — show them and ask: "Options: (1) Fix tests, (2) Revert refactor, (3) Investigate. Which do you prefer?"
- Pre-existing failures: note they were present before.
- New passes: note if the refactor fixed any failing tests.
- Wait for direction before acting if new failures exist.

If clean (or only pre-existing failures remain), print final summary:
```
Refactor Complete — Files: N | Risk: X | Tests: N passing (+/- delta) | Analyzer: clean
Changes: <per_file_summary, one line per file>
Public API changes (if any): <list — update callers not in scope>
Follow-up: <flagged_items or next incremental phase>
```
