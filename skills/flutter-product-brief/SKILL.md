---
name: flutter-product-brief
version: 1.0.0
description: >-
  Use this skill when the user wants to plan a new Flutter app, convert a vague
  idea into a concrete product brief, or define what to build before writing code.
  Trigger phrases: "plan a new Flutter app", "I want to build an app",
  "write a product brief", "help me brainstorm my app idea",
  "what should I build", "define my MVP", "I have an app idea",
  "help me plan my Flutter app", "let's scope this app",
  "I want to make an app that", "what features should my app have",
  "help me think through my app", "create a product brief".
  Also use when: the user describes a problem they want to solve with a mobile
  app, or asks what the minimum viable product should include.
---

# Flutter Product Brief

Transform a vague app idea into a structured product brief with user stories
and MVP scope — before any architecture or code is considered.

**Guiding principle:** Clarity before code. Do not generate architecture,
suggest packages, or write any code during this skill. Output is documents.

---

## Discovery Approach

Ask questions conversationally — not as a numbered form fired all at once.
Start with the most important question, listen, probe if the answer is vague,
then move on. Aim to complete discovery in one focused conversation.

If the user says "I don't know," record as TBD and flag as a risk.

---

## The 10 Discovery Questions

### 1. The Problem
"What problem does this app solve? And who actually experiences it day-to-day?"

Probe if: the answer describes a feature ("share photos") not a pain point. Ask: "What is someone doing right now without this app? What breaks down for them?"

### 2. The Users
"Who is the primary user — the person who uses this every day? Any secondary users (admin, viewer)?"

Probe if: answer is a demographic bucket. Ask: "What is this person doing in their life that makes this app relevant?"

### 3. Success Definition
"What does success look like in 6 months? If you had to pick one measurable number, what would it be?"

Probe if: answer is qualitative only. Ask: "What stat would you lead with in an investor conversation?"

### 4. Must-Have Features (MVP)
"What are the 3 features this app absolutely must have on day one? If you removed any one, the app wouldn't work."

Enforce the 3-feature constraint — push back on lists of 6+. Probe: "If you could only ship one, which would it be?"

### 5. Nice-to-Have Features (Post-MVP)
"What would be great eventually but is not needed for V1?"

This list is as important as the must-haves — it contains scope creep.

### 6. Target Platforms
"iOS only, Android only, or both? Web ever in scope?"

Probe if "both" with no thought: "Do your users skew one platform?"

### 7. Required Integrations
Cover conversationally:
- **Auth:** email/password, Google, Apple, phone?
- **Payments:** in-app, subscription, one-time? Which provider?
- **Hardware:** camera, GPS, microphone, biometrics, NFC, Bluetooth?
- **Push notifications:** required for core loop?
- **Backend:** existing API, Firebase, Supabase, build from scratch?
- **Storage:** remote file, offline, local-only?

### 8. Scale Expectations
"How many users in the first 6 months? Data-heavy (video, images) or data-light (text, settings)?"

Gently calibrate if a solo developer says "millions."

### 9. Competitive Landscape
"Existing apps that do something similar? What does yours do differently?"

Probe if "nothing like it" — ask: "What do people use today, even if it's a spreadsheet?"

### 10. Timeline
"When do you need a first version in users' hands? Hard or soft deadline?"

Probe "as soon as possible" — ask for a realistic date. Flag scope mismatches.

---

## Output Documents

### `docs/product/app_brief.md`

```markdown
# App Brief: [App Name]

## Problem Statement
## Primary User
## Secondary Users (if any)
## Success Metric
## Target Platforms
## Required Integrations
## Scale Expectations
## Competitive Landscape
## Timeline
## Open Questions / TBDs
```

### `docs/product/user_stories.md`

Format for each story:
> As a [persona], I want to [action] so that [outcome].

**Acceptance Criteria:**
- [ ] Given [context], when [action], then [result]

Write a minimum of 5 stories (3 for MVP features + 2 supporting: onboarding, error/empty state). Stories must be testable and describe user value, not technical implementation.

### `docs/product/mvp_scope.md`

```markdown
## In Scope (Launch)
| Feature | Description | Priority | Complexity |

## Out of Scope (Post-MVP Backlog)
| Feature | Reason Deferred | Target Phase |

## Explicitly Excluded
[Features the user said are NOT needed — prevents future scope creep debates.]

## Risks and Assumptions
| Risk | Likelihood | Impact | Mitigation |
```

---

## Rules

- Do not generate architecture, packages, or code during this skill.
- Ask conversationally — never dump all 10 questions at once.
- Probe before advancing if an answer is vague or incomplete.
- Never assume monetization, analytics, or backend unless explicitly mentioned.
- Never assume platform unless explicitly confirmed.
- Do not judge the idea — clarify and structure it.
- When in doubt about scope: "Is this needed to solve the core problem?" If no → post-MVP backlog.

---

## Output Artifacts

- `docs/product/app_brief.md`
- `docs/product/user_stories.md`
- `docs/product/mvp_scope.md`

Create `docs/product/` if it does not exist. If `templates/app_brief.md` exists, use its structure.

---

## Cross-references

- Next skill: `flutter-architecture` (after brief is approved)
- Next skill: `flutter-ux-design` (after architecture is approved)
- Agent: `product-strategist`
