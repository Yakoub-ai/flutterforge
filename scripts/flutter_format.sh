#!/usr/bin/env bash
# Format all Dart files in the project

set -euo pipefail

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

print_usage() {
  echo "Usage: $0 [--check] [--path <dir>] [--help]"
  echo ""
  echo "Format Dart files using 'dart format'."
  echo ""
  echo "Flags:"
  echo "  --check         Check formatting without modifying files"
  echo "                  Exits 1 if any files need reformatting"
  echo "  --path <dir>    Format/check a specific directory (default: current directory)"
  echo "  --help          Show this message"
  echo ""
  echo "Exit codes:"
  echo "  0  All files are formatted (or were successfully reformatted)"
  echo "  1  --check mode: unformatted files were found"
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

CHECK_ONLY=false
FORMAT_PATH="."

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check)
      CHECK_ONLY=true
      shift
      ;;
    --path)
      if [[ -z "${2:-}" ]]; then
        echo "[ERROR] --path requires a directory argument"
        exit 1
      fi
      FORMAT_PATH="$2"
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

if [[ ! -d "$FORMAT_PATH" ]]; then
  echo "[ERROR] Directory not found: $FORMAT_PATH"
  exit 1
fi

# ---------------------------------------------------------------------------
# Check dart is installed
# ---------------------------------------------------------------------------

if ! command -v dart &>/dev/null; then
  echo "[ERROR] Dart is not installed or not on PATH."
  echo "Dart is bundled with Flutter. Ensure Flutter is installed and on your PATH."
  exit 1
fi

# ---------------------------------------------------------------------------
# Run dart format
# ---------------------------------------------------------------------------

if [[ "$CHECK_ONLY" == "true" ]]; then
  echo "Checking Dart formatting in $FORMAT_PATH ..."
  echo ""

  # --set-exit-if-changed exits 1 if any file would change
  set +e
  FORMAT_OUTPUT=$(dart format --set-exit-if-changed "$FORMAT_PATH" 2>&1)
  FORMAT_EXIT=$?
  set -e

  echo "$FORMAT_OUTPUT"
  echo ""

  # Count changed files from output (dart format prints "Formatted X files")
  CHANGED=$(echo "$FORMAT_OUTPUT" | grep -oE "Formatted [0-9]+ file" | grep -oE "[0-9]+" | head -1 || true)
  CHANGED="${CHANGED:-0}"

  if [[ "$FORMAT_EXIT" -ne 0 ]] || [[ "$CHANGED" -gt 0 ]]; then
    echo "------------------------------------------"
    echo "Formatting check: FAILED"
    echo "  $CHANGED file(s) would be reformatted"
    echo ""
    echo "Run without --check to apply formatting:"
    echo "  bash $0 --path $FORMAT_PATH"
    echo "------------------------------------------"
    exit 1
  fi

  echo "------------------------------------------"
  echo "Formatting check: PASSED"
  echo "  All files are already formatted"
  echo "------------------------------------------"
  exit 0

else
  echo "Formatting Dart files in $FORMAT_PATH ..."
  echo ""

  FORMAT_OUTPUT=$(dart format "$FORMAT_PATH" 2>&1)
  echo "$FORMAT_OUTPUT"
  echo ""

  # Parse how many files were changed
  CHANGED=$(echo "$FORMAT_OUTPUT" | grep -oE "Formatted [0-9]+ file" | grep -oE "[0-9]+" | head -1 || true)
  UNCHANGED=$(echo "$FORMAT_OUTPUT" | grep -oE "unchanged" | head -1 || true)

  echo "------------------------------------------"
  if [[ -n "$CHANGED" && "$CHANGED" -gt 0 ]]; then
    echo "Formatting: $CHANGED file(s) reformatted"
  else
    echo "Formatting: All files already formatted"
  fi
  echo "------------------------------------------"
  exit 0
fi
