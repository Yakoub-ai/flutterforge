#!/usr/bin/env bash
# Run Flutter tests with optional coverage

set -euo pipefail

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

print_usage() {
  echo "Usage: $0 [--coverage] [--integration] [--golden] [--watch] [--path <file-or-dir>] [--help]"
  echo ""
  echo "Run Flutter tests with optional coverage, integration, or golden modes."
  echo ""
  echo "Flags:"
  echo "  --coverage          Collect code coverage; reports percentage from coverage/lcov.info"
  echo "  --integration       Run tests in integration_test/ directory"
  echo "  --golden            Pass --update-goldens to update golden image files"
  echo "  --watch             Run tests in watch mode (re-runs on file changes)"
  echo "  --path <p>          Target a specific test file or directory"
  echo "  --help              Show this message"
  echo ""
  echo "Exit codes:"
  echo "  0  All tests passed"
  echo "  1  One or more tests failed"
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

COVERAGE=false
INTEGRATION=false
GOLDEN=false
WATCH=false
TEST_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --coverage)
      COVERAGE=true
      shift
      ;;
    --integration)
      INTEGRATION=true
      shift
      ;;
    --golden)
      GOLDEN=true
      shift
      ;;
    --watch)
      WATCH=true
      shift
      ;;
    --path)
      if [[ -z "${2:-}" ]]; then
        echo "[ERROR] --path requires a file or directory argument"
        exit 1
      fi
      TEST_PATH="$2"
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
# Check Flutter is installed
# ---------------------------------------------------------------------------

if ! command -v flutter &>/dev/null; then
  echo "[ERROR] Flutter is not installed or not on PATH."
  exit 1
fi

# ---------------------------------------------------------------------------
# Build flutter test command
# ---------------------------------------------------------------------------

CMD=(flutter test)

# Integration tests target integration_test/ unless a specific path is given
if [[ "$INTEGRATION" == "true" ]]; then
  if [[ -z "$TEST_PATH" ]]; then
    if [[ -d "integration_test" ]]; then
      CMD+=("integration_test/")
    else
      echo "[ERROR] --integration specified but integration_test/ directory not found."
      exit 1
    fi
  else
    CMD+=("$TEST_PATH")
  fi
elif [[ -n "$TEST_PATH" ]]; then
  CMD+=("$TEST_PATH")
fi

if [[ "$COVERAGE" == "true" ]]; then
  CMD+=("--coverage")
fi

if [[ "$GOLDEN" == "true" ]]; then
  CMD+=("--update-goldens")
fi

if [[ "$WATCH" == "true" ]]; then
  CMD+=("--watch")
fi

# ---------------------------------------------------------------------------
# Run tests
# ---------------------------------------------------------------------------

echo "Running: ${CMD[*]}"
echo ""

# Capture output while still streaming it (tee to stderr for live view)
TEST_OUTPUT_FILE=$(mktemp)
set +e
"${CMD[@]}" 2>&1 | tee "$TEST_OUTPUT_FILE"
TEST_EXIT_CODE=${PIPESTATUS[0]}
set -e

TEST_OUTPUT=$(cat "$TEST_OUTPUT_FILE")
rm -f "$TEST_OUTPUT_FILE"

# ---------------------------------------------------------------------------
# Parse test result summary
# ---------------------------------------------------------------------------

echo ""
echo "------------------------------------------"
echo "Test summary"
echo "------------------------------------------"

# Flutter test prints a line like:
#   00:05 +42: All tests passed!
#   00:05 +40 -2: Some tests failed.
# or (with counts):
#   Some tests failed: 2 passed, 1 failed
PASSED=0
FAILED=0
SKIPPED=0

RESULT_LINE=$(echo "$TEST_OUTPUT" | grep -oE "[0-9]+ passed|[0-9]+ failed|[0-9]+ skipped" || true)

while IFS= read -r chunk; do
  if echo "$chunk" | grep -q "passed"; then
    PASSED=$(echo "$chunk" | grep -oE "[0-9]+")
  elif echo "$chunk" | grep -q "failed"; then
    FAILED=$(echo "$chunk" | grep -oE "[0-9]+")
  elif echo "$chunk" | grep -q "skipped"; then
    SKIPPED=$(echo "$chunk" | grep -oE "[0-9]+")
  fi
done <<< "$RESULT_LINE"

# Fallback: parse the "+N -M" format from flutter's progress line
if [[ "$PASSED" -eq 0 && "$FAILED" -eq 0 ]]; then
  LAST_STATUS=$(echo "$TEST_OUTPUT" | grep -oE "\+[0-9]+" | tail -1 | tr -d '+' || true)
  LAST_FAILED=$(echo "$TEST_OUTPUT" | grep -oE "\-[0-9]+" | tail -1 | tr -d '-' || true)
  PASSED="${LAST_STATUS:-0}"
  FAILED="${LAST_FAILED:-0}"
fi

echo "  Passed:  $PASSED"
echo "  Failed:  $FAILED"
echo "  Skipped: $SKIPPED"
echo "------------------------------------------"

# ---------------------------------------------------------------------------
# Coverage report
# ---------------------------------------------------------------------------

if [[ "$COVERAGE" == "true" ]]; then
  echo ""
  LCOV_FILE="coverage/lcov.info"
  if [[ -f "$LCOV_FILE" ]]; then
    TOTAL_LINES=0
    HIT_LINES=0
    while IFS= read -r lcov_line; do
      if [[ "$lcov_line" == DA:* ]]; then
        TOTAL_LINES=$((TOTAL_LINES + 1))
        COUNT=$(echo "$lcov_line" | cut -d',' -f2)
        if [[ "$COUNT" -gt 0 ]]; then
          HIT_LINES=$((HIT_LINES + 1))
        fi
      fi
    done < "$LCOV_FILE"

    if [[ "$TOTAL_LINES" -gt 0 ]]; then
      # Use awk for floating-point percentage
      COVERAGE_PCT=$(awk "BEGIN { printf \"%.1f\", ($HIT_LINES / $TOTAL_LINES) * 100 }")
      echo "Coverage: $HIT_LINES / $TOTAL_LINES lines ($COVERAGE_PCT%)"
    else
      echo "Coverage: no instrumented lines found in $LCOV_FILE"
    fi
  else
    echo "Coverage: $LCOV_FILE not found (coverage may not have been collected)"
  fi
fi

echo ""

# ---------------------------------------------------------------------------
# Exit
# ---------------------------------------------------------------------------

if [[ "$TEST_EXIT_CODE" -ne 0 ]]; then
  echo "[FAIL] Tests failed."
  exit 1
fi

echo "[PASS] All tests passed."
exit 0
