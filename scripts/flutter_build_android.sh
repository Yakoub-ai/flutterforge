#!/usr/bin/env bash
# Build Android release artifacts

set -euo pipefail

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

print_usage() {
  echo "Usage: $0 [--apk|--appbundle] [--flavor <name>] [--dart-define KEY=VALUE] [--help]"
  echo ""
  echo "Build Android release artifacts."
  echo ""
  echo "Flags:"
  echo "  --apk                    Build an APK (default: App Bundle)"
  echo "  --appbundle              Build an App Bundle (default)"
  echo "  --flavor <name>          Specify a build flavor"
  echo "  --dart-define KEY=VALUE  Pass a Dart define (may be repeated)"
  echo "  --help                   Show this message"
  echo ""
  echo "Exit codes:"
  echo "  0  Build succeeded"
  echo "  1  Build failed"
}

diagnose_failure() {
  local output="$1"

  echo ""
  echo "Build failed. Possible causes:"

  if echo "$output" | grep -qiE "(gradle|daemon)"; then
    echo "  • Gradle issue — try deleting .gradle/ and rebuild:"
    echo "      rm -rf ~/.gradle/caches && flutter clean && flutter pub get"
  fi

  if echo "$output" | grep -qiE "(keystore|signing|jks|key\.properties)"; then
    echo "  • Signing / keystore issue — check android/key.properties and that your keystore file exists"
  fi

  if echo "$output" | grep -qiE "(sdk|ndk|build.tools|platform)"; then
    echo "  • Android SDK issue — open Android Studio → SDK Manager and install missing components"
    echo "      Also run: flutter doctor"
  fi

  if echo "$output" | grep -qiE "(compileSdkVersion|targetSdkVersion|minSdkVersion)"; then
    echo "  • SDK version conflict — check android/app/build.gradle"
  fi

  if echo "$output" | grep -qiE "(could not resolve|dependency|pub)"; then
    echo "  • Dependency issue — run: flutter pub get"
  fi

  echo ""
  echo "Full output is shown above. Run 'flutter doctor' for environment status."
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

BUILD_TYPE="appbundle"
FLAVOR=""
DART_DEFINES=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apk)
      BUILD_TYPE="apk"
      shift
      ;;
    --appbundle)
      BUILD_TYPE="appbundle"
      shift
      ;;
    --flavor)
      if [[ -z "${2:-}" ]]; then
        echo "[ERROR] --flavor requires a name argument"
        exit 1
      fi
      FLAVOR="$2"
      shift 2
      ;;
    --dart-define)
      if [[ -z "${2:-}" ]]; then
        echo "[ERROR] --dart-define requires a KEY=VALUE argument"
        exit 1
      fi
      DART_DEFINES+=("--dart-define=$2")
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
# Build the command
# ---------------------------------------------------------------------------

CMD=(flutter build "$BUILD_TYPE" --release)

if [[ -n "$FLAVOR" ]]; then
  CMD+=("--flavor" "$FLAVOR")
fi

if [[ ${#DART_DEFINES[@]} -gt 0 ]]; then
  CMD+=("${DART_DEFINES[@]}")
fi

# ---------------------------------------------------------------------------
# Run build
# ---------------------------------------------------------------------------

echo "Building Android $BUILD_TYPE (release) ..."
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

  # Print output artifact location
  if [[ "$BUILD_TYPE" == "appbundle" ]]; then
    ARTIFACT=$(find build/app/outputs/bundle -name "*.aab" 2>/dev/null | head -1 || true)
  else
    ARTIFACT=$(find build/app/outputs/flutter-apk -name "*.apk" 2>/dev/null | head -1 || true)
    # Fallback for older Flutter versions
    if [[ -z "$ARTIFACT" ]]; then
      ARTIFACT=$(find build/app/outputs/apk -name "*.apk" 2>/dev/null | head -1 || true)
    fi
  fi

  if [[ -n "$ARTIFACT" ]]; then
    echo "Output: $ARTIFACT"
  else
    echo "Output: build/app/outputs/ (artifact path not auto-detected)"
  fi
  echo "------------------------------------------"
  exit 0
else
  echo "Build: FAILED (exit code $BUILD_EXIT)"
  echo "------------------------------------------"
  diagnose_failure "$BUILD_OUTPUT"
  exit 1
fi
