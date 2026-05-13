---
name: flutter-ux-design
version: 1.0.0
description: >-
  Use this skill when the user wants to design the UX, plan screens, define
  navigation flows, or establish a design system for a Flutter app — before
  implementation begins. Trigger phrases: "design Flutter UX", "create screen flow",
  "plan app screens", "help with mobile UI", "design system Flutter",
  "what screens do I need", "design the UI for my Flutter app",
  "define the navigation", "create a component inventory",
  "help me plan the screens", "what widgets do I need",
  "design the onboarding flow", "map out the user flows",
  "define the color palette", "set up the theme for my Flutter app",
  "plan the accessibility", "design the empty states".
  Also use when: the product brief is complete and the user is ready to define
  the visual and interaction design before writing any widget code.
---

# Flutter UX Design

A structured methodology for defining the mobile user experience — screens,
navigation, UI states, design system, and component inventory — before a single
widget is coded.

**Guiding principle:** Every screen must be fully designed before it is implemented.
"Fully designed" means every UI state is defined, every navigation path is
explicit, and every reusable component is named. Do not generate code during this
skill — output is documents, not implementation.

---

## Workflow

1. **Screen inventory** — list every screen with name, purpose, entry point, exit points, and access control.
2. **Navigation flow** — define the app's navigation tree and navigation type per transition.
3. **UI states** — define all five states (loading, success, empty, error, offline) for every screen.
4. **Design system** — define color roles, typography scale, spacing, border radius, and elevation.
5. **Component inventory** — list every reusable widget with variants, props, and screen usage.
6. **Accessibility** — document tap target, contrast, semantic label, and text-scaling requirements as acceptance criteria.
7. **Write output artifacts** below.

---

## Step 1: Screen Inventory

For each screen:

| Field | Description |
|---|---|
| Name | Identifier used in code, routes, tests |
| Purpose | One sentence: what does the user accomplish here? |
| Entry Point | App launch / tab tap / button press / deep link |
| Exit Points | Where can the user navigate from here? |
| Access Control | Unauthenticated / authenticated / admin |

Group screens by feature area. If screen count exceeds MVP scope, flag discrepancy and ask which are required for launch.

---

## Step 2: Navigation Flow

**Navigation types:**

| Type | Use when |
|---|---|
| `BottomNavigationBar` / `NavigationBar` | Top-level sections (3–5 tabs max) |
| Stack push/pop | Drill-down within a section |
| `showModalBottomSheet` / `showDialog` | Temporary overlays, quick actions, lightweight forms |
| Full-screen modal push | Flows that interrupt context: camera, checkout, permissions |

**Navigation tree format (indented notation):**

```
App Root
  ├── Unauthenticated Shell
  │   ├── SplashScreen
  │   └── LoginPage
  │       └── [modal] ForgotPasswordBottomSheet
  └── Authenticated Shell (MainNavigationPage)
      ├── Tab 1: HomePage
      │   └── [push] ItemDetailPage
      ├── Tab 2: SearchPage
      └── Tab 3: ProfilePage
          ├── [push] EditProfilePage
          └── [push] SettingsPage
```

For each navigation action: widget that triggers it, data passed to destination, back-navigation guard if applicable.

---

## Step 3: UI States (per screen)

Every screen must define all five states. Mark N/A only with justification.

| State | Requirement |
|---|---|
| Loading | Skeleton layout matching the success state (prefer shimmer over centered spinner for content-heavy screens) |
| Success | Normal state — data rendered correctly |
| Empty | Illustration/icon + heading + supporting message + primary action. Never a blank screen. |
| Error | Heading + human-readable message (not a stack trace) + retry action. Inline if partial, full-screen if entire screen failed. |
| Offline | Applies to apps with offline requirements. Banner + cached data + disabled write actions. |

---

## Step 4: Design System Foundation

All values must be concrete — no TBD, no placeholder colors.

**Color Palette** — define using `ColorScheme` naming convention:

| Role | Purpose |
|---|---|
| `primary` | Primary actions, links, active tabs |
| `onPrimary` | Text/icons on primary color |
| `primaryContainer` | Subtle backgrounds for primary context |
| `secondary` | Secondary actions, badges |
| `error` | Errors, destructive actions |
| `background` | Page backgrounds |
| `surface` | Cards, sheets, dialog backgrounds |
| `outline` | Borders, dividers, inactive icons |

