#!/usr/bin/env bash
# skills.sh - install FlutterForge skills and agents for Claude Code, Codex, or
# generic agent CLIs.
#
# Local use:
#   bash skills.sh install --preset codex
#   bash skills.sh install --preset claude
#   bash skills.sh list
#
# Remote use:
#   curl -fsSL https://raw.githubusercontent.com/Yakoub-ai/flutterforge/main/skills.sh | bash -s -- install --preset generic

set -euo pipefail

REPO_URL="${FLUTTERFORGE_REPO_URL:-https://github.com/Yakoub-ai/flutterforge}"
REF="${FLUTTERFORGE_REF:-main}"

usage() {
  cat <<'EOF'
Usage:
  bash skills.sh list
  bash skills.sh install [--preset claude|codex|generic] [--skills-dir DIR] [--agents-dir DIR]

Presets:
  claude   Install to ~/.claude/skills and ~/.claude/agents
  codex    Install to ${CODEX_HOME:-~/.codex}/skills and ${CODEX_HOME:-~/.codex}/agents
  generic  Install to ~/.agents/skills and ~/.agents/agents

Environment:
  FLUTTERFORGE_REF       Git ref to download when this script is run standalone (default: main)
  FLUTTERFORGE_REPO_URL  Repository URL used for standalone downloads

Examples:
  bash skills.sh install --preset codex
  bash skills.sh install --skills-dir "$HOME/.mycli/skills" --agents-dir "$HOME/.mycli/agents"
EOF
}

expand_path() {
  local value="$1"
  case "$value" in
    "~") printf '%s\n' "$HOME" ;;
    "~/"*) printf '%s/%s\n' "$HOME" "${value#~/}" ;;
    *) printf '%s\n' "$value" ;;
  esac
}

repo_root_from_script() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || pwd)"
  if [[ -d "$script_dir/skills" && -d "$script_dir/agents" ]]; then
    printf '%s\n' "$script_dir"
    return 0
  fi
  return 1
}

download_repo() {
  local tmp archive archive_url
  tmp="$(mktemp -d)"
  archive="$tmp/flutterforge.tar.gz"
  archive_url="${REPO_URL%/}/archive/${REF}.tar.gz"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$archive_url" -o "$archive"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$archive" "$archive_url"
  else
    echo "ERROR: curl or wget is required when skills.sh is not run from a FlutterForge checkout." >&2
    exit 1
  fi

  tar -xzf "$archive" -C "$tmp"
  find "$tmp" -maxdepth 1 -type d -name "flutterforge-*" | head -n 1
}

repo_root() {
  repo_root_from_script || download_repo
}

list_items() {
  local root="$1"

  echo "Skills:"
  while IFS= read -r skill_md; do
    basename "$(dirname "$skill_md")"
  done < <(find "$root/skills" -mindepth 2 -maxdepth 2 -name SKILL.md -print) \
    | sort | sed 's/^/  - /'

  echo ""
  echo "Agents:"
  while IFS= read -r agent_file; do
    basename "$agent_file" .md
  done < <(find "$root/agents" -maxdepth 1 -type f -name '*.md' -print) \
    | sort | sed 's/^/  - /'
}

copy_tree_contents() {
  local src="$1"
  local dest="$2"
  mkdir -p "$dest"
  cp -R "$src"/. "$dest"/
}

install_items() {
  local root="$1"
  local skills_dir="$2"
  local agents_dir="$3"
  local skill_count agent_count

  skills_dir="$(expand_path "$skills_dir")"
  agents_dir="$(expand_path "$agents_dir")"

  mkdir -p "$skills_dir" "$agents_dir"

  skill_count=0
  while IFS= read -r skill_md; do
    local skill_name src_dir dest_dir
    src_dir="$(dirname "$skill_md")"
    skill_name="$(basename "$src_dir")"
    dest_dir="$skills_dir/$skill_name"
    copy_tree_contents "$src_dir" "$dest_dir"
    skill_count=$((skill_count + 1))
  done < <(find "$root/skills" -mindepth 2 -maxdepth 2 -name SKILL.md -print | sort)

  agent_count=0
  while IFS= read -r agent_file; do
    cp "$agent_file" "$agents_dir/$(basename "$agent_file")"
    agent_count=$((agent_count + 1))
  done < <(find "$root/agents" -maxdepth 1 -type f -name '*.md' -print | sort)

  echo "Installed $skill_count skills to: $skills_dir"
  echo "Installed $agent_count agents to: $agents_dir"
}

preset_dirs() {
  local preset="$1"
  case "$preset" in
    claude)
      SKILLS_DIR="$HOME/.claude/skills"
      AGENTS_DIR="$HOME/.claude/agents"
      ;;
    codex)
      local codex_home="${CODEX_HOME:-$HOME/.codex}"
      SKILLS_DIR="$codex_home/skills"
      AGENTS_DIR="$codex_home/agents"
      ;;
    generic)
      SKILLS_DIR="$HOME/.agents/skills"
      AGENTS_DIR="$HOME/.agents/agents"
      ;;
    *)
      echo "ERROR: Unknown preset: $preset" >&2
      usage >&2
      exit 1
      ;;
  esac
}

main() {
  local command="${1:-help}"
  shift || true

  local preset="generic"
  local custom_skills_dir=""
  local custom_agents_dir=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --preset)
        preset="${2:-}"
        shift 2
        ;;
      --skills-dir)
        custom_skills_dir="${2:-}"
        shift 2
        ;;
      --agents-dir)
        custom_agents_dir="${2:-}"
        shift 2
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        echo "ERROR: Unknown argument: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
  done

  local root
  root="$(repo_root)"

  case "$command" in
    list)
      list_items "$root"
      ;;
    install)
      preset_dirs "$preset"
      if [[ -n "$custom_skills_dir" ]]; then SKILLS_DIR="$(expand_path "$custom_skills_dir")"; fi
      if [[ -n "$custom_agents_dir" ]]; then AGENTS_DIR="$(expand_path "$custom_agents_dir")"; fi
      install_items "$root" "$SKILLS_DIR" "$AGENTS_DIR"
      ;;
    help|--help|-h)
      usage
      ;;
    *)
      echo "ERROR: Unknown command: $command" >&2
      usage >&2
      exit 1
      ;;
  esac
}

main "$@"
