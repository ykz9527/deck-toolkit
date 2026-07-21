#!/usr/bin/env bash
# Behaviour test for extract-pdf-figures.sh. Generates its own 2-page fixture PDF
# with ghostscript (no committed binary, no dependency on any real paper), then
# asserts the emitted snippet is a single-file-safe inline figure.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$HERE/../shared/scripts/extract-pdf-figures.sh"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
fail=0
ok(){ echo "  OK  $1"; }
bad(){ echo " FAIL $1"; fail=1; }

# --- build a deterministic 2-page letter PDF via ghostscript ---
cat > "$TMP/fixture.ps" <<'PS'
/Helvetica findfont 48 scalefont setfont
72 700 moveto (Figure One page) show
showpage
/Helvetica findfont 48 scalefont setfont
72 700 moveto (Figure Two page) show
showpage
PS
gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile="$TMP/sample.pdf" "$TMP/fixture.ps" \
  || { echo "cannot build fixture PDF (ghostscript?)"; exit 2; }

# --- T1: whole page → inline apx-fig snippet, single-file safe ---
out="$(bash "$SCRIPT" "$TMP/sample.pdf" 1)" || bad "T1 exited non-zero"
echo "$out" | grep -q 'class="apx-fig"'            && ok "T1 apx-fig wrapper"      || bad "T1 no apx-fig wrapper"
echo "$out" | grep -q 'src="data:image/png;base64,' && ok "T1 inline data URI"      || bad "T1 no data URI"
# no <img src=...> pointing at a file: every src must start with data:
if echo "$out" | grep -oE 'src="[^"]*"' | grep -vq '^src="data:'; then
  bad "T1 a non-data src leaked (breaks single-file rule)"; else ok "T1 all src are data:"; fi
b64len=$(echo "$out" | grep -oE 'base64,[A-Za-z0-9+/=]+' | head -1 | wc -c)
[ "$b64len" -gt 500 ] && ok "T1 payload non-trivial ($b64len chars)" || bad "T1 payload too small ($b64len)"

# --- T2: crop + --out + --id + --caption ---
out2="$(bash "$SCRIPT" "$TMP/sample.pdf" 1 --crop 0,0,0.5,0.5 --out "$TMP/crop.png" --id s7-fig --caption "结果对比")" \
  || bad "T2 exited non-zero"
echo "$out2" | grep -q 'data-ref="s7-fig"' && ok "T2 honours --id"      || bad "T2 --id ignored"
echo "$out2" | grep -q '结果对比'           && ok "T2 honours --caption" || bad "T2 --caption ignored"
[ -f "$TMP/crop.png" ] && file "$TMP/crop.png" | grep -qi png && ok "T2 wrote a PNG via --out" || bad "T2 --out png missing/not png"
# full page vs cropped width: crop(0.5) must be clearly narrower than full
full_w=$(bash "$SCRIPT" "$TMP/sample.pdf" 1 --out "$TMP/full.png" >/dev/null; identify -format '%w' "$TMP/full.png")
crop_w=$(identify -format '%w' "$TMP/crop.png")
[ "$crop_w" -lt "$full_w" ] && ok "T2 crop narrower ($crop_w < $full_w)" || bad "T2 crop not narrower ($crop_w vs $full_w)"

# --- T3: bad input fails loudly, non-zero ---
if bash "$SCRIPT" "$TMP/nope.pdf" 1 >/dev/null 2>"$TMP/err"; then
  bad "T3 missing PDF should have failed"; else
  grep -qi 'no such PDF' "$TMP/err" && ok "T3 clear error on missing PDF" || bad "T3 wrong/empty error message"; fi

# --- T4: the emitted snippet satisfies verify.sh's "architecture diagram present"
# check when it is the deck's ONLY figure. Regression for the base64 payload (~40k+
# chars) blowing past verify.sh's old 8000-char </div>-anchored scan window, which
# made an extracted apx-fig invisible to the check even though it's the exact shape
# paper-deck is told to place there.
snippet="$(bash "$SCRIPT" "$TMP/sample.pdf" 1)" || bad "T4 extract exited non-zero"
cat > "$TMP/deck.html" <<HTML
<!doctype html><html><body>
<section class="slide"><div class="frame">
$snippet
</div></section>
</body></html>
HTML
vout="$(bash "$HERE/../shared/scripts/verify.sh" "$TMP/deck.html" 2>&1 || true)"
echo "$vout" | grep -q '  OK  architecture diagram present' && ok "T4 extracted apx-fig recognised by verify.sh" || bad "T4 extracted apx-fig NOT recognised by verify.sh"

echo "RESULT: $([ $fail -eq 0 ] && echo PASS || echo ISSUES)"
exit $fail
