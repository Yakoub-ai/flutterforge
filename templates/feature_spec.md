# Feature Spec: [FEATURE NAME]

<!-- Instruction: Write this before implementation, after the app brief and technical plan exist. A spec forces you to discover ambiguities on paper rather than in code. Get sign-off before building. -->

**Status:** `draft` | `approved` | `in-progress` | `done`
**Author:** [PLACEHOLDER — @username]
**Date:** [PLACEHOLDER — YYYY-MM-DD]
**Target milestone:** [PLACEHOLDER — e.g., MVP / v1.1]

---

## Goal

<!-- Instruction: One sentence. What problem does this feature solve for the user? If you can't write one sentence, the feature isn't defined well enough yet. -->

[PLACEHOLDER — e.g., "Allow users to log a new EV charging session in under 30 seconds so they have an accurate monthly cost record."]

---

## User Story

<!-- Instruction: Use the standard format. One primary story per spec — if you need multiple, consider splitting the feature. -->

**Primary:**
As a [PLACEHOLDER — e.g., logged-in EV driver], I want to [PLACEHOLDER — e.g., log a charging session with location, cost, and duration], so that [PLACEHOLDER — e.g., I can track my monthly charging expenses without manual spreadsheet entry].

**Acceptance criteria:**
- [ ] [PLACEHOLDER — e.g., User can create a session from the home screen in ≤3 taps]
- [ ] [PLACEHOLDER — e.g., Session is saved locally and synced to cloud when online]
- [ ] [PLACEHOLDER — e.g., Newly created session appears in session list immediately]
- [ ] [PLACEHOLDER — e.g., Validation prevents saving a session with 0 cost and 0 duration]

---

## Entry Points

<!-- Instruction: List every place in the app that can lead a user to this feature. -->

- [PLACEHOLDER — e.g., Home screen FAB "+" button]
- [PLACEHOLDER — e.g., Session list screen "Add session" empty state CTA]
- [PLACEHOLDER — e.g., Deep link: `app://sessions/new`]

---

## Screens Affected

<!-- Instruction: List each screen by name. Note whether it's new or modified. -->

| Screen | New / Modified | Notes |
|--------|---------------|-------|
| [PLACEHOLDER — e.g., NewSessionScreen] | New | [PLACEHOLDER — e.g., Full-screen form, modal presentation on iOS] |
| [PLACEHOLDER — e.g., HomeScreen] | Modified | [PLACEHOLDER — e.g., FAB added] |
| [PLACEHOLDER — e.g., SessionListScreen] | Modified | [PLACEHOLDER — e.g., New item animates in after save] |

---

## UI States

<!-- Instruction: Every screen must handle all relevant states. Defining them here prevents "we forgot the empty state" conversations during review. -->

| State | Trigger | What the user sees |
|-------|---------|-------------------|
| Loading | Form submitting | [PLACEHOLDER — e.g., Submit button replaced with spinner, form fields disabled] |
| Success | Session saved | [PLACEHOLDER — e.g., Screen dismisses, success snackbar on previous screen] |
| Validation error | Submit with invalid data | [PLACEHOLDER — e.g., Inline field error messages, no network call made] |
| Network error | Save fails due to connectivity | [PLACEHOLDER — e.g., Error banner with "Saved offline — will sync when connected"] |
| Offline | No connection | [PLACEHOLDER — e.g., Offline indicator in app bar, save still works locally] |
| Empty (list) | No sessions yet | [PLACEHOLDER — e.g., Illustration + "Log your first session" CTA] |

---

## State Requirements

<!-- Instruction: What data/state must exist in the app for this feature to work? -->

- [PLACEHOLDER — e.g., Authenticated user (userId available from AuthProvider)]
- [PLACEHOLDER — e.g., SessionFormState — tracks form field values, validation status, submission state]
- [PLACEHOLDER — e.g., SessionListState — must be invalidated after successful save so list refreshes]

---

## Data Requirements

<!-- Instruction: Define the data model for this feature. Use exact field names you'll use in code. -->

**Session entity:**

```dart
class Session {
  final String id;            // UUID, generated client-side
  final String userId;        // from auth
  final DateTime startedAt;
  final int durationMinutes;
  final double costInCents;   // stored as int cents to avoid float rounding
  final String? networkName;  // nullable — user may not know
  final String? locationName; // nullable — reverse geocoded or typed
  final String? notes;        // optional freetext
  final bool isSynced;        // local-only flag
}
```

---

## API Requirements

<!-- Instruction: Define the API contract before implementation. If the backend isn't built yet, this is the spec for the backend developer. -->

**Create session**

