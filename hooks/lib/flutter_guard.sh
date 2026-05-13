#!/usr/bin/env bash
# LEGACY REFERENCE — Claude Code hooks now use Node.js scripts in hooks/lib-node/.
# This file is kept for shell-script reference only; it is no longer wired in hooks.json.
# flutter_guard.sh — Walk up from $PWD to find a Flutter project root.
#
# Usage: source this script or run it directly.
#   - If pubspec.yaml is found: exports FLUTTER_PROJECT_ROOT, exits 0
#   - If not found after 5 levels: exits 99 (callers treat this as a no-op)
#
# Compatible with: macOS, Linux, Git Bash on Windows

_flutter_guard_find_root() {
  local dir
  dir="$(pwd)"
  local depth=0
  local max_depth=5

  while [ "$depth" -le "$max_depth" ]; do
    if [ -f "$dir/pubspec.yaml" ]; then
      export FLUTTER_PROJECT_ROOT="$dir"
      return 0
    fi

    # Stop at filesystem root
    local parent
    parent="$(dirname "$dir")"
    if [ "$parent" = "$dir" ]; then
      break
    fi

    dir="$parent"
    depth=$(( depth + 1 ))
  done

  return 99
}

# Run the check. When sourced, the caller can check the return value via $?.
# When executed directly, we propagate the exit code.
_flutter_guard_find_root
