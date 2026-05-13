#!/usr/bin/env bash
# LEGACY REFERENCE — Claude Code hooks now use hooks/lib-node/pubspec_sync.cjs
# pubspec_sync.sh — Run flutter pub get after pubspec.yaml is edited.
#
# Triggered: PostToolUse on Write|Edit
# Env vars:
#   CLAUDE_FILE_PATHS  — space-separated list of files affected by the tool call
#
# Behavior:
#   - No-ops silently if not in a Flutter project
#   - No-ops silently if pubspec.yaml was not among the edited files
#   - Exits 0 even on pub get failure (non-blocking — pubspec may be mid-edit)
#   - Prints success or informational failure message

set -uo pipefail

# ── Guard: only act on pubspec.yaml edits ─────────────────────────────────────
pubspec_edited=false
if [ -n "${CLAUDE_FILE_PATHS:-}" ]; then
  IFS=' ' read -ra all_files <<< "$CLAUDE_FILE_PATHS"
  for f in "${all_files[@]}"; do
    if [[ "$f" == *pubspec.yaml ]]; then
      pubspec_edited=true
      break
    fi
  done
fi

if [ "$pubspec_edited" = false ]; then
  exit 0
fi

# ── Load flutter_guard ────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./flutter_guard.sh
source "$SCRIPT_DIR/flutter_guard.sh"
GUARD_EXIT=$?

if [ "$GUARD_EXIT" -eq 99 ]; then
  exit 0
fi

# ── Run flutter pub get ───────────────────────────────────────────────────────
echo "FlutterForge [pubspec_sync]: Running flutter pub get..."

if flutter pub get --directory "$FLUTTER_PROJECT_ROOT" 2>&1; then
  echo "FlutterForge [pubspec_sync]: Dependencies updated."
else
  echo "FlutterForge [pubspec_sync]: Warning — flutter pub get failed." >&2
  echo "  This may be expected if pubspec.yaml is not yet complete." >&2
  echo "  Run 'flutter pub get' manually when the file is ready." >&2
fi

# Always exit 0 — pub get failure must not block editor operations
exit 0
