#!/usr/bin/env bash
# LEGACY REFERENCE — Claude Code hooks now use hooks/lib-node/post_edit_format.cjs
# post_edit_format.sh — Run dart format on an edited Dart file.
#
# Triggered: PostToolUse on Write|Edit
# Env vars:
#   CLAUDE_FILE_PATHS  — space-separated list of files affected by the tool call
#
# Behavior:
#   - No-ops silently if not in a Flutter project
#   - Formats only .dart files; ignores all others
#   - Exits 0 even on formatter failure (non-blocking)

set -uo pipefail

# ── Load flutter_guard ────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./flutter_guard.sh
source "$SCRIPT_DIR/flutter_guard.sh"
GUARD_EXIT=$?

if [ "$GUARD_EXIT" -eq 99 ]; then
  # Not a Flutter project — silently no-op
  exit 0
fi

# ── Determine target files ────────────────────────────────────────────────────
dart_files=()

if [ -n "${CLAUDE_FILE_PATHS:-}" ]; then
  # Parse space-separated paths; filter to .dart only
  IFS=' ' read -ra all_files <<< "$CLAUDE_FILE_PATHS"
  for f in "${all_files[@]}"; do
    if [[ "$f" == *.dart ]]; then
      dart_files+=("$f")
    fi
  done
fi

if [ "${#dart_files[@]}" -eq 0 ]; then
  # No Dart files in this edit — silently exit
  exit 0
fi

# ── Run dart format ───────────────────────────────────────────────────────────
for dart_file in "${dart_files[@]}"; do
  if [ -f "$dart_file" ]; then
    if ! dart format --fix "$dart_file" 2>&1; then
      echo "FlutterForge [post_edit_format]: Warning — dart format failed for $dart_file" >&2
    fi
  fi
done

exit 0
