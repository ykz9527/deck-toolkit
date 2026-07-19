#!/usr/bin/env bash
# Zero-regression check: the installed showcase-deck skill must be byte-identical
# (content AND permission bits) to the pre-refactor baseline tagged p0-baseline,
# with ONE deliberate exception — SKILL.md's frontmatter `name:` line, which was
# renamed project-showcase-deck -> showcase-deck to match the installed dir name.
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLED="${1:-$HOME/.claude/skills/showcase-deck}"
BASE="$(mktemp -d)"; trap 'rm -rf "$BASE"' EXIT

# materialise the baseline tree (root == the old single-skill folder)
git -C "$REPO" archive p0-baseline | tar -x -C "$BASE"

fail=0
cmp_path() {  # $1 = relative path under both trees — byte-identical content
  if ! diff -r "$BASE/$1" "$INSTALLED/$1" >/dev/null 2>&1; then
    echo " FAIL parity: $1 differs from p0-baseline"; diff -r "$BASE/$1" "$INSTALLED/$1" | head || true; fail=1
  else
    echo "  OK  $1"
  fi
}

# SKILL.md: identical EXCEPT the frontmatter name: line (deliberate rename).
if ! diff <(grep -v '^name:' "$BASE/SKILL.md") <(grep -v '^name:' "$INSTALLED/SKILL.md") >/dev/null 2>&1; then
  echo " FAIL parity: SKILL.md differs beyond the name: line"
  diff <(grep -v '^name:' "$BASE/SKILL.md") <(grep -v '^name:' "$INSTALLED/SKILL.md") | head || true; fail=1
elif ! grep -q '^name: showcase-deck$' "$INSTALLED/SKILL.md"; then
  echo " FAIL parity: installed SKILL.md name: is not 'showcase-deck'"; fail=1
else
  echo "  OK  SKILL.md (identical but for the intended name: showcase-deck)"
fi

cmp_path references
cmp_path assets
cmp_path scripts

# permission bits: verify.sh / serve.sh are run directly (./serve.sh), so +x is
# load-bearing — diff -r above ignores mode, so guard it explicitly.
modes() { (cd "$1" && find scripts -type f -printf '%m %p\n' | sort); }
if ! diff <(modes "$BASE") <(modes "$INSTALLED") >/dev/null 2>&1; then
  echo " FAIL parity: scripts permission bits differ"; diff <(modes "$BASE") <(modes "$INSTALLED") | head || true; fail=1
else
  echo "  OK  scripts permission bits"
fi

echo "RESULT: $([ $fail -eq 0 ] && echo 'PASS — zero regression (name: intentionally showcase-deck)' || echo 'REGRESSION')"
exit $fail
