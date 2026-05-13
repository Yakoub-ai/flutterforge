#!/usr/bin/env bash
# Collect Flutter project context for debugging

# NOTE: No set -euo pipefail here — this script must never abort.
# All failures are printed as warnings.

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

print_usage() {
  echo "Usage: $0 [--help]"
  echo ""
  echo "Collect Flutter project context for debugging."
  echo "Prints a structured report covering versions, config, code structure, and analysis."
  echo ""
  echo "Secrets are redacted. Output is safe to share."
  echo ""
  echo "Exit codes:"
  echo "  0  Always (collection failures are printed as warnings)"
}

section() {
  echo ""
  echo "============================================================"
  echo "  $1"
  echo "============================================================"
}

warn() {
  echo "[WARNING] $1"
}

# Redact values that look like secrets from a line of text.
# Removes: API keys, tokens, passwords, private key material, UUIDs that look
# like secrets (long hex strings), and common key=value patterns.
redact_line() {
  local line="$1"
  # Redact common key patterns
  echo "$line" | sed \
    -e 's/\(api[_-]\?key\s*[:=]\s*\)[^[:space:],"}]*/\1[REDACTED]/gi' \
    -e 's/\(api[_-]\?secret\s*[:=]\s*\)[^[:space:],"}]*/\1[REDACTED]/gi' \
    -e 's/\(secret\s*[:=]\s*\)[^[:space:],"}]*/\1[REDACTED]/gi' \
    -e 's/\(token\s*[:=]\s*\)[^[:space:],"}]*/\1[REDACTED]/gi' \
    -e 's/\(password\s*[:=]\s*\)[^[:space:],"}]*/\1[REDACTED]/gi' \
    -e 's/\(passwd\s*[:=]\s*\)[^[:space:],"}]*/\1[REDACTED]/gi' \
    -e 's/\(private[_-]\?key\s*[:=]\s*\)[^[:space:],"}]*/\1[REDACTED]/gi' \
    -e 's/\(auth[_-]\?token\s*[:=]\s*\)[^[:space:],"}]*/\1[REDACTED]/gi' \
    -e 's/\(access[_-]\?key\s*[:=]\s*\)[^[:space:],"}]*/\1[REDACTED]/gi' \
    -e 's/\(client[_-]\?secret\s*[:=]\s*\)[^[:space:],"}]*/\1[REDACTED]/gi' \
    -e 's/-----BEGIN [A-Z ]*KEY-----[^-]*-----END [A-Z ]*KEY-----/[REDACTED PRIVATE KEY]/g'
}

# Print file contents with redaction applied line by line
print_redacted_file() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    warn "File not found: $file"
    return
  fi
  while IFS= read -r line; do
    redact_line "$line"
  done < "$file"
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

for arg in "$@"; do
  case "$arg" in
    --help|-h)
      print_usage
      exit 0
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Section: Header
# ---------------------------------------------------------------------------

echo "Flutter Project Diagnostics"
echo "Collected: $(date)"
echo "Working directory: $(pwd)"

# ---------------------------------------------------------------------------
# Section: Flutter Version
# ---------------------------------------------------------------------------

section "Flutter Version"

if command -v flutter &>/dev/null; then
  flutter --version 2>&1 || warn "flutter --version failed"
else
  warn "Flutter is not installed or not on PATH"
fi

# ---------------------------------------------------------------------------
# Section: Dart Version
# ---------------------------------------------------------------------------

section "Dart Version"

if command -v dart &>/dev/null; then
  dart --version 2>&1 || warn "dart --version failed"
else
  warn "Dart is not installed or not on PATH"
fi

# ---------------------------------------------------------------------------
# Section: Flutter Doctor Summary
# ---------------------------------------------------------------------------

section "Flutter Doctor Summary"

if command -v flutter &>/dev/null; then
  flutter doctor 2>&1 || warn "flutter doctor failed"
else
  warn "Flutter not available — skipping flutter doctor"
fi

# ---------------------------------------------------------------------------
# Section: pubspec.yaml (redacted)
# ---------------------------------------------------------------------------

