# verify_mcps.ps1 — Smoke-test default MCP servers and any configured optional servers (Windows)
# Usage: pwsh scripts/verify_mcps.ps1 [-PluginRoot <path>]
param([string]$PluginRoot = (Split-Path $PSScriptRoot -Parent))

$mcpJson = Join-Path $PluginRoot '.mcp.json'

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
  Write-Error "node not found on PATH. Install Node.js >= 18 to use FlutterForge hooks."
  exit 1
}
if (-not (Test-Path $mcpJson)) {
  Write-Error "$mcpJson not found."
  exit 1
}

Write-Host "FlutterForge MCP Verification"
Write-Host "=============================="
Write-Host ""

$pass = 0; $fail = 0

function Test-McpServer {
  param([string]$Name, [string]$Command)
  $initMsg = '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"flutterforge-verify","version":"0.1"}}}'
  try {
    $result = $initMsg | & cmd /c "$Command" 2>$null
    if ($result -match '"result"') {
      Write-Host "  OK  $Name" -ForegroundColor Green
      $script:pass++
    } else {
      Write-Host "  FAIL $Name  (could not initialize -- check credentials/install)" -ForegroundColor Red
      $script:fail++
    }
  } catch {
    Write-Host "  FAIL $Name  (error: $_)" -ForegroundColor Red
    $script:fail++
  }
}

# context7
Test-McpServer "context7" "npx -y @upstash/context7-mcp"

# pub-dev
$pubDevServer = Join-Path $PluginRoot 'mcp-servers\pub-dev-mcp\server.js'
if (Test-Path $pubDevServer) {
  $env:CLAUDE_PLUGIN_DATA = Join-Path $PluginRoot '.tmp-claude-plugin-data'
  Test-McpServer "pub-dev" "node `"$pubDevServer`""
} else {
  Write-Host "  -    pub-dev  (server file missing)" -ForegroundColor Yellow
}

# github
if ($env:GITHUB_PERSONAL_ACCESS_TOKEN) {
  Test-McpServer "github" "npx -y @github/github-mcp-server stdio"
} else {
  Write-Host "  -    github  (GITHUB_PERSONAL_ACCESS_TOKEN not set)" -ForegroundColor Yellow
}

# supabase
if ($env:SUPABASE_ACCESS_TOKEN) {
  Test-McpServer "supabase" "npx -y @supabase/mcp-server-supabase --access-token $env:SUPABASE_ACCESS_TOKEN"
} else {
  Write-Host "  -    supabase  (SUPABASE_ACCESS_TOKEN not set)" -ForegroundColor Yellow
}

# figma
if ($env:FIGMA_API_KEY) {
  Test-McpServer "figma" "npx -y figma-mcp"
} else {
  Write-Host "  -    figma  (FIGMA_API_KEY not set)" -ForegroundColor Yellow
}

# firebase
if (Get-Command firebase -ErrorAction SilentlyContinue) {
  Test-McpServer "firebase" "firebase experimental:mcp"
} else {
  Write-Host "  -    firebase  (firebase-tools not installed)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Results: $pass passed, $fail failed"
if ($fail -gt 0) { exit 1 } else { exit 0 }
