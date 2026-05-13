---
description: "FlutterForge — Flutter development workflow hub. Choose your mode or describe what you need."
argument-hint: "[mode or description]"
allowed-tools: ["Read", "Glob", "Bash", "Task", "Write", "TodoWrite"]
---

You are running `/flutterforge:flutterforge`, the FlutterForge workflow hub.

## Workflow Modes

FlutterForge has 10 modes:

1. **Plan new app** → `/flutterforge:plan-flutter-app` — product brief, UX flows, and architecture before any code
2. **Create new app** → `/flutterforge:new-flutter-app` — scaffold a production-ready Flutter project from scratch
3. **Build a feature** → `/flutterforge:build-flutter-feature` — inspect → plan → implement → test → validate
4. **Audit existing app** → `/flutterforge:audit-flutter-app` — code quality, architecture, and dependency review
5. **Debug an issue** → `/flutterforge:debug-flutter` — trace errors, read logs, and resolve root causes
6. **Generate tests** → `/flutterforge:generate-tests` — add unit, widget, and integration test coverage
7. **Improve UX** → `/flutterforge:improve-ux` — accessibility, responsiveness, and interaction polish
8. **Prepare release** → `/flutterforge:prepare-release` — versioning, changelogs, build validation, and store prep
9. **Refactor code** → `/flutterforge:refactor-flutter` — safe structural improvements without changing behavior
10. **Accessibility audit** → `/flutterforge:flutter-accessibility` — WCAG 2.1 AA compliance, semantics, contrast, and screen reader support

## Routing Logic

### Mode keyword or number — dispatch immediately

If `$ARGUMENTS` unambiguously matches one of the patterns below, **invoke the target
command directly using the Task tool** without asking for confirmation. Pass any
remaining text after the keyword as the argument to the sub-command.

| Trigger | Target command | Pass-through |
|---|---|---|
| `1`, `plan`, `plan new app`, `plan app` | `/flutterforge:plan-flutter-app` | everything after the trigger word |
| `2`, `create`, `new app`, `scaffold` | `/flutterforge:new-flutter-app` | everything after the trigger word |
| `3`, `feature`, `build feature`, `add feature` | `/flutterforge:build-flutter-feature` | everything after the trigger word |
| `4`, `audit` | `/flutterforge:audit-flutter-app` | everything after the trigger word |
| `5`, `debug` | `/flutterforge:debug-flutter` | everything after the trigger word |
| `6`, `tests`, `generate tests`, `test` | `/flutterforge:generate-tests` | everything after the trigger word |
| `7`, `ux`, `improve ux`, `ui` | `/flutterforge:improve-ux` | everything after the trigger word |
| `8`, `release`, `prepare release`, `publish` | `/flutterforge:prepare-release` | everything after the trigger word |
| `9`, `refactor` | `/flutterforge:refactor-flutter` | everything after the trigger word |
| `10`, `accessibility`, `a11y`, `flutter-accessibility` | `/flutterforge:flutter-accessibility` | everything after the trigger word |

Example: `/flutterforge:flutterforge plan a social fitness app` → immediately invokes
`/flutterforge:plan-flutter-app` with `"a social fitness app"` as the argument.

### Natural language — route with confirmation

If `$ARGUMENTS` is a sentence that does not start with a clear mode keyword or number,
identify the best-fit mode, explain your reasoning in one sentence, print the exact
command to run with the description pre-filled, and ask: "Run this command? Reply 'yes'
to confirm or give me a different description."

This confirmation step prevents accidental dispatch when the intent is ambiguous
(e.g. "refactor and also add tests" could be two commands, not one).

### No arguments — show the menu

Print the numbered list above and ask:
"Which workflow do you want to run? Reply with a number (1–10), a mode name, or describe what you need."

Do not write any files. This command dispatches workflows — it does not implement them.
