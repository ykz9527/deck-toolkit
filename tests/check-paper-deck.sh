#!/usr/bin/env bash
# Fan-out install check for paper-deck (P2), plus a regression check that
# showcase-deck still installs correctly. Runs install.sh under an isolated HOME
# so the real ~/.claude/skills is never touched.
set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMPH="$(mktemp -d)"; trap 'rm -rf "$TMPH"' EXIT
fail=0
ok(){ echo "  OK  $1"; }
bad(){ echo " FAIL $1"; fail=1; }

HOME="$TMPH" FORCE_CLAUDE=1 bash "$REPO/install.sh" >/dev/null 2>&1 || { echo "install.sh failed"; exit 2; }
BASE="$TMPH/.claude/skills"

check_skill(){  # $1 skill dir name; $2.. expected reference basenames (without .md)
  local name="$1"; shift
  local d="$BASE/$name"
  [ -f "$d/SKILL.md" ] && grep -q "^name: $name\$" "$d/SKILL.md" && ok "$name: SKILL.md name" || bad "$name: SKILL.md name != $name"
  [ ! -e "$d/shared" ] && ok "$name: no shared/ subdir (flat)" || bad "$name: shared/ leaked"
  for r in "$@"; do
    [ -f "$d/references/$r.md" ] && ok "$name: references/$r.md" || bad "$name: missing references/$r.md"
  done
  local n; n=$(ls "$d"/references/*.md 2>/dev/null | wc -l)
  [ "$n" -eq 5 ] && ok "$name: exactly 5 references" || bad "$name: $n references (want 5)"
  for s in verify.sh serve.sh extract-pdf-figures.sh; do
    [ -x "$d/scripts/$s" ] && ok "$name: scripts/$s +x" || bad "$name: scripts/$s missing or not +x"
  done
  for a in deck-template.html interaction-patterns.html picker.js; do
    [ -f "$d/assets/$a" ] && ok "$name: assets/$a" || bad "$name: missing assets/$a"
  done
}

echo "-- paper-deck (new in P2) --"
check_skill paper-deck extract-the-paper-soul paper-narrative visual-system content-logic deck-mechanics
# paper-deck must NOT carry showcase's soul refs
[ ! -e "$BASE/paper-deck/references/extract-the-soul.md" ] && ok "paper-deck: no showcase soul ref" || bad "paper-deck: leaked showcase ref"

echo "-- showcase-deck (regression) --"
check_skill showcase-deck extract-the-soul narrative-spine visual-system content-logic deck-mechanics

echo "RESULT: $([ $fail -eq 0 ] && echo PASS || echo ISSUES)"
exit $fail
