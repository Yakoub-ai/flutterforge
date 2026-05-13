#!/usr/bin/env bash
# LEGACY REFERENCE — Claude Code hooks now use hooks/lib-node/post_edit_analyze.cjs
# post_edit_analyze.sh — Run flutter analyze after a Dart file edit.
#
# Triggered: PostToolUse on Write|Edit
# Env vars:
#   FLUTTERFORGE_AUTO_ANALYZE  — must be "1" to enable (default: disabled)
#   CLAUDE_FILE_PATHS          — space-separated list of files affected by the tool call
#
# Behavior:
#   - No-ops silently if FLUTTERFORGE_AUTO_ANALYZE != 1
#   - No-ops silently if not in a Flutter project
#   - No-ops silently if no .dart files were edited
#   - Exits 1 on analyze failure (blocks further processing)
#   - Exits 0 on success

set -uo pipefail

# ── Guard: only run if explicitly enabled ─────────────────────────────────────
if [ "${FLUTTERFORGE_AUTO_ANALYZE:-}" != "1" ]; then
  exit 0
fi

# ── Guard: only for .dart file edits ─────────────────────────────────────────
has_dart_files=false
if [ -n "${CLAUDE_FILE_PATHS:-}" ]; then
  IFS=' ' read -ra all_files <<< "$CLAUDE_FILE_PATHS"
  for f in "${all_files[@]}"; do
    if [[ "$f" == *.dart ]]; then
      has_dart_files=true
      break
    fi
  done
fi

if [ "$has_dart_files" = false ]; then
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

# ── Run flutter analyze ───────────────────────────────────────────────────────
echo "FlutterForge [post_edit_analyze]: Running flutter analyze..."

analyze_output="$(flutter analyze --no-fatal-infos 2>&1)" || {
  exit_code=$?
  echo "FlutterForge [post_edit_analyze]: Analysis found issues:" >&2
  echo "$analyze_output" | grep -E "^(error|warning|hint|  •)" | head -20 >&2
  issue_count="$(echo "$analyze_output" | grep -c "error\|warning" || true)"
  echo "FlutterForge [post_edit_analyze]: $issue_count issue(s) detected. Fix before continuing." >&2
  exit "$exit_code"
}

echo "FlutterForge [post_edit_analyze]: No issues found."
exit 0
