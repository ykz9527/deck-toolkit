#!/usr/bin/env bash
# Zero-regression check: the installed showcase-deck skill must be byte-identical
# (for SKILL-behavior files) to the pre-refactor baseline tagged p0-baseline.
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLED="${1:-$HOME/.claude/skills/showcase-deck}"
BASE="$(mktemp -d)"; trap 'rm -rf "$BASE"' EXIT

# materialise the baseline tree (root == the old single-skill folder)
git -C "$REPO" archive p0-baseline | tar -x -C "$BASE"

fail=0
cmp_path() {  # $1 = relative path under both trees
  if ! diff -r "$BASE/$1" "$INSTALLED/$1" >/dev/null 2>&1; then
    echo " FAIL parity: $1 differs from p0-baseline"; diff -r "$BASE/$1" "$INSTALLED/$1" | head || true; fail=1
  else
    echo "  OK  $1"
  fi
}
cmp_path SKILL.md
cmp_path references
cmp_path assets
cmp_path scripts

echo "RESULT: $([ $fail -eq 0 ] && echo 'PASS — zero regression' || echo 'REGRESSION')"
exit $fail
