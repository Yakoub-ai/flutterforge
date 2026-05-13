#!/usr/bin/env bash
# verify_mcps.sh — Smoke-test default MCP servers and any configured optional servers.
# Usage: bash scripts/verify_mcps.sh [<plugin-root>]
#   <plugin-root>  Optional path to the plugin root directory. Defaults to the parent of this script.
# Prints OK or FAIL for each server so you can diagnose setup issues before
# running into them mid-task.
set -uo pipefail

PLUGIN_ROOT="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
MCP_JSON="$PLUGIN_ROOT/.mcp.json"

if ! command -v node >/dev/null 2>&1; then
  echo "ERROR: node not found on PATH. Install Node.js ≥ 18 to use FlutterForge hooks."
  exit 1
fi

if [ ! -f "$MCP_JSON" ]; then
  echo "ERROR: $MCP_JSON not found."
  exit 1
fi

echo "FlutterForge MCP Verification"
echo "=============================="
echo ""

PASS=0
FAIL=0

check_server() {
  local name="$1"
  local cmd="$2"
  # Try to start the server, send a bare initialize message, and read response within 5 s
  local result
  result=$(echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"flutterforge-verify","version":"0.1"}}}' \
    | timeout 5 sh -c "$cmd" 2>/dev/null || true)
  if echo "$result" | grep -q '"result"'; then
    echo "  ✓ $name"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $name  (could not initialize — check credentials/install)"
    FAIL=$((FAIL + 1))
  fi
}

# context7 (no auth)
check_server "context7" "npx -y @upstash/context7-mcp 2>/dev/null"

# pub-dev (no auth)
if [ -f "$PLUGIN_ROOT/mcp-servers/pub-dev-mcp/server.js" ]; then
  check_server "pub-dev" "CLAUDE_PLUGIN_DATA=\"$PLUGIN_ROOT/.tmp-claude-plugin-data\" node $PLUGIN_ROOT/mcp-servers/pub-dev-mcp/server.js"
else
  echo "  - pub-dev  (server file missing)"
fi

# github
if [ -n "${GITHUB_PERSONAL_ACCESS_TOKEN:-}" ]; then
  check_server "github" "npx -y @github/github-mcp-server stdio 2>/dev/null"
else
  echo "  - github  (GITHUB_PERSONAL_ACCESS_TOKEN not set)"
fi

# supabase
if [ -n "${SUPABASE_ACCESS_TOKEN:-}" ]; then
  check_server "supabase" "npx -y @supabase/mcp-server-supabase --access-token $SUPABASE_ACCESS_TOKEN 2>/dev/null"
else
  echo "  - supabase  (SUPABASE_ACCESS_TOKEN not set)"
fi

# figma
if [ -n "${FIGMA_API_KEY:-}" ]; then
  check_server "figma" "npx -y figma-mcp 2>/dev/null"
else
  echo "  - figma  (FIGMA_API_KEY not set)"
fi

# firebase
if command -v firebase >/dev/null 2>&1; then
  check_server "firebase" "firebase experimental:mcp 2>/dev/null"
else
  echo "  - firebase  (firebase-tools not installed — run: npm i -g firebase-tools && firebase login)"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -gt 0 ] && exit 1 || exit 0