```
POST /sessions
Authorization: Bearer {token}

Request body:
{
  "id": "uuid",
  "started_at": "ISO8601",
  "duration_minutes": 45,
  "cost_in_cents": 1250,
  "network_name": "Electrify America",
  "location_name": "Whole Foods Palo Alto",
  "notes": null
}

Response 201:
{
  "id": "uuid",
  "created_at": "ISO8601"
}

Response 422:
{
  "error": "validation_failed",
  "fields": { "duration_minutes": "must be greater than 0" }
}
```

**[PLACEHOLDER — additional endpoints as needed]**

---

## Business Logic Rules

<!-- Instruction: State every rule that isn't obvious from the UI. These are the rules unit tests will verify. -->

- [PLACEHOLDER — e.g., Cost and duration cannot both be 0 — at least one must be positive]
- [PLACEHOLDER — e.g., Session date cannot be in the future]
- [PLACEHOLDER — e.g., Duration max is 1440 minutes (24 hours)]
- [PLACEHOLDER — e.g., Cost stored in cents — multiply user-entered dollar value by 100 before saving]
- [PLACEHOLDER — e.g., If device is offline, session is saved to local DB and synced on next connectivity event]

---

## Error Handling

<!-- Instruction: What happens when each thing can go wrong? -->

| Scenario | Behavior |
|----------|---------|
| [PLACEHOLDER — e.g., Network timeout on save] | [PLACEHOLDER — e.g., Save to local DB, show "Saved offline" confirmation, retry in background] |
| [PLACEHOLDER — e.g., Server returns 422 validation error] | [PLACEHOLDER — e.g., Show field-level errors from server response] |
| [PLACEHOLDER — e.g., Auth token expired mid-save] | [PLACEHOLDER — e.g., Trigger silent token refresh, retry once, else redirect to login] |
| [PLACEHOLDER — e.g., Duplicate session ID (retry race)] | [PLACEHOLDER — e.g., Server returns 409; treat as success, discard duplicate] |

---

## Analytics Events

<!-- Instruction: Define tracking events here so they're not forgotten. Use `snake_case` event names. -->

| Event | Trigger | Properties |
|-------|---------|-----------|
| `session_form_opened` | User taps entry point | `entry_point: string` |
| `session_saved` | Successful save | `duration_minutes: int, cost_cents: int, is_offline: bool` |
| `session_save_failed` | Save fails | `error_type: string` |
| [PLACEHOLDER] | [PLACEHOLDER] | [PLACEHOLDER] |

---

## Accessibility Notes

<!-- Instruction: Define accessibility requirements before building — retrofitting is significantly harder. -->

- [PLACEHOLDER — e.g., All form fields have semantic labels (not just visual placeholder text)]
- [PLACEHOLDER — e.g., Submit button announces loading state to screen readers via `semanticsLabel`]
- [PLACEHOLDER — e.g., Error messages are associated with their input field via `Semantics.errorText`]
- [PLACEHOLDER — e.g., Minimum tap target size: 48×48dp for all interactive elements]
- [PLACEHOLDER — e.g., Color is not the sole indicator of validation state — use icon + text]

---

## Test Cases

<!-- Instruction: Not implementation details — just what must be tested. The test plan template has the how. -->

**Unit (use cases / business logic):**
- [ ] [PLACEHOLDER — e.g., CreateSessionUseCase returns failure when cost and duration are both 0]
- [ ] [PLACEHOLDER — e.g., CreateSessionUseCase saves locally when offline]
- [ ] [PLACEHOLDER — e.g., Cost conversion: $12.50 input → 1250 cents stored]

**Widget:**
- [ ] [PLACEHOLDER — e.g., NewSessionScreen renders all form fields]
- [ ] [PLACEHOLDER — e.g., Submit button shows spinner while loading state is active]
- [ ] [PLACEHOLDER — e.g., Validation error messages appear below fields on invalid submit]

**Integration:**
- [ ] [PLACEHOLDER — e.g., Complete flow: open form → fill fields → submit → session appears in list]

---

## Out of Scope

<!-- Instruction: Explicitly list what this feature does NOT include. Prevents scope creep mid-build. -->

- [PLACEHOLDER — e.g., Editing an existing session (separate feature, post-MVP)]
- [PLACEHOLDER — e.g., Auto-detecting charging network from GPS location (future feature)]
- [PLACEHOLDER — e.g., Bulk import from CSV (backlog)]

---

## Open Questions

<!-- Instruction: Unresolved questions that could change implementation. Resolve before building starts. -->

- [ ] [PLACEHOLDER — e.g., Should cost input be in the user's local currency or always USD? — Owner: @PM — Due: date]
- [ ] [PLACEHOLDER — e.g., What happens to offline sessions if user deletes the app? Lost or recoverable? — Owner: @tech-lead]
- [ ] [PLACEHOLDER]
