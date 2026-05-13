# FlutterForge MCP Servers

FlutterForge wires up default no-auth MCP servers in `.mcp.json`. Credentialed
servers are opt-in and documented in `optional-mcp.json` so public installs do not
fail because a user lacks GitHub, Supabase, Figma, or Firebase credentials.

---

## Default Servers

### `context7` — Flutter/Dart/pub.dev Documentation

**Package:** `@upstash/context7-mcp`
**Env vars required:** none

Context7 indexes library documentation from GitHub and pub.dev in real time. For
FlutterForge it covers:

- **Flutter SDK docs** — widget properties, lifecycle methods, rendering pipeline APIs.
  When you ask Claude about `Navigator.pushNamed`, `StreamBuilder`, or `CustomPainter`,
  context7 fetches up-to-date reference docs rather than relying on training-data snapshots.
- **Dart SDK docs** — core language APIs (`dart:async`, `dart:io`, `dart:convert`, etc.).
- **pub.dev packages** — README, changelog, and API docs for any public package.
  Useful when evaluating `riverpod`, `go_router`, `freezed`, or any dependency.
- **Framework-specific guides** — Riverpod, Bloc, GetX, and other ecosystem libraries.

Context7 is the primary substitute for the planned `flutter-docs-mcp` custom server
(see [ROADMAP.md](./ROADMAP.md) for what that would add).

---

### `pub-dev` — Package Search and Compatibility

**Location:** `mcp-servers/pub-dev-mcp/server.js` (local Node.js server)
**Env vars required:** none
**Prerequisites:** none; dependencies auto-install into `${CLAUDE_PLUGIN_DATA}` on first use.

A purpose-built MCP server for querying pub.dev structured data. Used by the
`flutter-architect`, `api-integration-engineer`, and `codebase-auditor` agents
when recommending or evaluating packages:

- Search pub.dev by keyword (`searchPackages`)
- Fetch full package metadata including SDK constraints (`getPackage`)
- Get health scores: likes, pub points, popularity (`getPackageScore`)
- List all published versions (`getPackageVersions`)
- Check if a package's Flutter constraint satisfies your Flutter version (`checkCompatibility`)

---

## Optional Credentialed Servers

The following entries are available in `optional-mcp.json`. Copy only the servers you
need into your own MCP configuration and set the corresponding credentials.

### `github` — PR and Issue Workflows

**Package:** `@github/github-mcp-server`
**Env vars required:** `GITHUB_PERSONAL_ACCESS_TOKEN`

Used by FlutterForge agents during code review, release preparation, and multi-developer
coordination:

- Fetch open pull requests and review comments during `/flutterforge:audit-flutter-app`.
- Query issues and milestones to cross-reference feature status.
- Post review summaries or release notes as PR comments.
- Read CI workflow results to surface failing checks.

Token scopes needed: `repo`, `read:org` (add `workflow` if you want agents to trigger
GitHub Actions runs).

---

### `supabase` — Backend Schema and Auth

**Package:** `@supabase/mcp-server-supabase`
**Env vars required:** `SUPABASE_ACCESS_TOKEN`

Used when the Flutter app integrates Supabase as a backend:

- Inspect table schemas so the API integration engineer can generate correct Dart models.
- Validate Row Level Security policies match the app's auth flows.
- Fetch edge function signatures for use in Dart HTTP clients.
- Check auth provider configuration (OAuth, magic link, phone OTP).

The access token is a Supabase Personal Access Token, scoped to the target project.

---

### `figma` — Design Inspection

**Package:** `figma-mcp`
**Env vars required:** `FIGMA_API_KEY`

Used by the UX Mobile Designer agent and the `/flutterforge:improve-ux` command:

- Extract layout measurements, color tokens, and typography from Figma frames.
- Map Figma components to Flutter widget implementations via Code Connect.
- Validate that implemented screens match design specifications.
- Retrieve asset exports (icons, images) for inclusion in the Flutter project.

The API key is a Figma Personal Access Token from Figma account settings.

---

### `firebase` — Firebase Backend (Auth, Firestore, Storage, Functions)

**Package:** `firebase-tools` (official Firebase CLI)
**Env vars required:** `FIREBASE_PROJECT` (optional if `.firebaserc` is present)
**Prerequisite:** `npm install -g firebase-tools && firebase login`

The official Firebase MCP server ships with `firebase-tools` as an experimental
subcommand. It is the most authoritative Firebase integration available — maintained
by the Firebase team and kept in sync with the Firebase Admin SDK.

Used by the API Integration Engineer agent and the `/flutterforge:build-flutter-feature` command
when the app has a Firebase backend:

- Inspect Firestore collection schemas and security rules to generate correct Dart models.
- Check Authentication providers enabled for the project (email/password, Google, Apple, etc.).
- Enumerate Firebase Storage bucket structure and download URL patterns.
- List deployed Cloud Functions signatures to wire into Dart HTTP clients.
- Inspect App Hosting and Hosting configuration for deployment readiness.
- Verify Remote Config parameter types before generating Dart bindings.