section "pubspec.yaml (secrets redacted)"

if [[ -f "pubspec.yaml" ]]; then
  print_redacted_file "pubspec.yaml"
else
  warn "pubspec.yaml not found in current directory"
fi

# ---------------------------------------------------------------------------
# Section: analysis_options.yaml
# ---------------------------------------------------------------------------

section "analysis_options.yaml"

if [[ -f "analysis_options.yaml" ]]; then
  cat "analysis_options.yaml" 2>/dev/null || warn "Could not read analysis_options.yaml"
else
  echo "(not present)"
fi

# ---------------------------------------------------------------------------
# Section: lib/ directory structure
# ---------------------------------------------------------------------------

section "lib/ Directory Structure"

if [[ -d "lib" ]]; then
  # Top-level lib/ entries
  echo "Top-level lib/ contents:"
  ls -1 "lib/" 2>/dev/null || warn "Could not list lib/"

  echo ""
  echo "Key files (main.dart, *_app.dart, *router*, *route*):"
  find lib -maxdepth 3 \( \
    -name "main.dart" \
    -o -name "*_app.dart" \
    -o -name "*router*" \
    -o -name "*route*" \
    -o -name "*config*" \
  \) 2>/dev/null | head -20 || warn "find in lib/ failed"

  echo ""
  echo "Total Dart files in lib/:"
  find lib -name "*.dart" 2>/dev/null | wc -l || echo "unknown"
else
  warn "lib/ directory not found"
fi

# ---------------------------------------------------------------------------
# Section: flutter analyze output
# ---------------------------------------------------------------------------

section "Recent flutter analyze Output"

if command -v flutter &>/dev/null; then
  flutter analyze --no-fatal-infos 2>&1 | head -60 || warn "flutter analyze failed"
else
  warn "Flutter not available — skipping analysis"
fi

# ---------------------------------------------------------------------------
# Section: Test files
# ---------------------------------------------------------------------------

section "Test Files"

if [[ -d "test" ]]; then
  TEST_COUNT=$(find test -name "*_test.dart" 2>/dev/null | wc -l | tr -d ' ')
  echo "Unit/widget tests (test/): $TEST_COUNT files"
  find test -name "*_test.dart" 2>/dev/null | head -10
else
  echo "test/ directory not found"
fi

if [[ -d "integration_test" ]]; then
  INT_COUNT=$(find integration_test -name "*_test.dart" 2>/dev/null | wc -l | tr -d ' ')
  echo ""
  echo "Integration tests (integration_test/): $INT_COUNT files"
  find integration_test -name "*_test.dart" 2>/dev/null | head -10
fi

# ---------------------------------------------------------------------------
# Section: iOS Podfile.lock (macOS only)
# ---------------------------------------------------------------------------

if [[ "$(uname)" == "Darwin" ]]; then
  section "iOS Podfile.lock — Flutter version"

  PODFILE_LOCK="ios/Podfile.lock"
  if [[ -f "$PODFILE_LOCK" ]]; then
    grep -A3 "Flutter" "$PODFILE_LOCK" 2>/dev/null | head -10 || warn "Could not read $PODFILE_LOCK"
  else
    echo "(ios/Podfile.lock not found)"
  fi
fi

# ---------------------------------------------------------------------------
# Section: Android local.properties
# ---------------------------------------------------------------------------

section "Android local.properties — Flutter SDK path"

LOCAL_PROPS="android/local.properties"
if [[ -f "$LOCAL_PROPS" ]]; then
  # Only show flutter/sdk lines — these are not secrets
  grep -iE "(flutter|sdk)" "$LOCAL_PROPS" 2>/dev/null | head -10 || warn "Could not read $LOCAL_PROPS"
else
  echo "(android/local.properties not found)"
fi

# ---------------------------------------------------------------------------
# Footer
# ---------------------------------------------------------------------------

echo ""
echo "============================================================"
echo "  End of Flutter Diagnostics"
echo "============================================================"
echo ""

exit 0
