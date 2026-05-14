# FlutterForge

> End-to-end Flutter mobile app development workflow plugin for Claude Code.

FlutterForge guides development teams from idea to release-ready Flutter app using specialized agents, reusable skills, quality hooks, and phased subagent workflows — all inside Claude Code.

**Plan like a product team. Design like a mobile UX expert. Code like a senior Flutter engineer. Test like a QA engineer. Debug like a production maintainer. Release like a mobile DevOps engineer.**

---

## Contents

- [Install](#install)
- [Quick Start](#quick-start)
- [Commands](#commands)
- [Agents](#agents)
- [Skills](#skills)
- [Hooks](#hooks)
- [MCP Integrations](#mcp-integrations)
- [Configuration](#configuration)
- [Portable Skills and Agents](#portable-skills-and-agents)
- [Templates](#templates)
- [Examples](#examples)
- [Contributing](#contributing)

---

## Prerequisites

- **Flutter SDK ≥ 3.x** — [flutter.dev/get-started](https://docs.flutter.dev/get-started/install)
- **Node.js ≥ 18** — ships with Claude Code; required for hooks
- **Claude Code** — [claude.ai/code](https://claude.ai/code) or the VS Code / JetBrains extension

Optional (required only for the corresponding MCP integration):
- `firebase-tools` (`npm i -g firebase-tools && firebase login`) for Firebase MCP
- `GITHUB_PERSONAL_ACCESS_TOKEN` env var for GitHub MCP
- `SUPABASE_ACCESS_TOKEN` env var for Supabase MCP
- `FIGMA_API_KEY` env var for Figma MCP

---

## Install

### Option A — Install via Claude Code marketplace (recommended)

Inside any Claude Code session:

```bash
/plugin marketplace add Yakoub-ai/flutterforge
/plugin install flutterforge@flutterforge
```

Once installed, start FlutterForge with:

```bash
claude
```

### Option B — Local clone (for contributors or offline use)

Clone the repo once and launch Claude Code with the plugin directory pointed at the clone:

```bash
git clone https://github.com/Yakoub-ai/flutterforge.git
claude --plugin-dir ./flutterforge
```

> **Tip:** If you work in the same Flutter project most days, add a shell alias:
> ```bash
> alias flutterforge='claude --plugin-dir /absolute/path/to/flutterforge'
> ```
> Then just type `flutterforge` to start a Claude session with the plugin loaded.

### Verify installation

Inside the launched Claude Code session, run `/flutterforge:flutterforge` — you should see the FlutterForge workflow menu.

If hooks do not fire, ensure Node.js is on your PATH (`node --version` should print `v18` or later) and that you launched Claude from a shell where `node` resolves.

---

## Quick Start

### New Flutter app (greenfield)

```
/flutterforge:plan-flutter-app I want to build a social fitness app where friends compete on weekly challenges
```

This runs a 3-phase workflow:
1. **Product strategist** produces app brief, MVP scope, user stories
2. **UX designer + Flutter architect** work in parallel on screen flows and architecture
3. You approve the plan before any code is written

Then scaffold:

```
/flutterforge:new-flutter-app
```

### Add a feature to an existing app

```
/flutterforge:build-flutter-feature Add a leaderboard screen that shows weekly challenge rankings
```

### Audit before a release

```
/flutterforge:audit-flutter-app
```

Runs 5 agents in parallel: architecture audit, security review, performance check, test coverage review, release readiness check.

---

## Commands

All commands are available as `/flutterforge:<command>` or via the main `/flutterforge:flutterforge` menu.

| Command | Purpose | Agents Used |
|---|---|---|
| `/flutterforge:flutterforge` | Workflow menu — pick your mode | (router) |
| `/flutterforge:plan-flutter-app` | Brainstorm + architecture plan | product-strategist, ux-mobile-designer, flutter-architect |
| `/flutterforge:new-flutter-app` | Scaffold new Flutter project | flutter-architect, flutter-implementation-engineer, flutter-test-engineer |
| `/flutterforge:build-flutter-feature` | Implement a feature with tests | flutter-architect, flutter-implementation-engineer, flutter-test-engineer |
| `/flutterforge:audit-flutter-app` | Full app audit (5 parallel agents) | codebase-auditor, mobile-security-reviewer, mobile-performance-engineer, flutter-test-engineer, release-engineer |
| `/flutterforge:debug-flutter` | Root-cause debug and fix | flutter-debugger, flutter-test-engineer |
| `/flutterforge:generate-tests` | Generate unit + widget tests | flutter-test-engineer |
| `/flutterforge:improve-ux` | UX analysis and UI improvements | ux-mobile-designer, flutter-implementation-engineer |
| `/flutterforge:prepare-release` | Android + iOS release checklist | release-engineer, mobile-security-reviewer |
| `/flutterforge:refactor-flutter` | LSP-guided safe refactoring | codebase-auditor, flutter-implementation-engineer |
| `/flutterforge:flutter-accessibility` | Accessibility audit and WCAG 2.1 AA improvements | ux-mobile-designer |

---

## Agents

Agents are dispatched by commands using the Task tool for isolated-context execution. Each agent is scoped to its expertise and avoids context pollution from the main session.

| Agent | Role | Model |
|---|---|---|
| `product-strategist` | Converts app ideas into product briefs with user stories, MVP scope, metrics | opus |
| `flutter-architect` | Architecture decisions, folder structure, state management, ADRs | opus |
| `ux-mobile-designer` | Screen flows, design system, component inventory, accessibility | sonnet |
| `flutter-implementation-engineer` | Clean Flutter code following project architecture | sonnet |
| `state-management-specialist` | Riverpod/Bloc/Cubit design, async handling, rebuild optimization | sonnet |
| `api-integration-engineer` | REST/Firebase/Supabase clients, repositories, DTOs, offline patterns | sonnet |
| `flutter-test-engineer` | Unit, widget, integration, golden test strategy and generation | sonnet |
| `flutter-debugger` | Stack trace analysis, root cause, minimal patch, regression tests | sonnet |
| `mobile-performance-engineer` | Rebuild analysis, list optimization, image caching, profiling guidance | sonnet |
| `mobile-security-reviewer` | Secrets detection, permissions, auth flows, storage security | sonnet |
| `release-engineer` | Android/iOS build readiness, store metadata, CI/CD checklist | sonnet |
| `codebase-auditor` | Architecture drift, anti-patterns, unused deps, refactor prioritization | sonnet |

---

## Skills

Skills are invoked by agents (and by Claude directly when trigger phrases match). Each skill documents a complete methodology.

| Skill | Trigger | Output |
|---|---|---|
| `flutter-app-discovery` | "audit existing Flutter app", "understand this Flutter codebase" | Architecture summary, dependency audit, risks |
| `flutter-product-brief` | "plan a Flutter app", "write a product brief" | Brief, personas, user stories, MVP scope |
| `flutter-architecture` | "design Flutter architecture", "choose state management" | ADR, folder structure, dependency list |
| `flutter-ux-design` | "design Flutter UX", "create screen flow" | Screen map, user flows, component inventory |
| `flutter-feature-dev` | "build Flutter feature", "implement Flutter screen" | Feature spec, implementation, tests |
| `flutter-state-management` | "Riverpod", "Bloc", "manage state in Flutter" | State model, provider design, test strategy |
| `flutter-api-integration` | "integrate API", "connect Firebase", "add Supabase" | API client, repositories, DTOs, mocks |
| `flutter-testing` | "write Flutter tests", "generate tests" | Test plan, unit tests, widget tests |
| `flutter-debugging` | "debug Flutter", "fix Flutter error", "stack trace" | Root cause, patch, validation commands |
| `flutter-performance` | "optimize Flutter", "fix jank", "improve performance" | Performance findings, prioritized fixes |
| `flutter-accessibility` | "check accessibility", "add semantics", "a11y" | Accessibility findings, semantic improvements |
| `flutter-security` | "security review", "check secrets", "Flutter security" | Security risks, fixes, permission review |
| `flutter-release-readiness` | "prepare release", "app store", "publish Flutter app" | Android + iOS checklist, build commands |
| `flutter-documentation` | "generate docs", "update README", "document Flutter" | README updates, architecture docs, feature docs |

---

## Hooks

FlutterForge hooks are quality gates that run automatically. All Flutter-specific hooks no-op when `pubspec.yaml` is not found — they are safe to install globally.

| Hook | Trigger | Action |
|---|---|---|
| Format | After editing any `.dart` file | `dart format <file>` |
| Analyzer | After editing `.dart` (opt-in) | `flutter analyze` — enable with `FLUTTERFORGE_AUTO_ANALYZE=1` |
| Pre-commit | Before `git commit` | `dart format --set-exit-if-changed .` + `flutter analyze` + `flutter test` |
| Secret detection | Before any file write or commit | Blocks API keys, tokens, `.env` files — override with `FLUTTERFORGE_SKIP_SECRET_CHECK=1` |
| Pubspec sync | After editing `pubspec.yaml` | `flutter pub get` |

To skip pre-commit checks during WIP: `FLUTTERFORGE_SKIP_PRECOMMIT=1 git commit -m "WIP"`.

---

## MCP Integrations

FlutterForge ships `.mcp.json` with default MCP server integrations that work without credentials. Credentialed integrations are opt-in and documented in `mcp-servers/optional-mcp.json`.

| Server | Purpose | Setup |
|---|---|---|
| `context7` | Flutter/Dart/pub.dev documentation lookup | `npx @upstash/context7-mcp` (no auth needed) |
| `pub-dev` | Package search, scores, versions, Flutter SDK compatibility | Auto-installs Node dependencies into Claude plugin data on first use |

Optional integrations:

| Server | Purpose | Setup |
|---|---|---|
| `github` | PR and issue workflows | Copy from `mcp-servers/optional-mcp.json` and set `GITHUB_PERSONAL_ACCESS_TOKEN` |
| `supabase` | Supabase schema and auth integration | Copy from `mcp-servers/optional-mcp.json` and set `SUPABASE_ACCESS_TOKEN` |
| `figma` | Design-to-Flutter component mapping | Copy from `mcp-servers/optional-mcp.json` and set `FIGMA_API_KEY` |
| `firebase` | Firebase Auth, Firestore, Storage, Functions | Copy from `mcp-servers/optional-mcp.json`, install/login to `firebase-tools`, optionally set `FIREBASE_PROJECT` |

See `mcp-servers/README.md` for detailed setup instructions and `mcp-servers/ROADMAP.md` for planned future MCPs.

---

## Configuration

FlutterForge reads environment variables for behavior configuration:

| Variable | Default | Effect |
|---|---|---|
| `FLUTTERFORGE_AUTO_ANALYZE` | `0` | Set to `1` to auto-run `flutter analyze` after every Dart edit |
| `FLUTTERFORGE_SKIP_PRECOMMIT` | unset | Set to `1` to skip pre-commit quality gate (WIP escape hatch) |
| `FLUTTERFORGE_SKIP_SECRET_CHECK` | unset | Set to `1` to skip secret detection (use carefully) |

Maintainer validation before release:

```bash
claude plugin validate .
python3 -m json.tool .lsp.json > /dev/null
bash skills.sh list
node --check hooks/lib-node/*.cjs
node --check mcp-servers/pub-dev-mcp/server.js
node --check mcp-servers/pub-dev-mcp/lib/pubdev-client.js
```

---

## Portable Skills and Agents

FlutterForge can also export its `skills/` and `agents/` without installing the full Claude Code plugin. This is useful for Codex and other CLIs that can read skill or agent prompt directories.

From a local checkout:

```bash
bash skills.sh install --preset codex
bash skills.sh install --preset generic
bash skills.sh list
```

From a remote script:

```bash
curl -fsSL https://raw.githubusercontent.com/Yakoub-ai/flutterforge/main/skills.sh | bash -s -- install --preset generic
```

Presets:

| Preset | Skills directory | Agents directory |
|---|---|---|
| `claude` | `~/.claude/skills` | `~/.claude/agents` |
| `codex` | `${CODEX_HOME:-~/.codex}/skills` | `${CODEX_HOME:-~/.codex}/agents` |
| `generic` | `~/.agents/skills` | `~/.agents/agents` |

Custom directories are supported:

```bash
bash skills.sh install --skills-dir ~/.mycli/skills --agents-dir ~/.mycli/agents
```

---

## Templates

Copy templates from `templates/` into your Flutter project to bootstrap documentation:

| Template | Use |
|---|---|
| `app_brief.md` | Product brief for new app planning |
| `technical_plan.md` | Architecture and implementation plan |
| `architecture_decision_record.md` | Document architecture decisions |
| `feature_spec.md` | Feature specification before implementation |
| `ux_review.md` | UX review checklist |
| `test_plan.md` | Test strategy documentation |
| `release_checklist.md` | Android + iOS release checklist |
| `debug_report.md` | Structured debugging report |
| `claude_project_memory.md` | CLAUDE.md template for Flutter project AI context |

---

## Examples

See `examples/` for guided walkthrough recipes showing how to use FlutterForge commands to build real app types:

- [`todo_app.md`](examples/todo_app.md) — Simple CRUD with local storage
- [`firebase_auth_app.md`](examples/firebase_auth_app.md) — Authentication with Firebase
- [`ecommerce_app.md`](examples/ecommerce_app.md) — Product catalog with cart and payments
- [`maps_upload_app.md`](examples/maps_upload_app.md) — Maps, location, and photo upload

---

## Troubleshooting

**Hooks not firing?**
- Run `node --version` to confirm Node.js ≥ 18 is on your PATH.
- Run the MCP verification script to check all server connections:
  ```bash
  bash scripts/verify_mcps.sh      # macOS / Linux
  pwsh scripts/verify_mcps.ps1     # Windows
  ```

**MCP server not connecting?**
- Check the required env vars in the table above.
- See `mcp-servers/README.md` for per-server troubleshooting.

**Secret detection blocking a legitimate value?**
- Add a placeholder comment (`# example`) on the same line, or set `FLUTTERFORGE_SKIP_SECRET_CHECK=1`.

**Pre-commit hook blocking?**
- Bypass for WIP work: `FLUTTERFORGE_SKIP_PRECOMMIT=1 git commit -m "WIP"`.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to add skills, agents, commands, and hook scripts.

## License

MIT — see [LICENSE](LICENSE).
