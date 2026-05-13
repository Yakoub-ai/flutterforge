# UX Review: [SCREEN / FEATURE NAME]

<!-- Instruction: Run this review before marking a feature done. A 20-minute review here prevents days of post-launch fixes. Be honest — unchecked boxes are useful information, not failure. -->

**Reviewer:** [PLACEHOLDER — name]
**Review Date:** [PLACEHOLDER — YYYY-MM-DD]
**Build / Commit:** [PLACEHOLDER — commit SHA or build number]
**Devices Tested:** [PLACEHOLDER — e.g., iPhone 15 Pro (iOS 17.2), Pixel 7 (Android 14), iPad Air 5]

---

## Information Hierarchy

<!-- Instruction: Is the most important content the most visually prominent? Does the page communicate its purpose within 3 seconds? -->

- [ ] Primary action is visually prominent and obvious
- [ ] Page communicates its purpose without reading body text
- [ ] Content is ordered by user priority, not developer convenience
- [ ] Related items are grouped; unrelated items are separated

**Notes:** [PLACEHOLDER — observations or issues found]

---

## Navigation

<!-- Instruction: Can users get in, accomplish their goal, and get out without confusion? -->

- [ ] Clear entry point to this screen from expected places
- [ ] Back navigation works correctly (hardware back on Android, swipe-back on iOS)
- [ ] Destructive actions (delete, discard) have confirmation or undo
- [ ] User is never stranded — there is always a path forward
- [ ] Deep links work correctly if supported

**Notes:** [PLACEHOLDER]

---

## UI States Coverage

<!-- Instruction: Every screen must handle all states it can be in. ✅ = implemented and looks good, ❌ = missing or broken, N/A = not applicable. -->

| State | Status | Notes |
|-------|--------|-------|
| Loading | [✅ / ❌ / N/A] | [PLACEHOLDER — e.g., Skeleton visible, no layout shift] |
| Success / data loaded | [✅ / ❌ / N/A] | [PLACEHOLDER] |
| Empty (no data yet) | [✅ / ❌ / N/A] | [PLACEHOLDER — e.g., Empty state with helpful CTA] |
| Error (recoverable) | [✅ / ❌ / N/A] | [PLACEHOLDER — e.g., Error banner with retry action] |
| Offline | [✅ / ❌ / N/A] | [PLACEHOLDER — e.g., Offline indicator shown] |
| Partial data / degraded | [✅ / ❌ / N/A] | [PLACEHOLDER] |

---

## Accessibility

<!-- Instruction: Test with VoiceOver (iOS) or TalkBack (Android) enabled. Don't skip this. -->

- [ ] All interactive elements have a minimum 48×48dp tap target
- [ ] Color contrast ratio meets WCAG AA (4.5:1 for text, 3:1 for large text and UI components)
- [ ] Color is not the sole differentiator (icons + text used alongside color)
- [ ] All images and icons have semantic labels or are marked decorative
- [ ] Screen reader announces meaningful element order (test with eyes closed)
- [ ] Form fields announce labels, not just placeholder text
- [ ] Error messages are associated with their fields (not just visually near them)
- [ ] Animated content respects `prefers-reduced-motion` / `AccessibilityFeatures.reduceMotion`
- [ ] Focus order is logical when using keyboard or switch access

**Screen reader test notes:** [PLACEHOLDER — observations from VoiceOver/TalkBack walkthrough]

---

## Responsiveness

<!-- Instruction: Test in all three contexts. Flutter clips, not wraps — overflow issues are common. -->

| Context | Status | Notes |
|---------|--------|-------|
| Phone portrait | [✅ / ❌] | [PLACEHOLDER — e.g., Tested on 375pt and 414pt widths] |
| Phone landscape | [✅ / ❌] | [PLACEHOLDER — e.g., Keyboard pushes content correctly] |
| Tablet (≥600dp) | [✅ / ❌ / N/A] | [PLACEHOLDER — e.g., Layout adapts or is excluded by design] |
| Large text sizes (Accessibility > Large Text) | [✅ / ❌] | [PLACEHOLDER — e.g., No overflow, text scales correctly] |

---

## Dark Mode

<!-- Instruction: If the app supports dark mode, both themes must look intentional, not accidental. -->

- [ ] Dark mode supported
- [ ] All text is readable in dark mode (no hardcoded light colors)
- [ ] Images and icons look correct in dark mode (no invisible assets)
- [ ] No hardcoded colors — all colors reference theme tokens