Define dark scheme if dark mode is required. Never use raw hex values in widget code — reference through `Theme.of(context).colorScheme`.

**Typography Scale** — map `TextTheme` slots to content types in this app:

| Slot | Scale | Typical Use |
|---|---|---|
| `headlineLarge` | 32sp | Screen titles |
| `headlineMedium` | 28sp | Card titles, section headings |
| `titleLarge` | 22sp | AppBar titles |
| `titleMedium` | 16sp | List item titles, tab labels |
| `bodyLarge` | 16sp | Primary body text |
| `bodyMedium` | 14sp | Secondary copy |
| `bodySmall` | 12sp | Captions, timestamps |
| `labelLarge` | 14sp | Button labels |

Specify font family and weight variations (400 regular, 500 medium, 700 bold).

**Spacing Scale** (base 4px — define constants in `app_spacing.dart`, no raw doubles in widgets):

```
xs=4 / sm=8 / md=12 / lg=16 / xl=24 / 2xl=32 / 3xl=48 / 4xl=64
```

**Border Radius:** sm=4 / md=8 / lg=12 / xl=16 / full=999

**Elevation:** follow Material 3 tonal elevation (0=background, 1=cards, 3=drawers, 4=FABs, 5=dialogs).

---

## Step 5: Component Inventory

Required baseline for every app:

| Component | Variants | Key Props | Used On |
|---|---|---|---|
| `AppBar` | with back / with actions / search | title, actions | All pushed screens |
| `BottomNavigationBar` | — | tabs (3–5), icon+label | All tab roots |
| `PrimaryButton` | enabled / loading / disabled | label, onPressed, isLoading | Forms, CTAs |
| `OutlinedButton` | enabled / disabled | label, onPressed | Secondary actions |
| `AppTextField` | standard / password / error | label, hint, errorText, obscureText | Forms |
| `LoadingIndicator` | full-screen / inline | — | All loading states |
| `SkeletonLoader` | card / list item / profile | — | Content loading |
| `ErrorView` | full-screen / inline | message, onRetry | Error states |
| `EmptyStateView` | — | illustration, heading, subheading, onAction | Empty states |
| `OfflineBanner` | — | — | Data-dependent screens |
| `AvatarWidget` | network / initials | imageUrl, displayName, size | Profile contexts |
| `CardWidget` | flat / elevated / tappable | child, onTap, padding | Content lists |

Add app-specific components beyond this baseline.

---

## Step 6: Accessibility (as acceptance criteria)

See `flutter-accessibility` skill for the full audit process. Document these as ACs:

- All interactive elements ≥ 48×48 dp tap target
- Body text ≥ 4.5:1 contrast; large text / UI components ≥ 3:1
- Every icon button has `tooltip` or `Semantics(label: ...)`
- Every meaningful `Image` has `semanticLabel`
- No information conveyed by color alone — always a secondary indicator
- UI does not overflow or clip at 1.3x text scale

---

## Design Quality Rules

- No generic defaults — every design decision must be specific to this app's context.
- Every screen requires all five UI states before implementation begins.
- Never placeholder colors or TBD spacing — pick values now; changing later is trivial.
- Platform conventions: iOS avoids FAB as primary CTA; Android uses FAB for creation. iOS uses back-swipe; both use system pickers where appropriate.
- Respect platform conventions for modals (bottom sheets on iOS, dialogs for confirmation).

---

## Output Artifacts

- `docs/ux/screen_map.md` — screen inventory table
- `docs/ux/user_flows.md` — navigation tree + per-flow narrative for 3 critical flows
- `docs/ux/design_system.md` — color palette, typography, spacing, border radius, elevation
- `docs/ux/component_inventory.md` — all components with variants, props, screen usage
- `docs/ux/accessibility_notes.md` — Step 6 checklist as acceptance criteria

---

## Cross-references

- Agent: `ux-mobile-designer` (implements UI changes from this design)
- Accessibility audit: `flutter-accessibility` skill
- Implementation: `flutter-feature-dev` skill
