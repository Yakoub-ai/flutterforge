#!/usr/bin/env bash
# Build iOS release artifacts (requires macOS)

set -euo pipefail

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

print_usage() {
  echo "Usage: $0 [--simulator] [--export-plist <path>] [--help]"
  echo ""
  echo "Build iOS release artifacts."
  echo "This script requires macOS. On Windows/Linux it exits 0 with an informational message."
  echo ""
  echo "Flags:"
  echo "  --simulator             Build for iOS Simulator instead of device"
  echo "  --export-plist <path>   Path to ExportOptions.plist for IPA export"
  echo "  --help                  Show this message"
  echo ""
  echo "Exit codes:"
  echo "  0  Build succeeded, or not running on macOS (not an error)"
  echo "  1  Build failed (macOS only)"
}

diagnose_failure() {
  local output="$1"

  echo ""
  echo "Build failed. Possible causes:"

  if echo "$output" | grep -qiE "(cocoapods|pod install|podfile)"; then
    echo "  • CocoaPods issue — run: cd ios && pod install --repo-update"
    echo "    If CocoaPods is not installed: sudo gem install cocoapods"
    echo "    Or with Homebrew: brew install cocoapods"
  fi

  if echo "$output" | grep -qiE "(xcode|xcrun|xcodebuild)"; then
    if echo "$output" | grep -qiE "(version|requires|upgrade|update)"; then
      echo "  • Xcode version too old — update Xcode from the App Store"
    else
      echo "  • Xcode issue — ensure Xcode is installed and command-line tools are set:"
      echo "      sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer"
      echo "      sudo xcodebuild -license accept"
    fi
  fi

  if echo "$output" | grep -qiE "(signing|certificate|provisioning|entitlement|codesign)"; then
    echo "  • Code signing issue — check Xcode → Signing & Capabilities"
    echo "    Ensure your team, bundle ID, and provisioning profiles are configured"
    echo "    For CI: use 'flutter build ios --no-codesign' and sign separately"
  fi

  if echo "$output" | grep -qiE "(simulator|device)"; then
    echo "  • Target issue — use --simulator to build for Simulator, or connect a device"
  fi

  if echo "$output" | grep -qiE "(dependency|pub get|pubspec)"; then
    echo "  • Dependency issue — run: flutter pub get"
  fi

  echo ""
  echo "Full output is shown above. Run 'flutter doctor' for environment status."
}

# ---------------------------------------------------------------------------
# Non-macOS early exit
# ---------------------------------------------------------------------------

if [[ "$(uname)" != "Darwin" ]]; then
  echo "iOS builds require macOS."
  echo ""
  echo "You are running on $(uname). iOS build skipped — this is not an error."
  echo ""
  echo "To build for iOS, run this script on a macOS machine."
  exit 0
fi

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

SIMULATOR=false
EXPORT_PLIST=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --simulator)
      SIMULATOR=true
      shift
      ;;
    --export-plist)
      if [[ -z "${2:-}" ]]; then
        echo "[ERROR] --export-plist requires a file path argument"
        exit 1
      fi
      EXPORT_PLIST="$2"
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
# Validate export plist if given
# ---------------------------------------------------------------------------

if [[ -n "$EXPORT_PLIST" && ! -f "$EXPORT_PLIST" ]]; then
  echo "[ERROR] Export plist not found: $EXPORT_PLIST"
  exit 1
fi

# ---------------------------------------------------------------------------
# Build the command
# ---------------------------------------------------------------------------

if [[ "$SIMULATOR" == "true" ]]; then
  CMD=(flutter build ios --simulator)
else
  CMD=(flutter build ios --release)
fi

if [[ -n "$EXPORT_PLIST" ]]; then
  CMD+=("--export-options-plist=$EXPORT_PLIST")
fi

# ---------------------------------------------------------------------------
# Run build
# ---------------------------------------------------------------------------

echo "Building iOS $( [[ "$SIMULATOR" == "true" ]] && echo "simulator" || echo "release" ) ..."
echo "Command: ${CMD[*]}"
echo ""

BUILD_OUTPUT_FILE=$(mktemp)
set +e
"${CMD[@]}" 2>&1 | tee "$BUILD_OUTPUT_FILE"
BUILD_EXIT=${PIPESTATUS[0]}
set -e

BUILD_OUTPUT=$(cat "$BUILD_OUTPUT_FILE")
rm -f "$BUILD_OUTPUT_FILE"

# ---------------------------------------------------------------------------
# Report result
# ---------------------------------------------------------------------------

echo ""
echo "------------------------------------------"

if [[ "$BUILD_EXIT" -eq 0 ]]; then
  echo "Build: SUCCESS"
  echo ""

  # Try to locate the .app or .ipa
  if [[ "$SIMULATOR" == "true" ]]; then
    ARTIFACT=$(find build/ios/iphonesimulator -name "*.app" 2>/dev/null | head -1 || true)
    ARTIFACT_DIR="build/ios/iphonesimulator/"
  else
    ARTIFACT=$(find build/ios/iphoneos -name "*.app" 2>/dev/null | head -1 || true)
    ARTIFACT_DIR="build/ios/iphoneos/"
  fi

  if [[ -n "$ARTIFACT" ]]; then
    echo "Output: $ARTIFACT"
  else
    echo "Output: $ARTIFACT_DIR (artifact path not auto-detected)"
  fi
  echo "------------------------------------------"
  exit 0
else
  echo "Build: FAILED (exit code $BUILD_EXIT)"
  echo "------------------------------------------"
  diagnose_failure "$BUILD_OUTPUT"
  exit 1
fi
