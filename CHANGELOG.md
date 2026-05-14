# Changelog

All notable changes to FlutterForge are documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added

- `.claude-plugin/marketplace.json` — marketplace catalog manifest enabling installation via `/plugin marketplace add Yakoub-ai/flutterforge` + `/plugin install flutterforge@flutterforge`.
- CI validation in `plugin_lint.yml`: new steps assert `marketplace.json` exists, parses as JSON, and matches `plugin.json` on `name`, `version`, and `source` path — prevents silent regression.
- skills.sh compatibility docs and CI validation via `npx skills add . --list`, so FlutterForge skills are discoverable by the open `skills` CLI for Claude Code, Codex, Cursor, and other supported agents.

### Changed

- README `## Install` section restructured: marketplace install is now **Option A** (recommended); local clone via `--plugin-dir` is **Option B** (contributors / offline).
- Removed the repo-local `skills.sh` installer in favor of the official `npx skills add Yakoub-ai/flutterforge` workflow.

### Fixed

- Claude Code plugin validation now passes after quoting command argument hints that contain YAML-sensitive characters.
- Blocking hooks now return Claude Code's JSON `decision: "block"` response correctly and cover `MultiEdit` writes.
- Default MCP configuration is public-install safe: only no-auth `context7` and `pub-dev` are enabled by default; credentialed integrations live in `mcp-servers/optional-mcp.json`.
- `pub-dev` MCP now bootstraps dependencies into Claude plugin data or a user cache and has been verified end to end against live pub.dev metadata.
- Documentation and examples now use namespaced `/flutterforge:*` command invocations consistently.
- `flutter-accessibility` command was registered in `plugin.json` but missing from the README Commands table and from the `flutterforge.md` hub menu — added as mode 10 with routing trigger `10 | accessibility | a11y | flutter-accessibility`.
- `skills/flutter-documentation/SKILL.md` referenced "Phase 7" of `/flutterforge:build-flutter-feature`, which only has 5 phases — corrected to "Phase 5".
- `commands/improve-ux.md`, `commands/prepare-release.md`, and `commands/refactor-flutter.md` were missing the "You are running …" orientation header present in all other commands — added for consistency.
- `scripts/verify_mcps.sh` comment described `--from-dir <path>` as a named flag but the script treats `$1` as a positional argument — comment corrected to `[<plugin-root>]`.
- `scripts/README.md` did not document `verify_mcps.sh` / `verify_mcps.ps1` despite those scripts being referenced in the main README troubleshooting section — added entry with usage and behaviour notes.

---

## [0.3.0] — 2026-05-13

### Fixed

#### Hooks — Cross-platform Node.js rewrite (critical)
- Rewrote all 5 hook scripts in Node.js (`hooks/lib-node/*.cjs`), replacing bash scripts that were non-functional on Windows. Hooks now run on Windows, macOS, and Linux via the Node.js runtime that ships with Claude Code.
- `_common.cjs` — shared helpers: `readStdin()` (parses JSON from stdin), `findFlutterProjectRoot()`, `block()`, `allow()`, `runCmd()` with `shell: true` for cross-platform `flutter`/`dart` invocation.
- `session_start_flutter_context.cjs` — SessionStart hook emitting project context (app name, state management, router, Flutter version, doc presence). No-ops outside Flutter projects.
- `post_edit_format.cjs` — Runs `dart format --fix` after every `.dart` file edit; always exits 0 (non-blocking).
- `post_edit_analyze.cjs` — Opt-in analyzer (set `FLUTTERFORGE_AUTO_ANALYZE=1`); writes findings to stdout.
- `pubspec_sync.cjs` — Runs `flutter pub get` when `pubspec.yaml` is saved.
- `secret_detect.cjs` — Pre-tool-use secret detection with 8 regex patterns + Firebase service-account JSON detection + bare `.env` file blocking. Allowlist for placeholder values. Escape hatch via `FLUTTERFORGE_SKIP_SECRET_CHECK=1`.
- `pre_commit_quality.cjs` — Pre-commit gate (format → analyze → test). Gates internally on `tool_input.command` matching `git commit`, fixing the broken `Bash.*git commit` regex matcher.
- Fixed `hooks/hooks.json`: all commands now invoke `node`, not `bash`; Bash pre-commit matcher changed from broken regex to `"Bash"` (script gates internally); secret detect added to Bash matcher.
- Added legacy headers to all 7 existing `hooks/lib/*.sh` and `*.ps1` files noting they are no longer wired.

#### README — Install path and onboarding
- Fixed install path: removed incorrect `~/.claude/plugins/local/` path; replaced with `/plugin install --from-dir <path>` (the supported local-dev mechanism).
- Added marketplace path: `/plugin marketplace add Yakoub-ai/flutterforge`.
- Removed invalid `/reload-plugins` hint.
- Added Prerequisites section (Flutter SDK ≥ 3.x, Node.js ≥ 18, Claude Code).
- Removed undocumented `FLUTTERFORGE_DEFAULT_ARCH` and `FLUTTERFORGE_DEFAULT_STATE` env vars.
- Added Troubleshooting section.