**Authentication:** Uses the Firebase CLI's existing login session (`firebase login`).
No service account key required for development. The `FIREBASE_PROJECT` environment
variable sets the active project; omit it to use the project in `.firebaserc`.

#### Alternative: Community Server (`@gannonh/firebase-mcp`)

If your environment cannot run `firebase login` interactively (CI pipelines, headless
servers), use the community-maintained service-account–based server instead:

```jsonc
// Optional alternative for the "firebase" entry from optional-mcp.json:
"firebase": {
  "command": "npx",
  "args": ["-y", "@gannonh/firebase-mcp"],
  "env": {
    "SERVICE_ACCOUNT_KEY_PATH": "${FIREBASE_SERVICE_ACCOUNT_PATH}",
    "FIREBASE_STORAGE_BUCKET": "${FIREBASE_STORAGE_BUCKET}"
  }
}
```

Generate a service account key in the Firebase console under
**Project Settings → Service accounts → Generate new private key**. Store the
downloaded `.json` file outside the project repo and set `FIREBASE_SERVICE_ACCOUNT_PATH`
to its absolute path. Add the path to `.gitignore` if you store it nearby.

| Approach | Auth method | Interactive login | Best for |
|---|---|---|---|
| `firebase-tools` (default) | Firebase CLI session | Required once | Development machines |
| `@gannonh/firebase-mcp` | Service account JSON | Not required | CI/CD, headless envs |

---

## Optional Setup

### 1. Set Environment Variables

Set these in your shell profile (`~/.zshrc`, `~/.bashrc`, or Windows environment):

```bash
# Required for GitHub workflows
export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_..."

# Required for Supabase integration (skip if not using Supabase)
export SUPABASE_ACCESS_TOKEN="sbp_..."

# Required for Figma design inspection (skip if not using Figma)
export FIGMA_API_KEY="figd_..."

# Optional for Firebase: overrides .firebaserc project selection
export FIREBASE_PROJECT="my-firebase-project-id"
```

On Windows (PowerShell):

```powershell
$env:GITHUB_PERSONAL_ACCESS_TOKEN = "ghp_..."
$env:SUPABASE_ACCESS_TOKEN        = "sbp_..."
$env:FIGMA_API_KEY                = "figd_..."
$env:FIREBASE_PROJECT             = "my-firebase-project-id"
```

### 2. Authenticate with Firebase (first time only)

```bash
npm install -g firebase-tools
firebase login
```

This stores a credential in `~/.config/firebase/` that the MCP server reuses for every
request. You only need to do this once per machine.

### 3. Copy optional server entries

Copy the entries you need from `mcp-servers/optional-mcp.json` into your user or
project MCP configuration. Keep secrets in environment variables, not in the repo.

### 4. No manual server start required

Claude Code spawns configured servers when a query triggers them and shuts them down
when idle.

---

## Quick Start

After setting env vars, servers activate automatically when Claude detects relevant
queries:

| You ask about...                          | Server used   |
|-------------------------------------------|---------------|
| A Flutter widget or Dart API              | `context7`    |
| A pub.dev package version or README       | `context7`    |
| A GitHub PR, issue, or CI result          | `github` if configured |
| A Supabase table, RLS policy, or auth     | `supabase` if configured |
| A Figma frame, component, or token        | `figma` if configured |
| A Firestore schema, Firebase Auth, or FCM | `firebase` if configured |

You do not need to invoke servers by name — Claude routes automatically based on context.

---

## Coverage Gaps

Two custom MCP servers described in the original FlutterForge PRD are not yet
publicly available. Context7 covers a significant portion of their use cases, but there
are gaps. See [ROADMAP.md](./ROADMAP.md) for the full planned server specifications and
current workarounds.

---

## Troubleshooting

**Context7 fails to start** — run `npx -y @upstash/context7-mcp@latest` manually in
a terminal to confirm `npx` can download it. Check Node.js is 18+.

**pub-dev fails to start** — confirm Node.js is 18+ and that npm can install packages.
The server installs its dependencies into `${CLAUDE_PLUGIN_DATA}/pub-dev-mcp` on first use.

**GitHub 401** — regenerate the PAT; ensure the `repo` scope is checked.

**Supabase permission denied** — confirm the access token belongs to a user with
`Owner` or `Administrator` role on the target project.

**Figma returns empty** — verify the PAT has "File content" read access and that the
file is not in a restricted team you are not a member of.

**Firebase MCP: `firebase: command not found`** — run `npm install -g firebase-tools`
to install the CLI, then `firebase login` to authenticate.

**Firebase MCP: `Error: No currently active project`** — either set `FIREBASE_PROJECT`
in your environment, or run `firebase use <project-id>` inside your Flutter project to
create a `.firebaserc` file.

**Firebase MCP: permission denied on Firestore** — the logged-in account must have
`Firebase Admin` or `Editor` role on the project in Google Cloud IAM.
