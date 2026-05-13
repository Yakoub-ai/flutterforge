#!/usr/bin/env bash
# LEGACY REFERENCE — Claude Code hooks now use hooks/lib-node/secret_detect.cjs
# secret_detect.sh — Detect secrets in files being written; block if found.
#
# Triggered: PreToolUse on Write|Edit
# Env vars:
#   FLUTTERFORGE_SKIP_SECRET_CHECK  — set to "1" to bypass detection
#   CLAUDE_FILE_PATHS               — space-separated list of target file paths
#   CLAUDE_FILE_CONTENT             — file content passed directly by the hook runtime
#
# NOTE: Does NOT use set -e because pattern matching may return non-zero
#       intentionally. Exit codes are managed explicitly.

# ── Escape hatch ──────────────────────────────────────────────────────────────
if [ "${FLUTTERFORGE_SKIP_SECRET_CHECK:-}" = "1" ]; then
  exit 0
fi

# ── Allowlist terms — skip lines containing these (case-insensitive) ──────────
# Values that are clearly placeholders, not real secrets.
ALLOWLIST_PATTERN='test_key|example_token|FAKE_|YOUR_|<YOUR_|xxx|dummy|placeholder'

# ── Secret patterns: name:regex pairs ─────────────────────────────────────────
declare -A SECRET_PATTERNS
SECRET_PATTERNS["Google API key"]='AIza[0-9A-Za-z\-_]{35}'
SECRET_PATTERNS["Google OAuth token"]='ya29\.[0-9A-Za-z\-_]+'
SECRET_PATTERNS["FCM legacy server key"]='AAAA[A-Za-z0-9_-]{7}:[A-Za-z0-9_-]{140}'
SECRET_PATTERNS["OpenAI API key"]='sk-[a-zA-Z0-9]{48}'
# Anthropic keys: sk-ant-api03-... or sk-ant-admin-... etc
SECRET_PATTERNS["Anthropic API key"]='sk-ant-[a-zA-Z0-9_\-]{60,120}'
SECRET_PATTERNS["Generic secret assignment"]='[sS][eE][cC][rR][eE][tT].*=.*['"'"'"][^'"'"'"]{8,}['"'"'"]'
SECRET_PATTERNS["Hardcoded password"]='password[[:space:]]*=[[:space:]]*['"'"'"][^'"'"'"]+['"'"'"]'
SECRET_PATTERNS["Private key block"]='private_key'

# ── Collect content to scan ───────────────────────────────────────────────────
content_to_scan=""

if [ -n "${CLAUDE_FILE_CONTENT:-}" ]; then
  # Hook runtime provided content directly
  content_to_scan="$CLAUDE_FILE_CONTENT"
elif [ -n "${CLAUDE_FILE_PATHS:-}" ]; then
  # Fall back to reading the target files
  IFS=' ' read -ra file_list <<< "$CLAUDE_FILE_PATHS"
  for f in "${file_list[@]}"; do
    if [ -f "$f" ]; then
      content_to_scan="${content_to_scan}
$(cat "$f")"
    fi
  done
fi

if [ -z "$content_to_scan" ]; then
  # Nothing to scan
  exit 0
fi

# ── Special combined check: private_key + BEGIN block ─────────────────────────
# Only flag if BOTH markers appear in the content (avoids false positives on
# variable names like `privateKeyPath`).
check_private_key() {
  local c="$1"
  if echo "$c" | grep -qiE 'private_key' && echo "$c" | grep -qF '-----BEGIN'; then
    # Check allowlist
    local matching_line
    matching_line="$(echo "$c" | grep -iE 'private_key' | head -1)"
    if ! echo "$matching_line" | grep -iqE "$ALLOWLIST_PATTERN"; then
      echo "FlutterForge [secret_detect]: BLOCKED — Possible private key detected (private_key + BEGIN block)." >&2
      echo "  If this is intentional, set FLUTTERFORGE_SKIP_SECRET_CHECK=1" >&2
      return 1
    fi
  fi
  return 0
}

# ── Scan each pattern ─────────────────────────────────────────────────────────
found_secret=false

for pattern_name in "${!SECRET_PATTERNS[@]}"; do
  # Skip the private_key entry — handled separately below
  if [ "$pattern_name" = "Private key block" ]; then
    continue
  fi

  regex="${SECRET_PATTERNS[$pattern_name]}"

  # Find matching lines
  while IFS= read -r line; do
    if [ -z "$line" ]; then
      continue
    fi
    # Skip lines that match the allowlist
    if echo "$line" | grep -iqE "$ALLOWLIST_PATTERN"; then
      continue
    fi
    # Real match
    echo "FlutterForge [secret_detect]: BLOCKED — Possible secret detected." >&2
    echo "  Pattern: $pattern_name" >&2
    echo "  Line:    $(echo "$line" | head -c 120)" >&2
    echo "  If intentional, set FLUTTERFORGE_SKIP_SECRET_CHECK=1" >&2
    found_secret=true
    break
  done < <(echo "$content_to_scan" | grep -iE "$regex" || true)

  if [ "$found_secret" = true ]; then
    break
  fi
done

# ── Combined private key check ────────────────────────────────────────────────
if [ "$found_secret" = false ]; then
  if ! check_private_key "$content_to_scan"; then
    found_secret=true
  fi
fi

# ── Result ────────────────────────────────────────────────────────────────────
if [ "$found_secret" = true ]; then
  exit 1
fi

exit 0
