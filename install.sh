#!/usr/bin/env bash
# One-command installer for the project-showcase-deck skill.
#
# Installs (or updates) the skill as a git checkout under your agent's
# personal-skills directory, so `git pull` keeps it current.
#
#   Claude Code : ~/.claude/skills/project-showcase-deck
#   Codex       : ~/.agents/skills/project-showcase-deck   (same SKILL.md format)
#
# Usage:
#   bash install.sh              # auto-detect Claude Code and/or Codex
#   FORCE_CLAUDE=1 bash install.sh   # force-install the Claude Code target
#   FORCE_CODEX=1  bash install.sh   # force-install the Codex target
#
# The skill lives in a PRIVATE repo, so `git clone` uses your existing git
# credentials (SSH key or credential helper). Make sure you can reach the repo.
set -euo pipefail

REPO_URL="https://github.com/ykz9527/project-showcase-deck.git"
NAME="project-showcase-deck"

install_to() {
  local base="$1" label="$2"
  local dest="$base/$NAME"
  mkdir -p "$base"
  if [ -d "$dest/.git" ]; then
    echo "↻ updating $label skill at $dest"
    git -C "$dest" pull --ff-only
  elif [ -e "$dest" ]; then
    echo "⚠ $dest exists but is not a git checkout — leaving it alone."
    echo "  Remove it and re-run if you want a fresh install."
  else
    echo "↓ installing $label skill → $dest"
    git clone --depth 1 "$REPO_URL" "$dest"
  fi
}

installed=0
if [ -d "$HOME/.claude" ] || [ "${FORCE_CLAUDE:-}" = "1" ]; then
  install_to "$HOME/.claude/skills" "Claude Code"; installed=1
fi
if [ -d "$HOME/.codex" ] || [ -d "$HOME/.agents" ] || [ "${FORCE_CODEX:-}" = "1" ]; then
  install_to "$HOME/.agents/skills" "Codex"; installed=1
fi

if [ "$installed" = "0" ]; then
  echo "No ~/.claude or ~/.codex found — defaulting to Claude Code."
  install_to "$HOME/.claude/skills" "Claude Code"
fi

echo "✓ done. Start a new agent session to pick up the skill, then ask:"
echo '    "给这个项目做一份介绍 deck"  /  "make a showcase deck for this repo"'
