#!/usr/bin/env bash
# LEGACY REFERENCE — Claude Code hooks now use hooks/lib-node/pre_commit_quality.cjs
# pre_commit_quality.sh — Quality gate before git commit.
#
# Triggered: PreToolUse on Bash.*git commit
# Env vars:
#   FLUTTERFORGE_SKIP_PRECOMMIT  — set to "1" to bypass all checks
#
# Steps:
#   1. dart format --set-exit-if-changed  (format check — fails if any file needs formatting)
#   2. flutter analyze --no-fatal-infos   (static analysis)
#   3. flutter test                        (unit/widget tests, only if test/ directory exists)
#
# Exit codes:
#   0  — all checks passed (or skipped via escape hatch)
#   1  — one or more checks failed (blocks the commit)

set -uo pipefail

# ── Escape hatch ──────────────────────────────────────────────────────────────
if [ "${FLUTTERFORGE_SKIP_PRECOMMIT:-}" = "1" ]; then
  echo "FlutterForge [pre_commit_quality]: Checks skipped (FLUTTERFORGE_SKIP_PRECOMMIT=1)"
  exit 0
fi

# ── Load flutter_guard ────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./flutter_guard.sh
source "$SCRIPT_DIR/flutter_guard.sh"
GUARD_EXIT=$?

if [ "$GUARD_EXIT" -eq 99 ]; then
  # Not a Flutter project — silently no-op
  exit 0
fi

cd "$FLUTTER_PROJECT_ROOT" || { echo "FlutterForge pre-commit: cannot cd to $FLUTTER_PROJECT_ROOT" >&2; exit 1; }

# Track overall failure
failed_checks=()

# ── Step 1: Format check ──────────────────────────────────────────────────────
echo "FlutterForge [pre_commit_quality]: Checking dart format..."
if ! dart format --set-exit-if-changed . 2>&1; then
  echo "" >&2
  echo "FlutterForge [pre_commit_quality]: FAILED — Unformatted Dart files detected." >&2
  echo "  Run: dart format ." >&2
  echo "  Then re-stage your files and commit again." >&2
  echo "  To skip: FLUTTERFORGE_SKIP_PRECOMMIT=1 git commit ..." >&2
  failed_checks+=("dart format")
fi

# ── Step 2: Static analysis ───────────────────────────────────────────────────
echo "FlutterForge [pre_commit_quality]: Running flutter analyze..."
# Stream output to terminal while capturing for summary
local analyze_tmp
analyze_tmp=$(mktemp)
flutter analyze --no-fatal-infos 2>&1 | tee "$analyze_tmp"
local analyze_exit=${PIPESTATUS[0]}
analyze_output=$(cat "$analyze_tmp")
rm -f "$analyze_tmp"
if [ "$analyze_exit" -ne 0 ]; then
  echo "" >&2
  echo "FlutterForge [pre_commit_quality]: FAILED — flutter analyze reported errors." >&2
  echo "$analyze_output" | tail -50 >&2
  echo "  Fix all errors before committing." >&2
  echo "  To skip: FLUTTERFORGE_SKIP_PRECOMMIT=1 git commit ..." >&2
  failed_checks+=("flutter analyze")
fi

# ── Step 3: Tests (only if test/ directory exists) ────────────────────────────
if [ -d "test" ]; then
  echo "FlutterForge [pre_commit_quality]: Running flutter test..."
  # Stream output to terminal while capturing for summary
  local test_tmp
  test_tmp=$(mktemp)
  flutter test 2>&1 | tee "$test_tmp"
  local test_exit=${PIPESTATUS[0]}
  test_output=$(cat "$test_tmp")
  rm -f "$test_tmp"
  if [ "$test_exit" -ne 0 ]; then
    echo "" >&2
    echo "FlutterForge [pre_commit_quality]: FAILED — flutter test reported failures." >&2
    echo "$test_output" | tail -30 >&2
    echo "  Fix all failing tests before committing." >&2
    echo "  To skip: FLUTTERFORGE_SKIP_PRECOMMIT=1 git commit ..." >&2
    failed_checks+=("flutter test")
  fi
else
  echo "FlutterForge [pre_commit_quality]: No test/ directory found — skipping flutter test."
fi

# ── Summary ───────────────────────────────────────────────────────────────────
if [ "${#failed_checks[@]}" -gt 0 ]; then
  echo "" >&2
  echo "FlutterForge [pre_commit_quality]: Commit blocked. Failed checks: ${failed_checks[*]}" >&2
  echo "  To bypass all checks: FLUTTERFORGE_SKIP_PRECOMMIT=1 git commit ..." >&2
  exit 1
fi

echo "FlutterForge [pre_commit_quality]: All quality checks passed."
exit 0
