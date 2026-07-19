#!/usr/bin/env bash
# Install / regression check for the installed showcase-deck skill.
#
# History: for P0 this asserted byte-identity to the pre-refactor baseline
# (tag p0-baseline). P1 deliberately EVOLVES the skill — data-ref anchors in the
# template, an injecting serve.sh, a data-ref coverage check in verify.sh, and
# SKILL.md hooks for the picker/deck-editing. Byte-identity is therefore no longer
# the invariant, and pretending it is would only invite shrinking the compare set
# to hide real changes. Instead this script now checks three honest things:
#   (1) TRIPWIRE — files P1 did NOT touch stay byte-identical to p0-baseline, so a
#       fan-out install silently corrupting unchanged content is still caught.
#   (2) EVOLVED — files P1 intentionally changed: present + valid (not byte-equal).
#   (3) STRUCTURE — the install is flat, self-contained, named showcase-deck.
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLED="${1:-$HOME/.claude/skills/showcase-deck}"
BASE="$(mktemp -d)"; trap 'rm -rf "$BASE"' EXIT

# materialise the pre-refactor baseline tree (root == the old single-skill folder)
git -C "$REPO" archive p0-baseline | tar -x -C "$BASE"

fail=0
cmp_frozen() {  # $1 must be byte-identical to p0-baseline (P1 must not touch it)
  if ! diff -r "$BASE/$1" "$INSTALLED/$1" >/dev/null 2>&1; then
    echo " FAIL tripwire: $1 drifted from p0-baseline (P1 was not meant to touch it)"
    diff -r "$BASE/$1" "$INSTALLED/$1" | head || true; fail=1
  else echo "  OK  frozen $1"; fi
}
present() {  # $1 exists in the install
  if [ -e "$INSTALLED/$1" ]; then echo "  OK  present $1"; else echo " FAIL: missing $1"; fail=1; fi
}

echo "-- (1) tripwire: files P1 did not touch stay byte-identical to p0-baseline --"
for f in references/visual-system.md references/content-logic.md \
         references/extract-the-soul.md references/narrative-spine.md \
         assets/interaction-patterns.html assets/img; do cmp_frozen "$f"; done

echo "-- (2) evolved in P1: present + valid (not byte-checked against baseline) --"
present SKILL.md
present references/deck-mechanics.md
present assets/deck-template.html
present assets/picker.js
present scripts/verify.sh
present scripts/serve.sh
grep -q '^name: showcase-deck$' "$INSTALLED/SKILL.md" \
  && echo "  OK  name: showcase-deck" || { echo " FAIL: SKILL.md name is not showcase-deck"; fail=1; }
{ [ -x "$INSTALLED/scripts/verify.sh" ] && [ -x "$INSTALLED/scripts/serve.sh" ]; } \
  && echo "  OK  scripts executable" || { echo " FAIL: verify.sh/serve.sh not +x (they run directly)"; fail=1; }
# the evolved template must still pass verify.sh (the by-design PLACEHOLDER-REDRAW
# line is allowed to FAIL — the template ships holes on purpose; filter only that).
vout="$(bash "$INSTALLED/scripts/verify.sh" "$INSTALLED/assets/deck-template.html" 2>&1 || true)"
if echo "$vout" | grep -E '^ FAIL ' | grep -qv 'PLACEHOLDER-REDRAW'; then
  echo " FAIL: template trips a non-placeholder verify check:"; echo "$vout" | grep -E '^ FAIL ' | grep -v 'PLACEHOLDER-REDRAW'; fail=1
else echo "  OK  template passes verify (bar the by-design placeholder)"; fi

echo "-- (3) structure: flat & self-contained --"
{ [ ! -e "$INSTALLED/shared" ]; } && echo "  OK  no shared/ subdir" || { echo " FAIL: shared/ leaked into the install"; fail=1; }
n=$(ls "$INSTALLED"/references/*.md 2>/dev/null | wc -l)
[ "$n" -eq 5 ] && echo "  OK  5 references present" || { echo " FAIL: $n references (want 5)"; fail=1; }

echo "RESULT: $([ $fail -eq 0 ] && echo 'PASS' || echo 'ISSUES')"
exit $fail
