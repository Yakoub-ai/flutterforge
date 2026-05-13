---
description: "Audit and improve Flutter accessibility — semantics, contrast, tap targets, screen reader support (TalkBack/VoiceOver), and WCAG 2.1 AA compliance."
argument-hint: "[file path, screen name, or 'all']"
allowed-tools: ["Read", "Glob", "Grep", "Bash", "Task", "Write", "Edit"]
---

You are running `/flutterforge:flutter-accessibility`.

Target: `$ARGUMENTS`

---

## Phase 1: Scope Resolution

Parse `$ARGUMENTS`:
- If a `.dart` file path: read that file directly.
- If a screen name (no `/`): glob `lib/**/*$ARGUMENTS*.dart`.
- If `all` or empty: glob all `*_page.dart`, `*_screen.dart`, `*_view.dart` files under `lib/`.

For each file in scope, note: widget type, approximate line count, and whether it contains any `Semantics`, `ExcludeSemantics`, `Tooltip`, or `MergeSemantics` widgets.

Display scope table: File | Widget Type | Has Semantics | Lines

If more than 5 screens are in scope, ask: "This will audit N screens. Proceed with all, or narrow the scope?" Stop until confirmed.

---

## Phase 2: Accessibility Audit

Use the `flutter-accessibility` skill to run the full audit against each screen in scope.

For each screen, check:

**Semantics:**
- Every `Image` has `semanticLabel` or is wrapped in `ExcludeSemantics` (decorative)
- Every `IconButton` has `tooltip` or `Semantics(label: ...)`
- Every `TextField` has `decoration.label` or `Semantics(label: ...)`
- Custom interactive widgets use `Semantics(button: true, onTap: ...)`
- Decorative widgets use `ExcludeSemantics`
- Grouped elements use `MergeSemantics`

**Touch Targets:**
- All interactive elements ≥ 48×48 dp (check for `SizedBox`, `InkWell`, `GestureDetector` sizing)
- ≥ 8 dp gap between adjacent tap targets

**Color and Contrast:**
- Body text ≥ 4.5:1 contrast ratio against background
- Large text (18sp+ or 14sp+ bold) ≥ 3:1 contrast ratio
- Information not conveyed by color alone

**Text Scaling:**
- No hardcoded `fontSize` with fixed-height parent containers
- No `maxLines` constraints that would truncate at 1.3x scale
- Uses `Flexible`/`Expanded` to accommodate scaled text

**Screen States:**
- Loading state: `CircularProgressIndicator` has `Semantics(label: 'Loading...')`
- Error state: retry button has descriptive label
- Empty state: has readable text, not just an icon

---

## Phase 3: Implementation

Launch the `ux-mobile-designer` agent using the Task tool with this prompt:

---
Context: Flutter accessibility implementation pass. The following files need accessibility fixes.

Audit findings:
[Paste the full audit findings from Phase 2 here, organized by file and severity]

Your task: Implement accessibility fixes for all HIGH and BLOCKER severity findings. For MEDIUM findings, implement if they are quick wins (adding a tooltip, wrapping in Semantics). Leave LOW findings as comments in the findings document.

Rules:
- Do not change the visual appearance of any widget — only add semantic annotations and adjust sizing constraints.
- Use `tooltip` on `IconButton` before reaching for `Semantics` — it serves both sighted and screen reader users.
- For tap target size fixes: wrap in `SizedBox(width: 48, height: 48, child: Center(child: ...))`.
- For decorative icons: wrap in `ExcludeSemantics(child: Icon(...))`.
- For text scaling: add `Flexible` or `Expanded` wrappers; remove explicit `maxLines` constraints where text truncation would be unexpected.
- Run `dart format <file>` after editing each file.

Return:
- Status: DONE | DONE_WITH_CONCERNS | BLOCKED
- Files modified (list)
- Fixes applied (list by finding)
- Skipped findings and why
---

---

## Phase 4: Findings Report

Write `docs/quality/accessibility_review.md` (create `docs/quality/` if needed):

```markdown
# Accessibility Review — [App/Screen Name]
Date: [today's date]
Audited by: /flutterforge:flutter-accessibility

## Summary
- Blocker: N findings (N fixed, N remaining)
- High: N findings
- Medium: N findings
- Low: N findings

## Findings by Screen

### [ScreenName]
| Severity | Finding | Fix Applied | Notes |
|---|---|---|---|

## Manual Testing Required
- [ ] Test with TalkBack on Android (Settings → Accessibility → TalkBack)
- [ ] Test with VoiceOver on iOS (Settings → Accessibility → VoiceOver)
- [ ] Test at 1.3x text scale (Settings → Accessibility → Larger Text)
- [ ] Verify focus order is top-to-bottom, left-to-right with keyboard navigation
```

Display the summary inline in the conversation. If there are remaining BLOCKER findings, list them explicitly and say: "These must be resolved before release."
