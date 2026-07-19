#!/usr/bin/env bash
# Fan-out installer for the deck-toolkit skills.
#
# Reads the local source layout (shared/ + skills/<name>/) that sits next to
# this script, and materialises each skill as a SELF-CONTAINED, flat directory
# under your agent's personal-skills dir — shared assets are merged in, so the
# installed layout matches a classic single-skill folder (no shared/ subdir).
#
#   Claude Code : ~/.claude/skills/<name>
#   Codex       : ~/.agents/skills/<name>   (same SKILL.md format)
#
# Usage:
#   bash install.sh                 # auto-detect Claude Code and/or Codex
#   FORCE_CLAUDE=1 bash install.sh  # force the Claude Code target
#   FORCE_CODEX=1  bash install.sh  # force the Codex target
#
# Re-run after `git pull` to update installed skills (they are copies, not
# checkouts). Existing installs are replaced wholesale.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -d "$SRC/shared" ] && [ -d "$SRC/skills" ] || {
  echo "install.sh must run from inside a deck-toolkit checkout (shared/ + skills/ next to it)"; exit 1; }

fan_out_one() {
  local base="$1" name="$2"
  local dest="$base/$name"
  rm -rf "$dest"
  mkdir -p "$dest/references"
  # 1) skill-specific payload (SKILL.md + its own references)
  cp -a "$SRC/skills/$name/." "$dest/"
  # 2) merge shared references, then drop in shared assets + scripts
  [ -d "$SRC/shared/references" ] && cp -a "$SRC/shared/references/." "$dest/references/"
  [ -d "$SRC/shared/assets" ]     && cp -a "$SRC/shared/assets"       "$dest/assets"
  [ -d "$SRC/shared/scripts" ]    && cp -a "$SRC/shared/scripts"      "$dest/scripts"
}

install_to() {
  local base="$1" label="$2"
  mkdir -p "$base"
  local name
  for name in $(cd "$SRC/skills" && ls -1); do
    [ -f "$SRC/skills/$name/SKILL.md" ] || continue
    echo "↓ installing $label skill → $base/$name"
    fan_out_one "$base" "$name"
  done
}

installed=0
if [ -d "$HOME/.claude" ] || [ "${FORCE_CLAUDE:-}" = "1" ]; then
  install_to "$HOME/.claude/skills" "Claude Code"; installed=1
fi
if [ -d "$HOME/.codex" ] || [ -d "$HOME/.agents" ] || [ "${FORCE_CODEX:-}" = "1" ]; then
  install_to "$HOME/.agents/skills" "Codex"; installed=1
fi
if [ "$installed" = "0" ]; then
  echo "No ~/.claude or ~/.agents found — defaulting to Claude Code."
  install_to "$HOME/.claude/skills" "Claude Code"
fi

echo "✓ done. Start a new agent session to pick up the skill(s)."
