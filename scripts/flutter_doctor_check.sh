#!/usr/bin/env bash
# Check Flutter installation and environment health

set -uo pipefail

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

print_usage() {
  echo "Usage: $0 [--help]"
  echo ""
  echo "Check Flutter installation and environment health."
  echo "Runs 'flutter doctor -v' and prints a human-readable summary."
  echo ""
  echo "Exit codes:"
  echo "  0  Flutter is installed (warnings are not blocking)"
  echo "  1  Flutter is not installed"
}

section() {
  echo ""
  echo "=========================================="
  echo "  $1"
  echo "=========================================="
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
    *)
      echo "Unknown argument: $arg"
      print_usage
      exit 1
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Check Flutter is installed
# ---------------------------------------------------------------------------

if ! command -v flutter &>/dev/null; then
  echo ""
  echo "[ERROR] Flutter is not installed or not on PATH."
  echo ""
  echo "To install Flutter, visit: https://docs.flutter.dev/get-started/install"
  echo ""
  echo "If Flutter is installed but not on PATH, add the Flutter bin directory to your PATH."
  echo "  macOS/Linux: export PATH=\"\$HOME/flutter/bin:\$PATH\""
  echo "  Windows (Git Bash): export PATH=\"\$HOME/flutter/bin:\$PATH\""
  exit 1
fi

# ---------------------------------------------------------------------------
# Run flutter doctor
# ---------------------------------------------------------------------------

section "Flutter Doctor Output"

DOCTOR_OUTPUT=$(flutter doctor -v 2>&1)
echo "$DOCTOR_OUTPUT"

# ---------------------------------------------------------------------------
# Parse and summarise results
# ---------------------------------------------------------------------------

section "Summary"

FLUTTER_VERSION=$(flutter --version 2>/dev/null | head -1 || echo "unknown")
echo "Flutter: $FLUTTER_VERSION"
echo ""

# Count ticks, exclamation marks, and crosses in doctor output
OK_COUNT=$(echo "$DOCTOR_OUTPUT" | grep -c "^\\[✓\\]" || true)
WARN_COUNT=$(echo "$DOCTOR_OUTPUT" | grep -c "^\\[!\\]" || true)
ERR_COUNT=$(echo "$DOCTOR_OUTPUT" | grep -c "^\\[✗\\]" || true)

# Also try ASCII fallbacks that some terminals produce
OK_COUNT=$((OK_COUNT + $(echo "$DOCTOR_OUTPUT" | grep -c "^\[v\]" || true)))
WARN_COUNT=$((WARN_COUNT + $(echo "$DOCTOR_OUTPUT" | grep -c "^\[!\]" || true)))
ERR_COUNT=$((ERR_COUNT + $(echo "$DOCTOR_OUTPUT" | grep -c "^\[x\]" || true)))

echo "Working:          $OK_COUNT component(s)"
echo "Needs attention:  $WARN_COUNT component(s)"
echo "Not available:    $ERR_COUNT component(s)"
echo ""

# ---------------------------------------------------------------------------
# Check specific tools and give actionable hints
# ---------------------------------------------------------------------------

NEEDS_ATTENTION=()

# Android SDK
if echo "$DOCTOR_OUTPUT" | grep -qi "android toolchain"; then
  if echo "$DOCTOR_OUTPUT" | grep -A5 -i "android toolchain" | grep -qiE "(\[!\]|\[x\]|issue|missing|not found)"; then
    NEEDS_ATTENTION+=("Android SDK / toolchain — run 'flutter doctor --android-licenses' or install Android Studio")
  fi
fi

# Xcode (macOS only)
if [[ "$(uname)" == "Darwin" ]]; then
  if echo "$DOCTOR_OUTPUT" | grep -qi "xcode"; then
    if echo "$DOCTOR_OUTPUT" | grep -A5 -i "xcode" | grep -qiE "(\[!\]|\[x\]|not installed|version|missing)"; then
      NEEDS_ATTENTION+=("Xcode — install or update from the App Store, then run 'sudo xcode-select --switch /Applications/Xcode.app'")
    fi
  fi

  # CocoaPods
  if echo "$DOCTOR_OUTPUT" | grep -qi "cocoapods"; then
    if echo "$DOCTOR_OUTPUT" | grep -A3 -i "cocoapods" | grep -qiE "(\[!\]|\[x\]|not installed|missing)"; then
      NEEDS_ATTENTION+=("CocoaPods — run 'sudo gem install cocoapods' or 'brew install cocoapods'")
    fi
  fi
fi

# VS Code / Android Studio
if echo "$DOCTOR_OUTPUT" | grep -qiE "(no ide|no supported)"; then
  NEEDS_ATTENTION+=("IDE — install Android Studio or VS Code with the Flutter extension")
fi

if [[ ${#NEEDS_ATTENTION[@]} -gt 0 ]]; then
  echo "Items needing attention:"
  for item in "${NEEDS_ATTENTION[@]}"; do
    echo "  • $item"
  done
  echo ""
  echo "These are warnings only — Flutter development can continue."
else
  echo "No critical issues detected. Flutter environment looks healthy."
fi

echo ""
exit 0
