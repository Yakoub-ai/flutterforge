# pub-dev-mcp

MCP server for querying [pub.dev](https://pub.dev) — the Dart and Flutter package registry.
Provides structured package search, metadata lookup, health scores, version history, and
Flutter compatibility checks directly from Claude.

No authentication required. Uses the public pub.dev REST API.

---

## Tools

| Tool | Description |
|---|---|
| `searchPackages` | Search pub.dev by keyword. Returns name, version, description, likes, pub points, popularity. |
| `getPackage` | Full metadata for a package: version, SDK constraints, publisher, scores. |
| `getPackageScore` | Health scores: like count, popularity (0–1), granted/max pub points. |
| `getPackageVersions` | All published versions with publication dates, newest first. |
| `checkCompatibility` | Checks if a package's `environment.flutter` constraint satisfies a given Flutter version. |

---

## Usage

### Via `.mcp.json` (recommended)

Already wired in the plugin root `.mcp.json` as `pub-dev`. Claude uses it automatically when you ask about package versions, health scores, or compatibility.

### Manual start

```bash
CLAUDE_PLUGIN_DATA=/tmp/flutterforge-plugin-data node mcp-servers/pub-dev-mcp/server.js
```

The server auto-installs runtime dependencies into `${CLAUDE_PLUGIN_DATA}/pub-dev-mcp`
on first use. If `CLAUDE_PLUGIN_DATA` is not set during local testing, it uses a user
cache directory such as `%LOCALAPPDATA%/flutterforge/pub-dev-mcp` or
`~/.cache/flutterforge/pub-dev-mcp`.

### Example queries that trigger this server

- "What's the latest version of riverpod?"
- "Is flutter_secure_storage compatible with Flutter 3.24?"
- "Search for image caching packages on pub.dev"
- "What's the pub points score for go_router?"
- "List all versions of freezed"

---

## Local development

```bash
npm install
node --check server.js
node --check lib/pubdev-client.js
```

Dependencies:
- `@modelcontextprotocol/sdk` — MCP stdio transport and request schema
- `undici` — HTTP client with `AbortSignal.timeout` support (ships with Node 18+)

---

## No environment variables required

The pub.dev REST API is public and unauthenticated. No tokens or credentials needed.

---

## Rate limits

pub.dev does not publish an official rate limit. This server implements automatic retry
with a short backoff (up to 2 retries) and a 10-second request timeout.