**Notes:** [PLACEHOLDER — any dark mode specific issues]

---

## Typography

<!-- Instruction: Typography hierarchy helps users scan content. Inconsistency breaks trust. -->

- [ ] Clear visual hierarchy: heading → subheading → body → caption
- [ ] Body text line length is comfortable (45–75 characters, ~320-600dp)
- [ ] No walls of text — long content is broken up
- [ ] Font sizes scale correctly with system text size settings
- [ ] No truncation of important content (check all text overflow: ellipsis cases)

**Notes:** [PLACEHOLDER]

---

## Spacing and Layout

<!-- Instruction: Consistent spacing makes apps feel polished. Inconsistency is perceived as low quality. -->

- [ ] Padding and margins use the design system scale (e.g., multiples of 4dp or 8dp)
- [ ] No hardcoded pixel values that break at different screen densities
- [ ] No pixel overflow (run `flutter analyze` and use the overflow checker)
- [ ] Visual groups have consistent internal spacing
- [ ] Scrollable content has correct bottom padding (doesn't hide under nav bar or FAB)

**Notes:** [PLACEHOLDER]

---

## Interactions

<!-- Instruction: Interactions should be purposeful. Ask: does this animation inform or delight? Or does it just slow the user down? -->

- [ ] Buttons and tappable areas give immediate visual feedback (ink splash or state change)
- [ ] Loading animations don't block user input unnecessarily
- [ ] Transitions communicate navigation direction (forward vs. back)
- [ ] No janky animations — 60fps on mid-range devices
- [ ] Haptic feedback used contextually (success, error, selection) — not overused
- [ ] Long-press, swipe, and drag interactions have visible affordances or are discoverable

**Notes:** [PLACEHOLDER]

---

## Platform Conventions

<!-- Instruction: iOS and Android users have different expectations. Violating conventions creates friction. -->

- [ ] iOS: Back swipe gesture works throughout the feature
- [ ] iOS: Bottom sheet dismiss by swiping down works where expected
- [ ] iOS: Action sheets used instead of dialog buttons where appropriate
- [ ] Android: Hardware back button handled correctly
- [ ] Android: Predictive back gesture works (Android 13+)
- [ ] Platform-specific date/time pickers used (not a custom widget that looks wrong on both)
- [ ] Status bar and navigation bar colors adapt to screen content

**Notes:** [PLACEHOLDER]

---

## Microcopy

<!-- Instruction: Words matter as much as pixels. Bad labels cause confusion and support tickets. -->

- [ ] Button labels describe the action, not just "OK" or "Confirm"
- [ ] Error messages explain what went wrong AND what the user can do about it
- [ ] Empty states are helpful, not just "No data"
- [ ] Loading messages are specific (not just a spinner with no context)
- [ ] Destructive action confirmations name the thing being deleted
- [ ] No lorem ipsum, "TBD", or developer placeholder text in any state

**Microcopy issues:** [PLACEHOLDER — list any labels/messages that need rewording]

---

## Loading Experience

<!-- Instruction: Users judge load times. A skeleton screen feels faster than a blank screen even if the data takes the same time. -->

- [ ] Skeleton screens or shimmer used instead of spinner-only for list/card layouts
- [ ] Progress indicators show for operations taking more than 300ms
- [ ] Stale content shown immediately while fresh data loads (where cached)
- [ ] First paint is useful — not a blank screen or just a nav bar

**Notes:** [PLACEHOLDER]

---

## Overall Assessment

**Score:** [1 / 2 / 3 / 4 / 5] — (1 = needs significant rework, 5 = ship it)

**Priority Issues (must fix before shipping):**

1. [PLACEHOLDER — e.g., Error state missing on session form — shows blank screen on network failure]
2. [PLACEHOLDER — e.g., Tap targets on filter chips are 36dp — below the 48dp minimum]
3. [PLACEHOLDER]

**Minor Issues (fix when convenient):**

- [PLACEHOLDER — e.g., Loading message says "Loading..." — should say "Loading your sessions..."]
- [PLACEHOLDER]

**What works well:**

- [PLACEHOLDER — e.g., Skeleton loading looks great and avoids layout shift]
- [PLACEHOLDER — e.g., Empty state copy is helpful and has a clear CTA]
