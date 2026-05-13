#!/usr/bin/env bash
# LEGACY REFERENCE — Claude Code hooks now use hooks/lib-node/session_start_flutter_context.cjs
# session_start_flutter_context.sh — Auto-orient Claude when a Flutter project is open.
#
# Triggered: SessionStart
# Outputs a concise Flutter project context block to stdout so Claude begins
# each session with project awareness, eliminating redundant discovery queries.
# No-ops when no pubspec.yaml is found within 5 parent levels (global safe install).

# ── Find Flutter project root ─────────────────────────────────────────────────
source "$(dirname "$0")/flutter_guard.sh" 2>/dev/null || true

if [ -z "${FLUTTER_PROJECT_ROOT:-}" ]; then
  # Not inside a Flutter project — exit silently
  exit 0
fi

ROOT="$FLUTTER_PROJECT_ROOT"

# ── Gather Flutter version ────────────────────────────────────────────────────
flutter_version=""
if command -v flutter >/dev/null 2>&1; then
  flutter_version="$(flutter --version --machine 2>/dev/null \
    | grep -m1 '"version"' | sed 's/.*"version": *"\([^"]*\)".*/\1/' || true)"
fi
[ -z "$flutter_version" ] && flutter_version="(flutter not on PATH)"

# ── Extract app name from pubspec.yaml ───────────────────────────────────────
app_name="$(grep -m1 '^name:' "$ROOT/pubspec.yaml" 2>/dev/null \
  | sed 's/name: *//' | tr -d '[:space:]')"
[ -z "$app_name" ] && app_name="unknown"

# ── Detect state management library ──────────────────────────────────────────
state_mgmt="unknown"
if grep -q 'flutter_riverpod\|riverpod_annotation' "$ROOT/pubspec.yaml" 2>/dev/null; then
  state_mgmt="riverpod"
elif grep -q 'flutter_bloc\|bloc:' "$ROOT/pubspec.yaml" 2>/dev/null; then
  state_mgmt="bloc/cubit"
elif grep -q 'provider:' "$ROOT/pubspec.yaml" 2>/dev/null; then
  state_mgmt="provider"
elif grep -q 'get:' "$ROOT/pubspec.yaml" 2>/dev/null; then
  state_mgmt="getx"
fi

# ── Detect router ─────────────────────────────────────────────────────────────
router="unknown"
if grep -q 'go_router' "$ROOT/pubspec.yaml" 2>/dev/null; then
  router="go_router"
elif grep -q 'auto_route' "$ROOT/pubspec.yaml" 2>/dev/null; then
  router="auto_route"
fi

# ── Check for FlutterForge planning docs ─────────────────────────────────────
has_tech_plan="no"
[ -f "$ROOT/docs/architecture/technical_plan.md" ] && has_tech_plan="yes"

has_app_brief="no"
[ -f "$ROOT/docs/product/app_brief.md" ] && has_app_brief="yes"

# ── Check CI ──────────────────────────────────────────────────────────────────
has_ci="no"
[ -f "$ROOT/.github/workflows/flutter_ci.yml" ] && has_ci="yes"

# ── Output context block ──────────────────────────────────────────────────────
cat <<EOF
[FlutterForge — Session Context]
App: $app_name
Flutter: $flutter_version
State management: $state_mgmt
Router: $router
Architecture plan: $has_tech_plan  (docs/architecture/technical_plan.md)
Product brief: $has_app_brief  (docs/product/app_brief.md)
CI configured: $has_ci  (.github/workflows/flutter_ci.yml)
Project root: $ROOT
EOF