### Added

#### Command — `/flutterforge:flutter-accessibility`
- `commands/flutter-accessibility.md` — new command for accessibility auditing and fixes. Phases: scope resolution, accessibility audit (using the `flutter-accessibility` skill), implementation pass (via `ux-mobile-designer` agent), and findings report at `docs/quality/accessibility_review.md`.
- Registered in `plugin.json` commands list.
- Fixes dangling reference in `commands/flutterforge:improve-ux.md` that linked to this command.

#### MCP Server — `pub-dev-mcp`
- `mcp-servers/pub-dev-mcp/` — local Node.js MCP server for pub.dev queries. No authentication required.
- Tools: `searchPackages`, `getPackage`, `getPackageScore`, `getPackageVersions`, `checkCompatibility` (checks Flutter SDK constraint).
- Wired in `.mcp.json` as `pub-dev`.
- Referenced from `flutter-architect`, `api-integration-engineer`, and `codebase-auditor` agents.

#### Shared reference docs
- `references/dart-error-mapping.md` — canonical `AppException` hierarchy and `mapDioException()` for data/domain layers.
- `references/state-management-snippets.md` — Riverpod (AsyncNotifier, NotifierProvider, StreamProvider, family, testing) and Bloc/Cubit canonical code examples.
- `references/feature-layer-template.md` — feature-first folder structure, file naming conventions, and per-layer Dart snippets.

#### Documentation wiring
- `build-flutter-feature.md` Phase 5: uses `flutter-documentation` skill to update README, create feature doc, and append ADR after successful feature build.
- `prepare-release.md` Phase 3: uses `flutter-documentation` skill to update `CHANGELOG.md` with release entry.

### Changed

#### Skills — Moderate slim (context reduction ~40%)
- All 13 active skills trimmed to ~180–300 lines (from 296–697 lines). Inline Dart code moved to `references/` shared docs.
- Added `version: 1.0.0` to all skills that were missing it.
- Cross-references added from each skill to relevant `@references/` files and agents.
- `flutter-documentation` skill wired into `/flutterforge:build-flutter-feature` Phase 7 and `/flutterforge:prepare-release` Phase 1.

#### Agents — Compressed description blocks
- All 12 agent `description:` blocks compressed from ~30–40 lines (with examples/commentary) to 2-line summaries.
- `flutter-architect` agent: removed hardcoded package version pins; replaced with instruction to query pub-dev MCP before pinning.
- `api-integration-engineer`: added pub-dev MCP query instruction before adding packages.
- `codebase-auditor`: added pub-dev MCP query instruction for dependency version checks.

#### plugin.json
- Added explicit `"hooks": "./hooks/hooks.json"` field.
- Added `flutter-accessibility` command entry.
- Version bumped to `0.3.0`.

#### CI — `.github/workflows/plugin_lint.yml`
- Added Node.js syntax check (`node --check`) for all `hooks/lib-node/*.cjs` scripts.
- Added hook smoke tests: secret_detect blocks Google API key pattern, allows placeholder values; post_edit_format exits 0 for non-Dart files.
- Added `shellcheck` pass on `scripts/*.sh`.
- Added pub-dev-mcp JSON and syntax validation.
- Added flutter-accessibility command registration check.

---

## [0.2.0] — 2026-05-13

### Added

#### MCP Server — Firebase (official)
- Wired `firebase-tools experimental:mcp` as the `firebase` MCP server in `.mcp.json`.
  Provides live inspection of Firestore collections, Authentication providers, Storage
  buckets, Cloud Functions, and App Hosting — used by the `api-integration-engineer`
  agent and `flutter-api-integration` skill before writing backend integration code.
- Documented the community fallback (`@gannonh/firebase-mcp`) for headless / CI
  environments that cannot run `firebase login` interactively.
- Updated `mcp-servers/README.md` with Firebase setup steps, authentication options,
  troubleshooting, and a comparison table of official vs community approaches.

#### CI/CD Workflow Templates
- `templates/github_workflows/flutter_ci.yml` — Format check + analyze + test + coverage on
  every push/PR to `main` / `develop`.
- `templates/github_workflows/android_build.yml` — Release App Bundle + split APKs with
  documented signing setup via repository secrets.
- `templates/github_workflows/ios_build.yml` — iOS archive on `macos-latest` with
  no-codesign default and documented signing steps for production use.
  Fulfils PRD §20 (CI/CD requirements).

#### SessionStart Hook
- `hooks/lib/session_start_flutter_context.sh` (+ `.ps1` Windows mirror) — On each
  session start, auto-detects the Flutter project root, reads `pubspec.yaml`, and
  outputs a concise context block (app name, Flutter version, state management library,
  router, presence of planning docs and CI). No-ops outside Flutter projects.
