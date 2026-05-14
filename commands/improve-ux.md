---
description: "Analyze and improve the UX of Flutter screens — accessibility, UI states, design consistency, and platform conventions."
argument-hint: <screen name, widget file path, or 'all'>
allowed-tools: ["Read", "Glob", "Grep", "Bash", "Task", "Write", "Edit", "TodoWrite"]
---

You are running `/flutterforge:improve-ux`.

Target: `$ARGUMENTS`

---

## Phase 1: Scope Identification

Parse `$ARGUMENTS`:
- If it is a specific file path: read that file directly.
- If it is a screen name (no `/` or `.dart`): glob for `**/*$ARGUMENTS*.dart` in `lib/`.
- If it is `all` or empty: glob for all `*_page.dart`, `*_screen.dart`, and `*_view.dart` files under `lib/`.

For each file in scope:
- Read the file.
- Note: widget type (StatelessWidget / StatefulWidget / ConsumerWidget / etc.), which UI states are handled (loading, empty, error, offline), and approximate complexity (line count).

Display the scope to the user as a table: File | Widget Type | UI States Found | Lines

If more than 5 screens are in scope, stop and ask: "This will analyze N screens. Proceed with all, or narrow the scope?"

Do not proceed to Phase 2 until scope is confirmed.

---

## Phase 2: UX Analysis

Launch the `ux-mobile-designer` agent using the Task tool with this prompt:
---
Context: Flutter project UX review. The following screens need analysis.

[For each file in scope, paste this block:]
FILE: <filename>
```dart
<full file contents>
```

Task: For each screen listed above, identify:
1. Missing UI states — any of loading, empty/zero-data, error, offline that are absent
2. Layout issues — overflow risk, missing SafeArea/MediaQuery padding, hardcoded pixel sizes, non-responsive layouts
3. Accessibility gaps — missing Semantics labels, tap targets smaller than 48×48dp, low contrast text, missing tooltip on icon-only buttons
4. Platform convention violations — Android/iOS-specific patterns used on the wrong platform, non-standard navigation gestures
5. Generic or poor UX patterns — placeholder text never replaced, Lorem ipsum, raw error stack traces shown to users, disabled buttons with no explanation

Return a findings table per screen:
| Severity (high/medium/low) | Category | Line(s) | Issue | Recommended Fix |

Also return a prioritized top-5 list across all screens.
---

Wait for the agent to return before proceeding.

---

## Phase 3: Implementation

Present the findings from Phase 2 to the user in a readable format grouped by screen.

Ask: "Which issues should I fix? Reply with severity levels (e.g. 'all high', 'all', 'just HomeScreen'), specific item numbers, or 'none'."

Wait for the user's response. If `none`, skip to Phase 4.

For approved fixes, launch the `flutter-implementation-engineer` agent using the Task tool with this prompt:
---
Context: Flutter UX improvement task. Apply only the approved fixes listed below.

Files to modify:
<list each file path>

Approved fixes to implement:
<paste the exact rows from the Phase 2 findings table that were approved>

Constraints:
- Preserve the existing architecture and state management patterns exactly (do not swap providers, blocs, or notifiers).
- For missing UI states: add them inline where data is fetched/displayed — do not restructure the widget tree beyond what is necessary.
- For accessibility: wrap existing widgets in Semantics or MergeSemantics rather than rewriting.
- After all changes, run: dart format .
- If any fix would require changing a public API or shared widget, note it but do not make that change — flag it for the user instead.

Return:
- List of files changed
- Per file: what was changed and why
- Any concerns or flagged items that were skipped
---

After the agent returns, read the files it changed and verify the edits match the approved findings. If the agent reports flagged items, present them to the user and ask how to proceed before making any additional changes.

---

## Phase 4: Accessibility Validation

Run: `flutter analyze --no-fatal-infos`

If new issues appear that were not present before Phase 3, list them and ask whether to fix them now.

Produce a final summary:
- UX improvements made (count by severity)
- Remaining issues not fixed (if user chose partial fixes)
- Top follow-up recommendations

Offer: "Run `/flutterforge:flutter-accessibility` for a deeper semantics and screen-reader audit?"
