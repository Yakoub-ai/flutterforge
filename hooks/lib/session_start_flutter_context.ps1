# session_start_flutter_context.ps1 — Auto-orient Claude when a Flutter project is open.
# Windows PowerShell equivalent of session_start_flutter_context.sh.
#
# Triggered: SessionStart
# No-ops silently when no pubspec.yaml is found within 5 parent levels.

# ── Find Flutter project root ─────────────────────────────────────────────────
function Find-FlutterRoot {
    $dir = (Get-Location).Path
    $depth = 0
    $maxDepth = 5
    while ($depth -le $maxDepth) {
        if (Test-Path (Join-Path $dir "pubspec.yaml")) {
            return $dir
        }
        $parent = Split-Path $dir -Parent
        if ($parent -eq $dir) { break }
        $dir = $parent
        $depth++
    }
    return $null
}

$root = Find-FlutterRoot
if (-not $root) { exit 0 }

# ── Gather Flutter version ────────────────────────────────────────────────────
$flutterVersion = "(flutter not on PATH)"
try {
    $raw = flutter --version --machine 2>$null | ConvertFrom-Json -ErrorAction Stop
    if ($raw.version) { $flutterVersion = $raw.version }
} catch {}

# ── Extract app name ──────────────────────────────────────────────────────────
$pubspec = Join-Path $root "pubspec.yaml"
$appName = "unknown"
$nameLine = Select-String -Path $pubspec -Pattern "^name:" | Select-Object -First 1
if ($nameLine) { $appName = ($nameLine.Line -replace "name:\s*", "").Trim() }

# ── Detect state management ───────────────────────────────────────────────────
$pubspecContent = Get-Content $pubspec -Raw
$stateMgmt = "unknown"
if ($pubspecContent -match "flutter_riverpod|riverpod_annotation") { $stateMgmt = "riverpod" }
elseif ($pubspecContent -match "flutter_bloc|bloc:") { $stateMgmt = "bloc/cubit" }
elseif ($pubspecContent -match "provider:") { $stateMgmt = "provider" }
elseif ($pubspecContent -match "get:") { $stateMgmt = "getx" }

# ── Detect router ─────────────────────────────────────────────────────────────
$router = "unknown"
if ($pubspecContent -match "go_router") { $router = "go_router" }
elseif ($pubspecContent -match "auto_route") { $router = "auto_route" }

# ── Planning docs and CI ─────────────────────────────────────────────────────
$hasTechPlan = if (Test-Path (Join-Path $root "docs\architecture\technical_plan.md")) { "yes" } else { "no" }
$hasAppBrief = if (Test-Path (Join-Path $root "docs\product\app_brief.md")) { "yes" } else { "no" }
$hasCi = if (Test-Path (Join-Path $root ".github\workflows\flutter_ci.yml")) { "yes" } else { "no" }

# ── Output context block ──────────────────────────────────────────────────────
Write-Output "[FlutterForge — Session Context]"
Write-Output "App: $appName"
Write-Output "Flutter: $flutterVersion"
Write-Output "State management: $stateMgmt"
Write-Output "Router: $router"
Write-Output "Architecture plan: $hasTechPlan  (docs/architecture/technical_plan.md)"
Write-Output "Product brief: $hasAppBrief  (docs/product/app_brief.md)"
Write-Output "CI configured: $hasCi  (.github/workflows/flutter_ci.yml)"
Write-Output "Project root: $root"