- Wired in `hooks/hooks.json` as a `SessionStart` hook — eliminates per-session
  re-discovery overhead.

### Changed

#### Router Upgrade — `/flutterforge`
- `/flutterforge` can now **dispatch sub-commands directly** when given an unambiguous
  mode keyword or number (`/flutterforge plan a fitness app` → invokes
  `/flutterforge:plan-flutter-app` immediately). Natural-language inputs still route
  via a one-confirmation step to avoid accidental dispatch.

#### Agent: `api-integration-engineer`
- Added **MCP Tool Routing** section: instructs the agent to use the `firebase` MCP
  for live schema/auth/storage inspection, `supabase` MCP for table validation, and
  `context7` for current package API docs before writing any integration code.

#### Skill: `flutter-api-integration`
- Added **MCP Tool Usage** section with specific tool calls (`firestore/listCollections`,
  `auth/listProviders`, `storage/listBuckets`, `functions/list`) to consult before
  generating DTOs or repository code.

#### Docs
- `README.md` MCP table updated from 4 → 5 servers.
- `mcp-servers/ROADMAP.md` status table updated: Firebase marked as **Shipped**.
- `plugin.json` version bumped from `0.1.0` to `0.2.0`.

---

## [0.1.0] — 2026-05-12

### Added

#### Commands (10)
- `/flutterforge` — Main entry point with 9-mode workflow router
- `/flutterforge:plan-flutter-app` — Greenfield product brainstorm to architecture plan
- `/flutterforge:new-flutter-app` — Scaffold a production-ready Flutter project
- `/flutterforge:build-flutter-feature` — Feature development workflow with tests
- `/flutterforge:audit-flutter-app` — Comprehensive brownfield app audit
- `/flutterforge:debug-flutter` — Root-cause debugging workflow
- `/flutterforge:generate-tests` — Test generation for features and widgets
- `/flutterforge:improve-ux` — UX analysis and improvement workflow
- `/flutterforge:prepare-release` — Android + iOS release readiness checklist
- `/flutterforge:refactor-flutter` — LSP-guided safe refactoring workflow

#### Agents (12)
- `product-strategist` — App idea to product brief
- `flutter-architect` — Architecture, folder structure, state management decisions
- `ux-mobile-designer` — Screen flows, design system, accessibility
- `flutter-implementation-engineer` — Clean, tested Flutter code
- `state-management-specialist` — Riverpod, Bloc, Cubit patterns
- `api-integration-engineer` — REST, Firebase, Supabase data layer
- `flutter-test-engineer` — Unit, widget, integration test strategies
- `flutter-debugger` — Stack trace analysis and fix verification
- `mobile-performance-engineer` — Rebuild analysis, list optimization, profiling
- `mobile-security-reviewer` — Secrets, permissions, auth flows
- `release-engineer` — Android/iOS build readiness, store checklist
- `codebase-auditor` — Architecture drift, anti-patterns, tech debt

#### Skills (14)
- `flutter-app-discovery` — Understand an existing Flutter codebase
- `flutter-product-brief` — Product discovery and MVP definition
- `flutter-architecture` — Architecture decisions and folder structure
- `flutter-ux-design` — Mobile UX design workflow
- `flutter-feature-dev` — Feature planning and implementation
- `flutter-state-management` — State management selection and patterns
- `flutter-api-integration` — API, Firebase, Supabase integration
- `flutter-testing` — Testing strategy and generation
- `flutter-debugging` — Debugging classification and fix workflow
- `flutter-performance` — Performance audit and optimization
- `flutter-accessibility` — Accessibility audit and semantic improvements
- `flutter-security` — Security audit and hardening
- `flutter-release-readiness` — Release preparation for Android and iOS
- `flutter-documentation` — Documentation generation and maintenance

#### Hooks (5 rules)
- Post-edit Dart format (`dart format .`)
- Post-edit analyzer (opt-in via `FLUTTERFORGE_AUTO_ANALYZE=1`)
- Pre-commit quality gate (format + analyze + test)
- Secret detection (blocks API keys, tokens, `.env` in commits)
- Post-pubspec `flutter pub get`

#### MCP integrations (4 optional servers)
- `context7` — Flutter/Dart/pub.dev documentation lookup
- `github` — PR and issue workflows
- `supabase` — Supabase schema and auth integration
- `figma` — Design-to-Flutter component mapping

#### Templates (9)
- App brief, technical plan, ADR, feature spec, UX review, test plan, release checklist, debug report, CLAUDE.md project memory

#### Scripts (7)
- Flutter doctor check, analyze, test, format, Android build, iOS build, log collection

#### Examples (4 recipes)
- Todo app, Firebase auth app, ecommerce app, maps/upload app
