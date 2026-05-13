---
name: flutter-accessibility
version: 1.0.0
description: >-
  Audit and improve accessibility in Flutter apps. Use when the user wants to
  check WCAG compliance, add semantic labels, verify screen reader support, or
  review tap target sizes and text scaling behavior.
  Trigger phrases: "check accessibility Flutter", "add semantic labels", "a11y Flutter",
  "screen reader Flutter", "accessibility audit", "TalkBack Flutter", "VoiceOver Flutter",
  "WCAG Flutter", "semantic widgets Flutter", "focus order Flutter",
  "text scaling Flutter", "accessible Flutter app".
---

# Flutter Accessibility

Audit and improve accessibility in Flutter apps. Target: WCAG 2.1 AA, full TalkBack (Android) and VoiceOver (iOS) support, comfortable usability at 2x text scale.

---

## Workflow

1. **Discover the app surface** — list all screens, interactive elements, and images.
2. **Audit each screen against the checklist** below, one screen at a time.
3. **Identify findings** — severity: blocker / high / medium / low.
4. **Implement fixes** with the `ux-mobile-designer` agent for UI changes.
5. **Verify with device testing** — test with TalkBack on Android, VoiceOver on iOS.
6. **Write `docs/quality/accessibility_review.md`** with findings and fix status.

---

## Accessibility Checklist (per screen)

### Color and Contrast
- [ ] Body text: ≥ 4.5:1 contrast ratio against background
- [ ] Large text (18pt+ / 14pt+ bold): ≥ 3:1 contrast ratio
- [ ] UI component boundaries (buttons, inputs): ≥ 3:1 contrast ratio
- [ ] Information is not conveyed by color alone — always a secondary indicator (icon, text, pattern)

### Touch Targets
- [ ] All interactive elements ≥ 48×48 dp (WCAG) — prefer 56×56 dp minimum
- [ ] Minimum 8 dp gap between adjacent tap targets
- [ ] Gesture alternatives provided for complex gestures (swipe to delete → button fallback)

### Text and Layout
- [ ] UI does not overflow or clip at 1.3x text scale
- [ ] All text uses `TextTheme` / relative font sizes — no hardcoded `fontSize` in px without `TextScaler` handling
- [ ] Single-axis scroll (never two-dimensional scroll) for main content

### Screen Reader (TalkBack / VoiceOver)
- [ ] Every `Image` has `semanticLabel` or is marked `excludeFromSemantics: true` (decorative)
- [ ] Every `Icon` used as action has `tooltip` or wrapped in `Semantics(label: ...)`
- [ ] Form fields: `TextField` has `decoration.label` or `Semantics(label: ...)`
- [ ] Buttons: meaningful label (not "icon button") — avoid `IconButton` without tooltip
- [ ] `ExcludeSemantics` on decorative widgets that would add noise
- [ ] `MergeSemantics` on groups that should read as one unit (e.g., rating stars)
- [ ] Custom interactive widgets use `Semantics(button: true, onTap: ...)` or `GestureDetector` wrapped in `Semantics`

### Focus and Navigation
- [ ] Focus order follows visual reading order (top-to-bottom, left-to-right)
- [ ] Dialogs and bottom sheets trap focus correctly — focus returns on dismiss
- [ ] No keyboard focus traps (web/desktop targets)

### Error Messages
- [ ] Error messages are descriptive — not just "Invalid input" — say what's wrong
- [ ] Error messages are associated with the field via `Semantics` or `errorText`

---

## Required UI States (per screen)

Every screen must implement these states — each needs semantic support:

| State | Accessibility requirement |
|---|---|
| Loading | `CircularProgressIndicator` has `Semantics(label: 'Loading...')` |
| Empty | `EmptyStateView` has readable label, not just an icon |
| Error | Error message is readable; retry button labeled clearly |
| Success | State change announced via `SemanticsService.announce()` when needed |
| Offline | Banner readable by screen reader with actionable label |

---

## Common Fixes

| Issue | Fix |
|---|---|
| `IconButton` no label | Add `tooltip: 'Action name'` |
| `Image` no label | Add `semanticLabel: 'Description'` or `excludeSemantics: true` |
| Text overflow at 1.3x | Use `Flexible`/`Expanded`, remove `maxLines` constraints, test with `MediaQuery.textScalerOf` |
| Tap target too small | Wrap in `SizedBox(width: 48, height: 48)` + `Center()` |
| Decoration-only icon read aloud | Wrap in `ExcludeSemantics(child: Icon(...))` |

---

## Output Artifacts

- `docs/quality/accessibility_review.md` — per-screen findings with severity and fix status

---

## Cross-references

- Agent: `ux-mobile-designer` (implementation pass for UI fixes)
- Command: `/flutterforge:flutter-accessibility` invokes this skill directly
