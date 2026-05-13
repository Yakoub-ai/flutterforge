# flutter_guard.ps1 — Walk up from $PWD to find a Flutter project root.
#
# Usage: dot-source this script or run it directly.
#   - If pubspec.yaml is found: sets $env:FLUTTER_PROJECT_ROOT, exits 0
#   - If not found after 5 levels: exits 99 (callers treat this as a no-op)

$dir = (Get-Location).Path
$maxDepth = 5
$depth = 0
$found = $false

while ($depth -le $maxDepth) {
    $candidate = Join-Path $dir "pubspec.yaml"
    if (Test-Path $candidate -PathType Leaf) {
        $env:FLUTTER_PROJECT_ROOT = $dir
        $found = $true
        break
    }

    $parent = Split-Path $dir -Parent
    # Stop at filesystem root (Split-Path returns empty string or same path)
    if ([string]::IsNullOrEmpty($parent) -or $parent -eq $dir) {
        break
    }

    $dir = $parent
    $depth++
}

if ($found) {
    exit 0
} else {
    exit 99
}
