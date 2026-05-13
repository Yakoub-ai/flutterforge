#!/usr/bin/env bash
# Run flutter analyze with sensible defaults

set -euo pipefail

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

print_usage() {
  echo "Usage: $0 [--fix] [--path <dir>] [--help]"
  echo ""
  echo "Run flutter analyze with sensible defaults."
  echo ""
  echo "Flags:"
  echo "  --fix           Run 'dart fix --apply' before analysing"
  echo "  --path <dir>    Analyse a specific directory (default: current directory)"
  echo "  --help          Show this message"
  echo ""
  echo "Exit codes:"
  echo "  0  No errors (warnings and infos are non-blocking)"
  echo "  1  One or more errors found"
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

RUN_FIX=false
ANALYZE_PATH="."

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fix)
      RUN_FIX=true
      shift
      ;;
    --path)
      if [[ -z "${2:-}" ]]; then
        echo "[ERROR] --path requires a directory argument"
        exit 1
      fi
      ANALYZE_PATH="$2"
      shift 2
      ;;
    --help|-h)
      print_usage
      exit 0
      ;;
    *)
      echo "[ERROR] Unknown argument: $1"
      print_usage
      exit 1
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Validate path
# ---------------------------------------------------------------------------

if [[ ! -d "$ANALYZE_PATH" ]]; then
  echo "[ERROR] Directory not found: $ANALYZE_PATH"
  exit 1
fi

# ---------------------------------------------------------------------------
# Check Flutter is installed
# ---------------------------------------------------------------------------

if ! command -v flutter &>/dev/null; then
  echo "[ERROR] Flutter is not installed or not on PATH."
  exit 1
fi

# ---------------------------------------------------------------------------
# Optional: dart fix
# ---------------------------------------------------------------------------

if [[ "$RUN_FIX" == "true" ]]; then
  echo "Running dart fix --apply in $ANALYZE_PATH ..."
  (cd "$ANALYZE_PATH" && dart fix --apply)
  echo ""
fi

# ---------------------------------------------------------------------------
# Run flutter analyze
# ---------------------------------------------------------------------------

echo "Running flutter analyze in $ANALYZE_PATH ..."
echo ""

# Capture output; allow non-zero exit so we can parse ourselves
ANALYZE_OUTPUT=$(cd "$ANALYZE_PATH" && flutter analyze --no-fatal-infos 2>&1) || true

echo "$ANALYZE_OUTPUT"
echo ""

# ---------------------------------------------------------------------------
# Parse output into categories
# ---------------------------------------------------------------------------

ERROR_COUNT=0
WARNING_COUNT=0
INFO_COUNT=0

while IFS= read -r line; do
  # flutter analyze lines look like:
  #   error • <message> • file.dart:10:5 • rule_name
  #   warning • <message> • file.dart:10:5 • rule_name
  #   info • <message> • file.dart:10:5 • rule_name
  if echo "$line" | grep -qiE "^[[:space:]]*(error|•.*error)"; then
    ERROR_COUNT=$((ERROR_COUNT + 1))
  elif echo "$line" | grep -qiE "^[[:space:]]*(warning|•.*warning)"; then
    WARNING_COUNT=$((WARNING_COUNT + 1))
  elif echo "$line" | grep -qiE "^[[:space:]]*(info|hint|•.*info|•.*hint)"; then
    INFO_COUNT=$((INFO_COUNT + 1))
  fi
done <<< "$ANALYZE_OUTPUT"

# Also check the summary line emitted by flutter analyze itself
# e.g. "3 issues found." or "No issues found!"
SUMMARY_LINE=$(echo "$ANALYZE_OUTPUT" | grep -iE "(issues? found|no issues)" | tail -1 || true)

# ---------------------------------------------------------------------------
# Print summary
# ---------------------------------------------------------------------------

echo "------------------------------------------"
echo "Analysis summary"
echo "------------------------------------------"
echo "  Errors:   $ERROR_COUNT"
echo "  Warnings: $WARNING_COUNT"
echo "  Infos:    $INFO_COUNT"
if [[ -n "$SUMMARY_LINE" ]]; then
  echo ""
  echo "  Flutter: $SUMMARY_LINE"
fi
echo "------------------------------------------"
echo ""

# ---------------------------------------------------------------------------
# Exit code
# ---------------------------------------------------------------------------

if echo "$ANALYZE_OUTPUT" | grep -qiE "^(error • |[0-9]+ error)"; then
  echo "[FAIL] Analysis found errors."
  exit 1
fi

# If flutter analyze itself exited non-zero (captured above), also fail
if echo "$ANALYZE_OUTPUT" | grep -qiE "issues? found" && ! echo "$ANALYZE_OUTPUT" | grep -qiE "^0 issues|no issues"; then
  # Check whether any were actual errors rather than warnings/infos
  if [[ "$ERROR_COUNT" -gt 0 ]]; then
    echo "[FAIL] Analysis found $ERROR_COUNT error(s)."
    exit 1
  fi
fi

echo "[PASS] Analysis complete — no errors."
exit 0
