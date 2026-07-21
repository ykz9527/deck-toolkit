#!/usr/bin/env bash
# Extract a figure from a paper PDF as a SELF-CONTAINED inline <img> snippet.
#
# paper-deck's figure strategy is hybrid: the *method* figure gets redrawn as a
# live interaction (that's the deck's soul), but result curves / dense experiment
# plots are lifted FAITHFULLY from the original — redrawing them loses fidelity.
# This script does the lifting: render (and optionally crop) one PDF page to PNG
# with poppler, then base64-inline it so the deck stays a single mailable file
# (verify.sh's "no sibling assets" rule allows a data: URI, forbids <img src=file>).
#
# Usage:
#   extract-pdf-figures.sh <pdf> <page> [--crop Xf,Yf,Wf,Hf] [--dpi N]
#                          [--id DATA_REF] [--caption TEXT] [--out PNG]
#
#   <page>          1-based page number (read the PDF first to find the figure).
#   --crop f,f,f,f  Crop box as FRACTIONS of the page, 0..1: left,top,width,height
#                   (e.g. 0.08,0.60,0.84,0.30 = a wide strip in the lower half).
#                   Fractions are what you can eyeball from reading the page; the
#                   script converts them to pixels. Omit to take the whole page.
#   --dpi N         Render resolution (default 150; bump to 220 for tiny text).
#   --id REF        data-ref for the emitted wrapper (default: fig-p<page>).
#   --caption TXT   <div class="apx-cap"> text (default: none).
#   --out PNG       Also write the raw PNG here (for eyeballing the crop).
#
# Finding --crop fractions (there is no shortcut — iterate):
#   1. First pass: run with NO --crop (or a generous guess) and --out draft.png.
#   2. Read draft.png (an image-reading tool/agent) to see the whole rendered page.
#   3. Estimate where the figure sits as fractions of the page — left/top/width/
#      height, each 0..1 — from what you saw in step 2, and pass those to --crop.
#   4. Read the newly cropped --out PNG again; if it's off or clipped, adjust the
#      fractions and repeat. A few rounds is normal.
#   Bump --dpi (e.g. 220) if small text/axis labels are illegible once cropped.
set -euo pipefail
die(){ echo "extract-pdf-figures: $*" >&2; exit 1; }
command -v pdftoppm >/dev/null || die "pdftoppm (poppler-utils) not found — install poppler, or hand-author an inline SVG of the figure instead."
command -v pdfinfo  >/dev/null || die "pdfinfo (poppler-utils) not found — install poppler, or hand-author an inline SVG of the figure instead."
command -v base64   >/dev/null || die "base64 (coreutils) not found."

CROP=""; DPI=150; ID=""; CAPTION=""; OUT=""; POS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --crop) CROP="${2:-}"; shift 2;;
    --dpi) DPI="${2:-}"; shift 2;;
    --id) ID="${2:-}"; shift 2;;
    --caption) CAPTION="${2:-}"; shift 2;;
    --out) OUT="${2:-}"; shift 2;;
    -*) die "unknown option: $1";;
    *) POS+=("$1"); shift;;
  esac
done
PDF="${POS[0]:-}"; PAGE="${POS[1]:-}"
[ -n "$PDF" ] && [ -f "$PDF" ] || die "no such PDF: '${PDF:-}'  (usage: extract-pdf-figures.sh <pdf> <page> [opts])"
[ -n "$PAGE" ] || die "page number required (1-based)"
case "$PAGE" in ''|*[!0-9]*) die "page must be a positive integer, got '$PAGE'";; esac
[ "$PAGE" -ge 1 ] || die "page must be >= 1 (1-based), got '$PAGE'"
[ -n "$ID" ] || ID="fig-p$PAGE"

# page size in points (robust to both pdfinfo forms: "Page size:" and "Page  N size:")
line="$(pdfinfo -f "$PAGE" -l "$PAGE" "$PDF" 2>/dev/null | grep -m1 'size:')" || true
[ -n "$line" ] || die "could not read page $PAGE (out of range?)"
ptsW="$(echo "$line" | sed -E 's/.*size:[[:space:]]*([0-9.]+)[[:space:]]*x[[:space:]]*([0-9.]+).*/\1/')"
ptsH="$(echo "$line" | sed -E 's/.*size:[[:space:]]*([0-9.]+)[[:space:]]*x[[:space:]]*([0-9.]+).*/\2/')"
[ -n "$ptsW" ] && [ -n "$ptsH" ] || die "could not parse page size from: $line"
pxW="$(awk -v w="$ptsW" -v d="$DPI" 'BEGIN{printf "%d", w/72*d}')"
pxH="$(awk -v h="$ptsH" -v d="$DPI" 'BEGIN{printf "%d", h/72*d}')"

crop_args=()
if [ -n "$CROP" ]; then
  IFS=, read -r fx fy fw fh <<<"$CROP"
  X="$(awk -v v="${fx:-0}" -v p="$pxW" 'BEGIN{printf "%d", v*p}')"
  Y="$(awk -v v="${fy:-0}" -v p="$pxH" 'BEGIN{printf "%d", v*p}')"
  W="$(awk -v v="${fw:-0}" -v p="$pxW" 'BEGIN{printf "%d", v*p}')"
  H="$(awk -v v="${fh:-0}" -v p="$pxH" 'BEGIN{printf "%d", v*p}')"
  { [ "$W" -gt 0 ] && [ "$H" -gt 0 ]; } || die "crop width/height computed to 0 — check --crop fractions '$CROP'"
  crop_args=(-x "$X" -y "$Y" -W "$W" -H "$H")
fi

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
# ${crop_args[@]+"${crop_args[@]}"} instead of "${crop_args[@]}": under `set -u`,
# bash < 4.4 (stock macOS /bin/bash is 3.2) raises "unbound variable" when expanding
# an EMPTY array — which is exactly the default no-crop case. The `+` form only
# expands when the array is set/non-empty, so the default path survives on bash 3.2.
pdftoppm -png -singlefile -r "$DPI" -f "$PAGE" -l "$PAGE" ${crop_args[@]+"${crop_args[@]}"} "$PDF" "$tmp/fig" \
  || die "pdftoppm failed to render page $PAGE"
png="$tmp/fig.png"
[ -f "$png" ] || die "pdftoppm produced no PNG"
[ -n "$OUT" ] && cp "$png" "$OUT"

b64="$(base64 -w0 "$png" 2>/dev/null || base64 "$png" | tr -d '\n')"
alt="figure from page $PAGE"; [ -n "$CAPTION" ] && alt="$alt — $CAPTION"
printf '<div class="apx-fig" data-ref="%s">\n' "$ID"
printf '  <img alt="%s" style="max-width:100%%;height:auto" src="data:image/png;base64,%s"/>\n' "$alt" "$b64"
[ -n "$CAPTION" ] && printf '  <div class="apx-cap">%s</div>\n' "$CAPTION"
printf '</div>\n'
